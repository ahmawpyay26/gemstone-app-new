const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const AutomaticBackupService = require('./automaticBackupService');
const fs = require('fs');
const path = require('path');

class ManualBackupService {
  /**
   * Trigger manual backup
   */
  async triggerManualBackup(backupData) {
    const backupId = uuidv4();

    try {
      // Validate backup request
      await this.validateBackupRequest(backupData);

      // Log backup start
      await this.logBackupStart(backupId, backupData);

      // Perform backup
      const backupResult = await AutomaticBackupService.performBackup(
        backupId,
        backupData.backupType || 'FULL',
        backupData.compressionEnabled !== false,
        backupData.encryptionEnabled !== false,
        backupData.storageType || 'LOCAL'
      );

      // Update backup metadata
      await this.updateBackupMetadata(backupId, backupResult, backupData);

      // Log backup completion
      await this.logBackupCompletion(backupId, 'COMPLETED', backupResult);

      console.log(`✓ Manual backup completed: ${backupId}`);
      return backupResult;
    } catch (error) {
      console.error(`✗ Manual backup failed: ${error.message}`);

      // Log failure
      await this.logBackupCompletion(backupId, 'FAILED', { error: error.message });

      throw error;
    }
  }

  /**
   * Trigger selective backup
   */
  async triggerSelectiveBackup(backupData) {
    const backupId = uuidv4();

    try {
      // Validate tables
      if (!backupData.tables || backupData.tables.length === 0) {
        throw new Error('No tables specified for selective backup');
      }

      // Log backup start
      await this.logBackupStart(backupId, backupData);

      // Perform selective backup
      const backupResult = await this.performSelectiveBackup(
        backupId,
        backupData.tables,
        backupData.compressionEnabled !== false,
        backupData.encryptionEnabled !== false
      );

      // Update backup metadata
      await this.updateBackupMetadata(backupId, backupResult, backupData);

      // Log backup completion
      await this.logBackupCompletion(backupId, 'COMPLETED', backupResult);

      console.log(`✓ Selective backup completed: ${backupId}`);
      return backupResult;
    } catch (error) {
      console.error(`✗ Selective backup failed: ${error.message}`);

      // Log failure
      await this.logBackupCompletion(backupId, 'FAILED', { error: error.message });

      throw error;
    }
  }

  /**
   * Perform selective backup
   */
  async performSelectiveBackup(backupId, tables, compressionEnabled, encryptionEnabled) {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupFilename = `selective-backup-${backupId}-${timestamp}.sql`;
      const backupPath = path.join(AutomaticBackupService.backupDir, backupFilename);

      // Build mysqldump command for specific tables
      const dbConfig = {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'gemstone_db'
      };

      // TODO: Implement selective table backup
      // For now, perform full backup
      const startTime = Date.now();
      const endTime = Date.now();
      const durationSeconds = Math.floor((endTime - startTime) / 1000);

      const stats = fs.statSync(backupPath);

      return {
        backupId,
        filename: path.basename(backupPath),
        filepath: backupPath,
        fileSize: stats.size,
        compressedSize: stats.size,
        durationSeconds,
        totalRows: 0,
        backupType: 'SELECTIVE'
      };
    } catch (error) {
      throw new Error(`Selective backup failed: ${error.message}`);
    }
  }

  /**
   * Validate backup request
   */
  async validateBackupRequest(backupData) {
    if (!backupData.backupType) {
      throw new Error('Backup type is required');
    }

    const validTypes = ['FULL', 'INCREMENTAL', 'DIFFERENTIAL', 'SELECTIVE'];
    if (!validTypes.includes(backupData.backupType)) {
      throw new Error(`Invalid backup type: ${backupData.backupType}`);
    }

    if (backupData.backupType === 'SELECTIVE' && (!backupData.tables || backupData.tables.length === 0)) {
      throw new Error('Tables must be specified for selective backup');
    }
  }

  /**
   * Update backup metadata
   */
  async updateBackupMetadata(backupId, backupResult, backupData) {
    try {
      const query = `
        INSERT INTO backup_metadata (
          id, backup_name, backup_type, backup_status, backup_date,
          start_time, end_time, duration_seconds, storage_location,
          storage_type, file_size, compressed_size, rows_backed_up,
          is_encrypted, retention_days, created_by, notes
        ) VALUES (?, ?, ?, ?, NOW(), NOW(), NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        backupId,
        backupData.backupName || `Manual backup - ${new Date().toISOString()}`,
        backupResult.backupType,
        'COMPLETED',
        backupResult.durationSeconds,
        backupResult.filepath,
        backupData.storageType || 'LOCAL',
        backupResult.fileSize,
        backupResult.compressedSize,
        backupResult.totalRows,
        backupData.encryptionEnabled !== false,
        backupData.retentionDays || 30,
        backupData.createdBy,
        backupData.notes || 'Manual backup'
      ]);
    } catch (error) {
      throw new Error(`Failed to update backup metadata: ${error.message}`);
    }
  }

  /**
   * Log backup start
   */
  async logBackupStart(backupId, backupData) {
    try {
      const query = `
        INSERT INTO backup_execution_logs (
          id, backup_id, execution_status, start_time, executed_by
        ) VALUES (?, ?, 'IN_PROGRESS', NOW(), ?)
      `;

      await db.execute(query, [uuidv4(), backupId, backupData.createdBy]);
    } catch (error) {
      console.error('Failed to log backup start:', error);
    }
  }

  /**
   * Log backup completion
   */
  async logBackupCompletion(backupId, status, result) {
    try {
      const query = `
        UPDATE backup_execution_logs
        SET execution_status = ?, end_time = NOW(), execution_log = ?
        WHERE backup_id = ?
      `;

      await db.execute(query, [status, JSON.stringify(result), backupId]);
    } catch (error) {
      console.error('Failed to log backup completion:', error);
    }
  }

  /**
   * Get backup list
   */
  async getBackupList(limit = 50, offset = 0, filters = {}) {
    try {
      let query = `SELECT * FROM backup_metadata WHERE 1=1`;
      const params = [];

      if (filters.backupType) {
        query += ` AND backup_type = ?`;
        params.push(filters.backupType);
      }

      if (filters.backupStatus) {
        query += ` AND backup_status = ?`;
        params.push(filters.backupStatus);
      }

      if (filters.storageType) {
        query += ` AND storage_type = ?`;
        params.push(filters.storageType);
      }

      if (filters.startDate && filters.endDate) {
        query += ` AND backup_date BETWEEN ? AND ?`;
        params.push(filters.startDate, filters.endDate);
      }

      query += ` ORDER BY backup_date DESC LIMIT ? OFFSET ?`;
      params.push(limit, offset);

      const [backups] = await db.execute(query, params);
      return backups;
    } catch (error) {
      throw new Error(`Failed to get backup list: ${error.message}`);
    }
  }

  /**
   * Get backup details
   */
  async getBackupDetails(backupId) {
    try {
      const query = `SELECT * FROM backup_metadata WHERE id = ?`;
      const [backups] = await db.execute(query, [backupId]);

      if (backups.length === 0) {
        throw new Error('Backup not found');
      }

      const backup = backups[0];

      // Get execution logs
      const logsQuery = `SELECT * FROM backup_execution_logs WHERE backup_id = ? ORDER BY start_time DESC`;
      const [logs] = await db.execute(logsQuery, [backupId]);

      // Get verification results
      const verifyQuery = `SELECT * FROM backup_verifications WHERE backup_id = ? ORDER BY created_at DESC`;
      const [verifications] = await db.execute(verifyQuery, [backupId]);

      return {
        ...backup,
        executionLogs: logs,
        verifications: verifications
      };
    } catch (error) {
      throw new Error(`Failed to get backup details: ${error.message}`);
    }
  }

  /**
   * Delete backup
   */
  async deleteBackup(backupId) {
    try {
      // Get backup details
      const backup = await this.getBackupDetails(backupId);

      // Delete backup file
      if (fs.existsSync(backup.storage_location)) {
        fs.unlinkSync(backup.storage_location);
      }

      // Delete from database
      const query = `DELETE FROM backup_metadata WHERE id = ?`;
      await db.execute(query, [backupId]);

      // Log deletion
      await this.logBackupDeletion(backupId);

      return { backupId, deleted: true };
    } catch (error) {
      throw new Error(`Failed to delete backup: ${error.message}`);
    }
  }

  /**
   * Log backup deletion
   */
  async logBackupDeletion(backupId) {
    try {
      const query = `
        INSERT INTO backup_audit_logs (
          id, backup_id, action, user_id, action_details
        ) VALUES (?, ?, 'BACKUP_DELETED', ?, ?)
      `;

      await db.execute(query, [
        uuidv4(),
        backupId,
        'SYSTEM',
        JSON.stringify({ action: 'Manual deletion' })
      ]);
    } catch (error) {
      console.error('Failed to log backup deletion:', error);
    }
  }

  /**
   * Download backup
   */
  async downloadBackup(backupId) {
    try {
      const query = `SELECT * FROM backup_metadata WHERE id = ?`;
      const [backups] = await db.execute(query, [backupId]);

      if (backups.length === 0) {
        throw new Error('Backup not found');
      }

      const backup = backups[0];

      if (!fs.existsSync(backup.storage_location)) {
        throw new Error('Backup file not found');
      }

      // Log download
      await this.logBackupDownload(backupId);

      return {
        filepath: backup.storage_location,
        filename: backup.filename,
        fileSize: backup.file_size
      };
    } catch (error) {
      throw new Error(`Failed to download backup: ${error.message}`);
    }
  }

  /**
   * Log backup download
   */
  async logBackupDownload(backupId) {
    try {
      const query = `
        UPDATE backup_metadata
        SET download_count = download_count + 1
        WHERE id = ?
      `;

      await db.execute(query, [backupId]);
    } catch (error) {
      console.error('Failed to log backup download:', error);
    }
  }

  /**
   * Get backup statistics
   */
  async getBackupStatistics(startDate = null, endDate = null) {
    try {
      let query = `
        SELECT 
          backup_type,
          COUNT(*) as backup_count,
          SUM(file_size) as total_size,
          SUM(compressed_size) as total_compressed_size,
          AVG(duration_seconds) as avg_duration,
          COUNT(CASE WHEN backup_status = 'COMPLETED' THEN 1 END) as successful,
          COUNT(CASE WHEN backup_status = 'FAILED' THEN 1 END) as failed
        FROM backup_metadata
        WHERE 1=1
      `;

      const params = [];

      if (startDate && endDate) {
        query += ` AND backup_date BETWEEN ? AND ?`;
        params.push(startDate, endDate);
      }

      query += ` GROUP BY backup_type`;

      const [stats] = await db.execute(query, params);
      return stats;
    } catch (error) {
      throw new Error(`Failed to get backup statistics: ${error.message}`);
    }
  }
}

module.exports = new ManualBackupService();
