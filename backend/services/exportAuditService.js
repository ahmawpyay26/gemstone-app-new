const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

class ExportAuditService {
  /**
   * Log export action
   */
  async logExportAction(exportId, userId, action, ipAddress = null, userAgent = null, notes = null) {
    try {
      const auditId = uuidv4();

      const query = `
        INSERT INTO export_audit_logs (
          id, export_id, user_id, action, ip_address, user_agent, notes, action_timestamp
        ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
      `;

      await db.execute(query, [
        auditId,
        exportId,
        userId,
        action,
        ipAddress,
        userAgent,
        notes
      ]);

      return {
        auditId,
        exportId,
        userId,
        action,
        timestamp: new Date()
      };
    } catch (error) {
      throw new Error(`Failed to log export action: ${error.message}`);
    }
  }

  /**
   * Get export audit history
   */
  async getExportAuditHistory(exportId, limit = 50) {
    try {
      const query = `
        SELECT 
          eal.id, eal.export_id, eal.user_id, eal.action,
          eal.action_timestamp, eal.ip_address, eal.user_agent, eal.notes,
          u.email, u.name
        FROM export_audit_logs eal
        LEFT JOIN users u ON eal.user_id = u.id
        WHERE eal.export_id = ?
        ORDER BY eal.action_timestamp DESC
        LIMIT ?
      `;

      const [logs] = await db.execute(query, [exportId, limit]);
      return logs;
    } catch (error) {
      throw new Error(`Failed to get export audit history: ${error.message}`);
    }
  }

  /**
   * Get user export history
   */
  async getUserExportHistory(userId, limit = 50) {
    try {
      const query = `
        SELECT 
          eal.id, eal.export_id, eal.action, eal.action_timestamp,
          el.report_type, el.filename, el.format, el.period
        FROM export_audit_logs eal
        JOIN export_logs el ON eal.export_id = el.id
        WHERE eal.user_id = ?
        ORDER BY eal.action_timestamp DESC
        LIMIT ?
      `;

      const [logs] = await db.execute(query, [userId, limit]);
      return logs;
    } catch (error) {
      throw new Error(`Failed to get user export history: ${error.message}`);
    }
  }

  /**
   * Get export statistics
   */
  async getExportStatistics(startDate = null, endDate = null, branchId = null) {
    try {
      let query = `
        SELECT 
          el.report_type,
          el.format,
          COUNT(*) as export_count,
          COUNT(DISTINCT el.created_by) as unique_users,
          COUNT(DISTINCT DATE(el.created_at)) as days_with_exports,
          SUM(el.file_size) as total_size,
          AVG(el.file_size) as avg_size
        FROM export_logs el
        WHERE 1=1
      `;

      const params = [];

      if (startDate && endDate) {
        query += ` AND el.created_at BETWEEN ? AND ?`;
        params.push(startDate, endDate);
      }

      if (branchId) {
        query += ` AND el.branch_id = ?`;
        params.push(branchId);
      }

      query += ` GROUP BY el.report_type, el.format`;

      const [stats] = await db.execute(query, params);
      return stats;
    } catch (error) {
      throw new Error(`Failed to get export statistics: ${error.message}`);
    }
  }

  /**
   * Get most downloaded exports
   */
  async getMostDownloadedExports(limit = 10) {
    try {
      const query = `
        SELECT 
          el.id, el.report_type, el.filename, el.format,
          el.created_at, el.download_count,
          COUNT(eal.id) as total_actions
        FROM export_logs el
        LEFT JOIN export_audit_logs eal ON el.id = eal.export_id
        GROUP BY el.id
        ORDER BY el.download_count DESC
        LIMIT ?
      `;

      const [exports] = await db.execute(query, [limit]);
      return exports;
    } catch (error) {
      throw new Error(`Failed to get most downloaded exports: ${error.message}`);
    }
  }

  /**
   * Get export activity by user
   */
  async getExportActivityByUser(startDate = null, endDate = null) {
    try {
      let query = `
        SELECT 
          u.id, u.name, u.email, u.role,
          COUNT(DISTINCT eal.export_id) as exports_created,
          COUNT(CASE WHEN eal.action = 'DOWNLOADED' THEN 1 END) as downloads,
          COUNT(CASE WHEN eal.action = 'DELETED' THEN 1 END) as deletions,
          MAX(eal.action_timestamp) as last_action
        FROM export_audit_logs eal
        JOIN users u ON eal.user_id = u.id
        WHERE 1=1
      `;

      const params = [];

      if (startDate && endDate) {
        query += ` AND eal.action_timestamp BETWEEN ? AND ?`;
        params.push(startDate, endDate);
      }

      query += ` GROUP BY u.id ORDER BY exports_created DESC`;

      const [activity] = await db.execute(query, params);
      return activity;
    } catch (error) {
      throw new Error(`Failed to get export activity by user: ${error.message}`);
    }
  }

  /**
   * Increment download count
   */
  async incrementDownloadCount(exportId) {
    try {
      const query = `
        UPDATE export_logs 
        SET download_count = download_count + 1 
        WHERE id = ?
      `;

      await db.execute(query, [exportId]);
    } catch (error) {
      throw new Error(`Failed to increment download count: ${error.message}`);
    }
  }

  /**
   * Get export compliance report
   */
  async getExportComplianceReport(startDate, endDate, branchId = null) {
    try {
      let query = `
        SELECT 
          DATE(eal.action_timestamp) as action_date,
          eal.action,
          COUNT(*) as action_count,
          COUNT(DISTINCT eal.user_id) as unique_users,
          GROUP_CONCAT(DISTINCT u.name) as user_names
        FROM export_audit_logs eal
        LEFT JOIN users u ON eal.user_id = u.id
        WHERE eal.action_timestamp BETWEEN ? AND ?
      `;

      const params = [startDate, endDate];

      if (branchId) {
        query += ` AND eal.export_id IN (
          SELECT id FROM export_logs WHERE branch_id = ?
        )`;
        params.push(branchId);
      }

      query += ` GROUP BY DATE(eal.action_timestamp), eal.action
                 ORDER BY action_date DESC, eal.action`;

      const [report] = await db.execute(query, params);
      return report;
    } catch (error) {
      throw new Error(`Failed to get export compliance report: ${error.message}`);
    }
  }

  /**
   * Detect suspicious export activity
   */
  async detectSuspiciousActivity() {
    try {
      const suspiciousPatterns = [];

      // Pattern 1: Multiple exports in short time
      const query1 = `
        SELECT 
          user_id, COUNT(*) as export_count,
          MIN(action_timestamp) as first_export,
          MAX(action_timestamp) as last_export
        FROM export_audit_logs
        WHERE action = 'CREATED'
        AND action_timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
        GROUP BY user_id
        HAVING export_count > 10
      `;

      const [multipleExports] = await db.execute(query1, []);
      if (multipleExports.length > 0) {
        suspiciousPatterns.push({
          type: 'MULTIPLE_EXPORTS_SHORT_TIME',
          count: multipleExports.length,
          details: multipleExports
        });
      }

      // Pattern 2: Exports from unusual IP addresses
      const query2 = `
        SELECT 
          ip_address, COUNT(*) as access_count,
          COUNT(DISTINCT user_id) as unique_users
        FROM export_audit_logs
        WHERE action_timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        GROUP BY ip_address
        HAVING access_count > 50
      `;

      const [unusualIPs] = await db.execute(query2, []);
      if (unusualIPs.length > 0) {
        suspiciousPatterns.push({
          type: 'UNUSUAL_IP_ACTIVITY',
          count: unusualIPs.length,
          details: unusualIPs
        });
      }

      // Pattern 3: Exports by non-owner users
      const query3 = `
        SELECT 
          u.id, u.name, u.role, COUNT(*) as export_count
        FROM export_audit_logs eal
        JOIN users u ON eal.user_id = u.id
        WHERE u.role NOT IN ('owner', 'accountant')
        AND eal.action_timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY u.id
        HAVING export_count > 5
      `;

      const [unauthorizedExports] = await db.execute(query3, []);
      if (unauthorizedExports.length > 0) {
        suspiciousPatterns.push({
          type: 'UNAUTHORIZED_EXPORTS',
          count: unauthorizedExports.length,
          details: unauthorizedExports
        });
      }

      return suspiciousPatterns;
    } catch (error) {
      throw new Error(`Failed to detect suspicious activity: ${error.message}`);
    }
  }

  /**
   * Generate audit report
   */
  async generateAuditReport(startDate, endDate, branchId = null) {
    try {
      const stats = await this.getExportStatistics(startDate, endDate, branchId);
      const activity = await this.getExportActivityByUser(startDate, endDate);
      const compliance = await this.getExportComplianceReport(startDate, endDate, branchId);
      const suspicious = await this.detectSuspiciousActivity();

      return {
        reportPeriod: {
          startDate,
          endDate
        },
        statistics: stats,
        userActivity: activity,
        complianceLog: compliance,
        suspiciousPatterns: suspicious,
        summary: {
          totalExports: stats.reduce((sum, s) => sum + s.export_count, 0),
          totalUsers: activity.length,
          totalActions: compliance.reduce((sum, c) => sum + c.action_count, 0),
          suspiciousCount: suspicious.reduce((sum, s) => sum + s.count, 0)
        }
      };
    } catch (error) {
      throw new Error(`Failed to generate audit report: ${error.message}`);
    }
  }
}

module.exports = new ExportAuditService();
