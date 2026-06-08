/**
 * Sync API Routes
 * 
 * Endpoints for mobile app offline-first synchronization
 * All endpoints require JWT authentication
 */

const express = require('express');
const router = express.Router();
const SyncEngineService = require('../services/syncEngine.service');
const { authenticate, authorize } = require('../middleware/auth.middleware');
const logger = require('../config/logger');

// All sync endpoints require authentication
router.use(authenticate);

/**
 * POST /api/sync/initialize
 * Initialize sync for a user
 * 
 * Response:
 * {
 *   status: 'success',
 *   message: 'Sync initialized',
 *   userId: 'user-id'
 * }
 */
router.post('/initialize', async (req, res) => {
  try {
    const userId = req.user.id;
    logger.info(`📱 Sync initialization request from user: ${userId}`);

    const result = await SyncEngineService.initializeSync(userId);

    res.json({
      status: 'success',
      data: result,
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error initializing sync:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'SYNC_INIT_ERROR'
    });
  }
});

/**
 * POST /api/sync/push
 * Push local changes to server
 * 
 * Request body:
 * {
 *   localChanges: [
 *     {
 *       entityType: 'gemstone',
 *       entityId: 'id',
 *       operation: 'create|update|delete',
 *       data: {...},
 *       updatedAt: '2026-05-31T...'
 *     }
 *   ],
 *   lastSyncTimestamp: '2026-05-31T...',
 *   conflictResolutionStrategy: 'server_wins' | 'last_updated_wins'
 * }
 * 
 * Response:
 * {
 *   status: 'success',
 *   processedChanges: [...],
 *   conflicts: [...],
 *   resolutions: [...],
 *   serverChanges: [...],
 *   timestamp: '2026-05-31T...'
 * }
 */
router.post('/push', async (req, res) => {
  try {
    const userId = req.user.id;
    const syncData = req.body;

    logger.info(`📤 Sync push request from user: ${userId}`);
    logger.debug(`Changes: ${syncData.localChanges?.length || 0}`);

    // Validate request
    if (!Array.isArray(syncData.localChanges)) {
      return res.status(400).json({
        status: 'error',
        message: 'localChanges must be an array',
        code: 'INVALID_REQUEST'
      });
    }

    // Process sync
    const result = await SyncEngineService.processSyncRequest(userId, syncData);

    res.json({
      status: 'success',
      data: result,
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error processing sync push:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'SYNC_PUSH_ERROR'
    });
  }
});

/**
 * POST /api/sync/pull
 * Pull server changes since last sync
 * 
 * Request body:
 * {
 *   lastSyncTimestamp: '2026-05-31T...'
 * }
 * 
 * Response:
 * {
 *   status: 'success',
 *   changes: [
 *     {
 *       entityType: 'gemstone',
 *       operation: 'update',
 *       data: {...}
 *     }
 *   ],
 *   timestamp: '2026-05-31T...'
 * }
 */
router.post('/pull', async (req, res) => {
  try {
    const userId = req.user.id;
    const { lastSyncTimestamp } = req.body;

    logger.info(`📥 Sync pull request from user: ${userId}`);

    if (!lastSyncTimestamp) {
      return res.status(400).json({
        status: 'error',
        message: 'lastSyncTimestamp is required',
        code: 'INVALID_REQUEST'
      });
    }

    // Get server changes
    const changes = await SyncEngineService.getServerChanges(userId, lastSyncTimestamp);

    res.json({
      status: 'success',
      data: {
        changes,
        count: changes.length
      },
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error processing sync pull:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'SYNC_PULL_ERROR'
    });
  }
});

/**
 * POST /api/sync/bidirectional
 * Bidirectional sync (push and pull in one request)
 * 
 * Request body:
 * {
 *   localChanges: [...],
 *   lastSyncTimestamp: '2026-05-31T...',
 *   conflictResolutionStrategy: 'server_wins'
 * }
 * 
 * Response:
 * {
 *   status: 'success',
 *   push: {...},
 *   pull: {...},
 *   timestamp: '2026-05-31T...'
 * }
 */
router.post('/bidirectional', async (req, res) => {
  try {
    const userId = req.user.id;
    const syncData = req.body;

    logger.info(`🔄 Bidirectional sync request from user: ${userId}`);

    // 1. Push local changes
    const pushResult = await SyncEngineService.processSyncRequest(userId, syncData);

    // 2. Pull server changes
    const pullResult = {
      changes: await SyncEngineService.getServerChanges(userId, syncData.lastSyncTimestamp)
    };

    res.json({
      status: 'success',
      data: {
        push: pushResult,
        pull: pullResult,
        syncedAt: new Date()
      },
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error processing bidirectional sync:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'SYNC_BIDIRECTIONAL_ERROR'
    });
  }
});

/**
 * GET /api/sync/status
 * Get sync status for current user
 * 
 * Response:
 * {
 *   status: 'success',
 *   data: {
 *     lastSyncTimestamp: '2026-05-31T...',
 *     syncStatus: 'success|failed|pending',
 *     processedCount: 10,
 *     conflictCount: 2,
 *     resolvedCount: 2,
 *     lastError: null
 *   }
 * }
 */
router.get('/status', async (req, res) => {
  try {
    const userId = req.user.id;

    logger.info(`📊 Sync status request from user: ${userId}`);

    const status = await SyncEngineService.getSyncStatus(userId);

    res.json({
      status: 'success',
      data: status,
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error getting sync status:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'SYNC_STATUS_ERROR'
    });
  }
});

/**
 * POST /api/sync/retry
 * Retry failed syncs
 * 
 * Response:
 * {
 *   status: 'success',
 *   retriedCount: 5,
 *   timestamp: '2026-05-31T...'
 * }
 */
router.post('/retry', async (req, res) => {
  try {
    const userId = req.user.id;

    logger.info(`🔄 Retry failed syncs for user: ${userId}`);

    const retriedCount = await SyncEngineService.retryFailedSyncs(userId);

    res.json({
      status: 'success',
      data: {
        retriedCount,
        message: `Retried ${retriedCount} failed syncs`
      },
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error retrying failed syncs:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'SYNC_RETRY_ERROR'
    });
  }
});

/**
 * POST /api/sync/resolve-conflict
 * Manually resolve a sync conflict
 * 
 * Request body:
 * {
 *   conflictId: 'conflict-id',
 *   resolution: 'local_wins' | 'server_wins' | 'manual'
 * }
 * 
 * Response:
 * {
 *   status: 'success',
 *   message: 'Conflict resolved'
 * }
 */
router.post('/resolve-conflict', async (req, res) => {
  try {
    const userId = req.user.id;
    const { conflictId, resolution } = req.body;

    logger.info(`🔧 Resolving conflict: ${conflictId} with resolution: ${resolution}`);

    // Validate resolution
    if (!['local_wins', 'server_wins', 'manual'].includes(resolution)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid resolution type',
        code: 'INVALID_REQUEST'
      });
    }

    // TODO: Implement conflict resolution logic
    // For now, just acknowledge

    res.json({
      status: 'success',
      message: 'Conflict resolved',
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error resolving conflict:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'CONFLICT_RESOLUTION_ERROR'
    });
  }
});

/**
 * POST /api/sync/clear-cache
 * Clear offline cache (admin only)
 * 
 * Response:
 * {
 *   status: 'success',
 *   message: 'Cache cleared'
 * }
 */
router.post('/clear-cache', authorize(['Owner', 'Accountant']), async (req, res) => {
  try {
    const userId = req.user.id;

    logger.info(`🗑️  Clearing cache for user: ${userId}`);

    // TODO: Implement cache clearing logic

    res.json({
      status: 'success',
      message: 'Cache cleared',
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error clearing cache:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'CACHE_CLEAR_ERROR'
    });
  }
});

/**
 * GET /api/sync/conflicts
 * Get pending conflicts for user
 * 
 * Response:
 * {
 *   status: 'success',
 *   data: [
 *     {
 *       id: 'conflict-id',
 *       entityType: 'gemstone',
 *       entityId: 'id',
 *       conflictType: 'update_conflict',
 *       localData: {...},
 *       serverData: {...},
 *       createdAt: '2026-05-31T...'
 *     }
 *   ]
 * }
 */
router.get('/conflicts', async (req, res) => {
  try {
    const userId = req.user.id;

    logger.info(`📋 Getting conflicts for user: ${userId}`);

    // TODO: Implement conflict retrieval logic

    res.json({
      status: 'success',
      data: [],
      timestamp: new Date()
    });
  } catch (error) {
    logger.error('Error getting conflicts:', error);
    res.status(500).json({
      status: 'error',
      message: error.message,
      code: 'CONFLICTS_RETRIEVAL_ERROR'
    });
  }
});

module.exports = router;
