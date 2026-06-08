const AuditLog = require('../models/AuditLog');

class AuditService {
  /**
   * Log an audit event
   * @param {Object} auditData - Audit event data
   * @returns {Promise<AuditLog>}
   */
  static async logAudit(auditData) {
    try {
      const {
        userId,
        userEmail,
        userRole,
        actionType,
        moduleName,
        entityId,
        entityName,
        beforeValue,
        afterValue,
        description,
        ipAddress,
        userAgent,
        status = 'SUCCESS',
        errorMessage,
        metadata
      } = auditData;

      const log = await AuditLog.create({
        user_id: userId,
        user_email: userEmail,
        user_role: userRole,
        action_type: actionType,
        module_name: moduleName,
        entity_id: entityId,
        entity_name: entityName,
        before_value: beforeValue,
        after_value: afterValue,
        description,
        ip_address: ipAddress,
        user_agent: userAgent,
        status,
        error_message: errorMessage,
        metadata
      });

      return log;
    } catch (error) {
      console.error('Error logging audit event:', error);
      // Don't throw - audit failures shouldn't break main operations
      return null;
    }
  }

  /**
   * Get audit logs with filtering and pagination
   * @param {Object} filters - Filter criteria
   * @returns {Promise<Object>}
   */
  static async getAuditLogs(filters = {}) {
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
      } = filters;

      const where = {};
      const offset = (page - 1) * limit;

      // Apply filters
      if (userId) where.user_id = userId;
      if (moduleName) where.module_name = moduleName;
      if (actionType) where.action_type = actionType;

      // Date range filter
      if (startDate || endDate) {
        where.created_at = {};
        if (startDate) {
          where.created_at[sequelize.Op.gte] = new Date(startDate);
        }
        if (endDate) {
          where.created_at[sequelize.Op.lte] = new Date(endDate);
        }
      }

      const { count, rows } = await AuditLog.findAndCountAll({
        where,
        order: [[sortBy, sortOrder]],
        limit,
        offset,
        attributes: [
          'id',
          'user_id',
          'user_email',
          'user_role',
          'action_type',
          'module_name',
          'entity_id',
          'entity_name',
          'description',
          'status',
          'created_at',
          'updated_at'
        ]
      });

      return {
        data: rows,
        pagination: {
          total: count,
          page,
          limit,
          pages: Math.ceil(count / limit)
        }
      };
    } catch (error) {
      console.error('Error retrieving audit logs:', error);
      throw error;
    }
  }

  /**
   * Get detailed audit log entry with before/after values
   * @param {string} logId - Audit log ID
   * @returns {Promise<AuditLog>}
   */
  static async getAuditLogDetail(logId) {
    try {
      const log = await AuditLog.findByPk(logId);
      if (!log) {
        throw new Error('Audit log not found');
      }
      return log;
    } catch (error) {
      console.error('Error retrieving audit log detail:', error);
      throw error;
    }
  }

  /**
   * Get audit history for a specific entity
   * @param {string} entityId - Entity ID
   * @param {string} moduleName - Module name
   * @returns {Promise<Array>}
   */
  static async getEntityHistory(entityId, moduleName) {
    try {
      const logs = await AuditLog.findAll({
        where: {
          entity_id: entityId,
          module_name: moduleName
        },
        order: [['created_at', 'DESC']],
        attributes: [
          'id',
          'action_type',
          'user_email',
          'user_role',
          'before_value',
          'after_value',
          'description',
          'status',
          'created_at'
        ]
      });

      return logs;
    } catch (error) {
      console.error('Error retrieving entity history:', error);
      throw error;
    }
  }

  /**
   * Get user activity summary
   * @param {string} userId - User ID
   * @param {number} days - Number of days to look back
   * @returns {Promise<Object>}
   */
  static async getUserActivitySummary(userId, days = 30) {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const logs = await AuditLog.findAll({
        where: {
          user_id: userId,
          created_at: {
            [sequelize.Op.gte]: startDate
          }
        },
        attributes: [
          'action_type',
          'module_name',
          [sequelize.fn('COUNT', sequelize.col('id')), 'count']
        ],
        group: ['action_type', 'module_name'],
        raw: true
      });

      return logs;
    } catch (error) {
      console.error('Error retrieving user activity summary:', error);
      throw error;
    }
  }

  /**
   * Get system activity statistics
   * @param {number} days - Number of days to look back
   * @returns {Promise<Object>}
   */
  static async getSystemStats(days = 30) {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const [
        totalLogs,
        successLogs,
        failureLogs,
        logsByModule,
        logsByActionType,
        logsByUser
      ] = await Promise.all([
        AuditLog.count({
          where: {
            created_at: {
              [sequelize.Op.gte]: startDate
            }
          }
        }),
        AuditLog.count({
          where: {
            status: 'SUCCESS',
            created_at: {
              [sequelize.Op.gte]: startDate
            }
          }
        }),
        AuditLog.count({
          where: {
            status: 'FAILURE',
            created_at: {
              [sequelize.Op.gte]: startDate
            }
          }
        }),
        AuditLog.findAll({
          where: {
            created_at: {
              [sequelize.Op.gte]: startDate
            }
          },
          attributes: [
            'module_name',
            [sequelize.fn('COUNT', sequelize.col('id')), 'count']
          ],
          group: ['module_name'],
          raw: true
        }),
        AuditLog.findAll({
          where: {
            created_at: {
              [sequelize.Op.gte]: startDate
            }
          },
          attributes: [
            'action_type',
            [sequelize.fn('COUNT', sequelize.col('id')), 'count']
          ],
          group: ['action_type'],
          raw: true
        }),
        AuditLog.findAll({
          where: {
            created_at: {
              [sequelize.Op.gte]: startDate
            }
          },
          attributes: [
            'user_email',
            [sequelize.fn('COUNT', sequelize.col('id')), 'count']
          ],
          group: ['user_email'],
          order: [[sequelize.fn('COUNT', sequelize.col('id')), 'DESC']],
          limit: 10,
          raw: true
        })
      ]);

      return {
        totalLogs,
        successLogs,
        failureLogs,
        successRate: totalLogs > 0 ? ((successLogs / totalLogs) * 100).toFixed(2) : 0,
        logsByModule,
        logsByActionType,
        topUsers: logsByUser
      };
    } catch (error) {
      console.error('Error retrieving system stats:', error);
      throw error;
    }
  }

  /**
   * Archive old audit logs (for performance)
   * @param {number} daysToKeep - Keep logs from last N days
   * @returns {Promise<number>}
   */
  static async archiveOldLogs(daysToKeep = 90) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

      // In production, you would export to archive storage first
      // For now, just delete old logs
      const result = await AuditLog.destroy({
        where: {
          created_at: {
            [sequelize.Op.lt]: cutoffDate
          }
        }
      });

      console.log(`Archived ${result} audit logs`);
      return result;
    } catch (error) {
      console.error('Error archiving audit logs:', error);
      throw error;
    }
  }

  /**
   * Export audit logs to CSV
   * @param {Object} filters - Filter criteria
   * @returns {Promise<string>}
   */
  static async exportAuditLogs(filters = {}) {
    try {
      const logs = await this.getAuditLogs({ ...filters, limit: 10000 });
      
      // CSV header
      const headers = [
        'ID',
        'User Email',
        'User Role',
        'Action Type',
        'Module',
        'Entity ID',
        'Entity Name',
        'Description',
        'Status',
        'Timestamp'
      ];

      // CSV rows
      const rows = logs.data.map(log => [
        log.id,
        log.user_email,
        log.user_role,
        log.action_type,
        log.module_name,
        log.entity_id || '',
        log.entity_name || '',
        log.description || '',
        log.status,
        log.created_at
      ]);

      // Combine headers and rows
      const csv = [
        headers.join(','),
        ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
      ].join('\n');

      return csv;
    } catch (error) {
      console.error('Error exporting audit logs:', error);
      throw error;
    }
  }
}

module.exports = AuditService;
