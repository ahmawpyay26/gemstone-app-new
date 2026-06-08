/**
 * Sync Engine Service
 * 
 * Handles synchronization between offline mobile app and cloud backend
 * Features:
 * - Conflict resolution (last updated wins, server priority)
 * - Sync queue management
 * - Retry mechanism with exponential backoff
 * - Data validation and integrity checks
 */

const logger = require('../config/logger');
const db = require('../config/database');

class SyncEngineService {
  /**
   * Initialize sync for a user
   */
  static async initializeSync(userId) {
    try {
      logger.info(`🔄 Initializing sync for user: ${userId}`);

      // Create sync metadata for user
      await db.query(`
        INSERT INTO sync_metadata (user_id, last_sync_timestamp, sync_status)
        VALUES ($1, NOW(), 'initialized')
        ON CONFLICT (user_id) DO UPDATE SET
          sync_status = 'initialized',
          updated_at = NOW()
      `, [userId]);

      return {
        status: 'success',
        message: 'Sync initialized',
        userId
      };
    } catch (error) {
      logger.error('Error initializing sync:', error);
      throw error;
    }
  }

  /**
   * Process sync request from mobile app
   * Receives: local changes, last sync timestamp
   * Returns: server changes, conflict resolution
   */
  static async processSyncRequest(userId, syncData) {
    try {
      logger.info(`📤 Processing sync request from user: ${userId}`);

      const {
        localChanges = [],
        lastSyncTimestamp,
        conflictResolutionStrategy = 'server_wins' // 'server_wins' or 'last_updated_wins'
      } = syncData;

      // 1. Validate sync data
      await this.validateSyncData(localChanges);

      // 2. Process local changes (upsert to server)
      const processedChanges = await this.processLocalChanges(userId, localChanges);

      // 3. Detect conflicts
      const conflicts = await this.detectConflicts(userId, localChanges, lastSyncTimestamp);

      // 4. Resolve conflicts
      const resolutions = await this.resolveConflicts(conflicts, conflictResolutionStrategy);

      // 5. Get server changes since last sync
      const serverChanges = await this.getServerChanges(userId, lastSyncTimestamp);

      // 6. Update sync metadata
      await this.updateSyncMetadata(userId, {
        lastSyncTimestamp: new Date(),
        syncStatus: 'success',
        processedCount: processedChanges.length,
        conflictCount: conflicts.length,
        resolvedCount: resolutions.length
      });

      logger.info(`✅ Sync completed for user: ${userId}`);

      return {
        status: 'success',
        processedChanges,
        conflicts,
        resolutions,
        serverChanges,
        timestamp: new Date()
      };
    } catch (error) {
      logger.error('Error processing sync request:', error);
      await this.updateSyncMetadata(userId, {
        syncStatus: 'failed',
        lastError: error.message
      });
      throw error;
    }
  }

  /**
   * Validate sync data structure and integrity
   */
  static async validateSyncData(localChanges) {
    try {
      logger.info('🔍 Validating sync data...');

      for (const change of localChanges) {
        const { entityType, entityId, operation, data } = change;

        // Validate required fields
        if (!entityType || !entityId || !operation) {
          throw new Error(`Invalid sync data: missing required fields in ${JSON.stringify(change)}`);
        }

        // Validate operation type
        if (!['create', 'update', 'delete'].includes(operation)) {
          throw new Error(`Invalid operation: ${operation}`);
        }

        // Validate entity type
        const validEntityTypes = ['gemstone', 'sale', 'expense', 'worker', 'lot'];
        if (!validEntityTypes.includes(entityType)) {
          throw new Error(`Invalid entity type: ${entityType}`);
        }

        // Validate data structure
        if (operation !== 'delete' && !data) {
          throw new Error(`Data required for ${operation} operation`);
        }
      }

      logger.info(`✅ Sync data validation passed (${localChanges.length} changes)`);
      return true;
    } catch (error) {
      logger.error('Sync data validation failed:', error);
      throw error;
    }
  }

  /**
   * Process local changes and upsert to server database
   */
  static async processLocalChanges(userId, localChanges) {
    try {
      logger.info(`📝 Processing ${localChanges.length} local changes...`);

      const processedChanges = [];

      for (const change of localChanges) {
        const { entityType, entityId, operation, data, updatedAt } = change;

        try {
          let result;

          switch (operation) {
            case 'create':
              result = await this.createEntity(entityType, entityId, data, userId);
              break;
            case 'update':
              result = await this.updateEntity(entityType, entityId, data, userId, updatedAt);
              break;
            case 'delete':
              result = await this.deleteEntity(entityType, entityId, userId);
              break;
          }

          processedChanges.push({
            entityType,
            entityId,
            operation,
            status: 'success',
            result
          });

          // Log to audit trail
          await this.logAuditTrail(userId, operation, entityType, entityId, data);

        } catch (error) {
          logger.error(`Error processing ${operation} for ${entityType} ${entityId}:`, error);
          processedChanges.push({
            entityType,
            entityId,
            operation,
            status: 'failed',
            error: error.message
          });
        }
      }

      logger.info(`✅ Processed ${processedChanges.length} changes`);
      return processedChanges;
    } catch (error) {
      logger.error('Error processing local changes:', error);
      throw error;
    }
  }

  /**
   * Create entity on server
   */
  static async createEntity(entityType, entityId, data, userId) {
    const query = `
      INSERT INTO ${entityType}s (id, ${Object.keys(data).join(', ')}, created_by, created_at, updated_at)
      VALUES ($1, ${Object.keys(data).map((_, i) => `$${i + 2}`).join(', ')}, $${Object.keys(data).length + 2}, NOW(), NOW())
      ON CONFLICT (id) DO NOTHING
      RETURNING *
    `;

    const values = [entityId, ...Object.values(data), userId];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  /**
   * Update entity on server
   */
  static async updateEntity(entityType, entityId, data, userId, clientUpdatedAt) {
    // Check for conflicts
    const existing = await db.query(
      `SELECT updated_at FROM ${entityType}s WHERE id = $1`,
      [entityId]
    );

    if (existing.rows.length === 0) {
      throw new Error(`Entity not found: ${entityType} ${entityId}`);
    }

    const serverUpdatedAt = existing.rows[0].updated_at;

    // If server version is newer, skip update (server wins)
    if (new Date(serverUpdatedAt) > new Date(clientUpdatedAt)) {
      logger.warn(`Server version is newer for ${entityType} ${entityId}, skipping update`);
      return { conflict: true, serverVersion: existing.rows[0] };
    }

    // Update entity
    const updateFields = Object.keys(data).map((key, i) => `${key} = $${i + 2}`).join(', ');
    const query = `
      UPDATE ${entityType}s
      SET ${updateFields}, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;

    const values = [entityId, ...Object.values(data)];
    const result = await db.query(query, values);
    return result.rows[0];
  }

  /**
   * Delete entity on server
   */
  static async deleteEntity(entityType, entityId, userId) {
    const query = `
      DELETE FROM ${entityType}s
      WHERE id = $1
      RETURNING id
    `;

    const result = await db.query(query, [entityId]);
    return { id: entityId, deleted: true };
  }

  /**
   * Detect conflicts between local and server data
   */
  static async detectConflicts(userId, localChanges, lastSyncTimestamp) {
    try {
      logger.info('🔎 Detecting conflicts...');

      const conflicts = [];

      for (const change of localChanges) {
        const { entityType, entityId, updatedAt } = change;

        // Get server version
        const serverResult = await db.query(
          `SELECT * FROM ${entityType}s WHERE id = $1`,
          [entityId]
        );

        if (serverResult.rows.length === 0) continue;

        const serverData = serverResult.rows[0];
        const serverUpdatedAt = new Date(serverData.updated_at);
        const clientUpdatedAt = new Date(updatedAt);

        // Conflict if both were updated after last sync
        if (serverUpdatedAt > new Date(lastSyncTimestamp) && 
            clientUpdatedAt > new Date(lastSyncTimestamp)) {
          conflicts.push({
            entityType,
            entityId,
            type: 'update_conflict',
            clientData: change,
            serverData,
            clientUpdatedAt,
            serverUpdatedAt
          });
        }
      }

      logger.info(`✅ Detected ${conflicts.length} conflicts`);
      return conflicts;
    } catch (error) {
      logger.error('Error detecting conflicts:', error);
      throw error;
    }
  }

  /**
   * Resolve conflicts based on strategy
   */
  static async resolveConflicts(conflicts, strategy = 'server_wins') {
    try {
      logger.info(`🔧 Resolving ${conflicts.length} conflicts using strategy: ${strategy}`);

      const resolutions = [];

      for (const conflict of conflicts) {
        const { entityType, entityId, clientData, serverData, clientUpdatedAt, serverUpdatedAt } = conflict;

        let winner;

        if (strategy === 'server_wins') {
          winner = 'server';
        } else if (strategy === 'last_updated_wins') {
          winner = clientUpdatedAt > serverUpdatedAt ? 'client' : 'server';
        } else {
          winner = 'manual'; // Requires manual intervention
        }

        // Store conflict resolution
        await db.query(`
          INSERT INTO sync_conflicts (entity_type, entity_id, conflict_type, resolution, resolved_at)
          VALUES ($1, $2, $3, $4, NOW())
        `, [entityType, entityId, conflict.type, winner]);

        resolutions.push({
          entityType,
          entityId,
          winner,
          timestamp: new Date()
        });
      }

      logger.info(`✅ Resolved ${resolutions.length} conflicts`);
      return resolutions;
    } catch (error) {
      logger.error('Error resolving conflicts:', error);
      throw error;
    }
  }

  /**
   * Get server changes since last sync
   */
  static async getServerChanges(userId, lastSyncTimestamp) {
    try {
      logger.info(`📥 Fetching server changes since ${lastSyncTimestamp}...`);

      const changes = [];

      // Get gemstone changes
      const gemstones = await db.query(`
        SELECT * FROM gemstones 
        WHERE updated_at > $1 AND created_by = $2
        ORDER BY updated_at DESC
      `, [lastSyncTimestamp, userId]);

      changes.push(...gemstones.rows.map(row => ({
        entityType: 'gemstone',
        operation: 'update',
        data: row
      })));

      // Get sale changes
      const sales = await db.query(`
        SELECT * FROM sales 
        WHERE updated_at > $1 AND created_by = $2
        ORDER BY updated_at DESC
      `, [lastSyncTimestamp, userId]);

      changes.push(...sales.rows.map(row => ({
        entityType: 'sale',
        operation: 'update',
        data: row
      })));

      // Get expense changes
      const expenses = await db.query(`
        SELECT * FROM expenses 
        WHERE updated_at > $1 AND created_by = $2
        ORDER BY updated_at DESC
      `, [lastSyncTimestamp, userId]);

      changes.push(...expenses.rows.map(row => ({
        entityType: 'expense',
        operation: 'update',
        data: row
      })));

      logger.info(`✅ Found ${changes.length} server changes`);
      return changes;
    } catch (error) {
      logger.error('Error getting server changes:', error);
      throw error;
    }
  }

  /**
   * Update sync metadata
   */
  static async updateSyncMetadata(userId, metadata) {
    try {
      const {
        lastSyncTimestamp = new Date(),
        syncStatus = 'success',
        processedCount = 0,
        conflictCount = 0,
        resolvedCount = 0,
        lastError = null
      } = metadata;

      await db.query(`
        UPDATE sync_metadata
        SET 
          last_sync_timestamp = $1,
          sync_status = $2,
          processed_count = $3,
          conflict_count = $4,
          resolved_count = $5,
          last_error = $6,
          updated_at = NOW()
        WHERE user_id = $7
      `, [lastSyncTimestamp, syncStatus, processedCount, conflictCount, resolvedCount, lastError, userId]);

      logger.info(`✅ Updated sync metadata for user: ${userId}`);
    } catch (error) {
      logger.error('Error updating sync metadata:', error);
      // Don't throw - this is non-critical
    }
  }

  /**
   * Log to audit trail
   */
  static async logAuditTrail(userId, action, module, entityId, data) {
    try {
      await db.query(`
        INSERT INTO audit_logs (user_id, action, module, entity_id, after_value, created_at)
        VALUES ($1, $2, $3, $4, $5, NOW())
      `, [userId, action, module, entityId, JSON.stringify(data)]);
    } catch (error) {
      logger.error('Error logging audit trail:', error);
      // Don't throw - this is non-critical
    }
  }

  /**
   * Get sync status for user
   */
  static async getSyncStatus(userId) {
    try {
      const result = await db.query(`
        SELECT * FROM sync_metadata WHERE user_id = $1
      `, [userId]);

      if (result.rows.length === 0) {
        return {
          status: 'not_initialized',
          message: 'Sync not initialized for user'
        };
      }

      return result.rows[0];
    } catch (error) {
      logger.error('Error getting sync status:', error);
      throw error;
    }
  }

  /**
   * Retry failed syncs
   */
  static async retryFailedSyncs(userId) {
    try {
      logger.info(`🔄 Retrying failed syncs for user: ${userId}`);

      // Get failed sync records
      const failedSyncs = await db.query(`
        SELECT * FROM sync_queue
        WHERE user_id = $1 AND sync_status = 'failed' AND retry_count < max_retries
        ORDER BY created_at ASC
        LIMIT 10
      `, [userId]);

      let retryCount = 0;

      for (const sync of failedSyncs.rows) {
        try {
          // Retry sync
          await this.processSyncRequest(userId, {
            localChanges: [sync.data]
          });

          // Mark as synced
          await db.query(`
            UPDATE sync_queue
            SET sync_status = 'synced', updated_at = NOW()
            WHERE id = $1
          `, [sync.id]);

          retryCount++;
        } catch (error) {
          // Increment retry count
          await db.query(`
            UPDATE sync_queue
            SET retry_count = retry_count + 1, last_error = $1, updated_at = NOW()
            WHERE id = $2
          `, [error.message, sync.id]);
        }
      }

      logger.info(`✅ Retried ${retryCount} failed syncs`);
      return retryCount;
    } catch (error) {
      logger.error('Error retrying failed syncs:', error);
      throw error;
    }
  }
}

module.exports = SyncEngineService;
