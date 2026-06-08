const express = require('express');
const router = express.Router();
const auditController = require('../controllers/audit.controller');
const { authMiddleware, roleMiddleware } = require('../middleware/auth.middleware');

// All audit routes require authentication
router.use(authMiddleware);

// Get audit logs (Owner and Accountant only)
router.get(
  '/logs',
  roleMiddleware(['owner', 'accountant']),
  auditController.getAuditLogs
);

// Get detailed audit log entry
router.get(
  '/logs/:id',
  roleMiddleware(['owner', 'accountant']),
  auditController.getAuditLogDetail
);

// Get entity change history
router.get(
  '/entity/:entityId/:moduleName',
  roleMiddleware(['owner', 'accountant']),
  auditController.getEntityHistory
);

// Get user activity summary
router.get(
  '/user/:userId/summary',
  roleMiddleware(['owner', 'accountant']),
  auditController.getUserActivitySummary
);

// Get system statistics (Owner only)
router.get(
  '/stats',
  roleMiddleware(['owner']),
  auditController.getSystemStats
);

// Export audit logs (Owner only)
router.get(
  '/export',
  roleMiddleware(['owner']),
  auditController.exportAuditLogs
);

module.exports = router;
