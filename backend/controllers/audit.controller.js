const AuditService = require('../services/audit.service');

exports.getAuditLogs = async (req, res) => {
  try {
    const {
      userId,
      moduleName,
      actionType,
      startDate,
      endDate,
      page = 1,
      limit = 50,
      sortBy = 'created_at',
      sortOrder = 'DESC'
    } = req.query;

    const result = await AuditService.getAuditLogs({
      userId,
      moduleName,
      actionType,
      startDate,
      endDate,
      page: parseInt(page),
      limit: parseInt(limit),
      sortBy,
      sortOrder
    });

    res.status(200).json({
      status: 'success',
      data: result.data,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Error fetching audit logs:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch audit logs',
      code: 'FETCH_AUDIT_LOGS_ERROR'
    });
  }
};

exports.getAuditLogDetail = async (req, res) => {
  try {
    const { id } = req.params;

    const log = await AuditService.getAuditLogDetail(id);

    res.status(200).json({
      status: 'success',
      data: log
    });
  } catch (error) {
    console.error('Error fetching audit log detail:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch audit log detail',
      code: 'FETCH_AUDIT_LOG_DETAIL_ERROR'
    });
  }
};

exports.getEntityHistory = async (req, res) => {
  try {
    const { entityId, moduleName } = req.params;

    const history = await AuditService.getEntityHistory(entityId, moduleName);

    res.status(200).json({
      status: 'success',
      data: history
    });
  } catch (error) {
    console.error('Error fetching entity history:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch entity history',
      code: 'FETCH_ENTITY_HISTORY_ERROR'
    });
  }
};

exports.getUserActivitySummary = async (req, res) => {
  try {
    const { userId } = req.params;
    const { days = 30 } = req.query;

    const summary = await AuditService.getUserActivitySummary(userId, parseInt(days));

    res.status(200).json({
      status: 'success',
      data: summary
    });
  } catch (error) {
    console.error('Error fetching user activity summary:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch user activity summary',
      code: 'FETCH_USER_ACTIVITY_ERROR'
    });
  }
};

exports.getSystemStats = async (req, res) => {
  try {
    const { days = 30 } = req.query;

    const stats = await AuditService.getSystemStats(parseInt(days));

    res.status(200).json({
      status: 'success',
      data: stats
    });
  } catch (error) {
    console.error('Error fetching system stats:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch system statistics',
      code: 'FETCH_SYSTEM_STATS_ERROR'
    });
  }
};

exports.exportAuditLogs = async (req, res) => {
  try {
    const {
      userId,
      moduleName,
      actionType,
      startDate,
      endDate
    } = req.query;

    const csv = await AuditService.exportAuditLogs({
      userId,
      moduleName,
      actionType,
      startDate,
      endDate
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="audit-logs.csv"');
    res.send(csv);
  } catch (error) {
    console.error('Error exporting audit logs:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to export audit logs',
      code: 'EXPORT_AUDIT_LOGS_ERROR'
    });
  }
};
