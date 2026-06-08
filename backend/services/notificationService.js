const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const EventEmitter = require('events');

class NotificationService extends EventEmitter {
  constructor() {
    super();
    this.notificationTypes = new Map();
    this.initializeNotificationTypes();
  }

  /**
   * Initialize predefined notification types
   */
  async initializeNotificationTypes() {
    const types = [
      {
        typeKey: 'SALE_COMPLETED',
        displayName: 'Sale Completed',
        description: 'A new sale has been completed',
        severity: 'MEDIUM',
        icon: 'check-circle'
      },
      {
        typeKey: 'HIGH_VALUE_SALE',
        displayName: 'High-Value Sale Alert',
        description: 'A high-value sale has been completed',
        severity: 'HIGH',
        icon: 'alert-triangle'
      },
      {
        typeKey: 'LOW_STOCK_ALERT',
        displayName: 'Low Stock Alert',
        description: 'Inventory stock is running low',
        severity: 'HIGH',
        icon: 'alert-circle'
      },
      {
        typeKey: 'LARGE_EXPENSE_ALERT',
        displayName: 'Large Expense Alert',
        description: 'A large expense has been recorded',
        severity: 'MEDIUM',
        icon: 'trending-down'
      },
      {
        typeKey: 'USER_ACCOUNT_CHANGE',
        displayName: 'User Account Change',
        description: 'A user account has been modified',
        severity: 'HIGH',
        icon: 'user-alert'
      },
      {
        typeKey: 'BACKUP_COMPLETED',
        displayName: 'Backup Completed',
        description: 'Database backup has completed successfully',
        severity: 'LOW',
        icon: 'check'
      },
      {
        typeKey: 'BACKUP_FAILED',
        displayName: 'Backup Failed',
        description: 'Database backup has failed',
        severity: 'CRITICAL',
        icon: 'x-circle'
      },
      {
        typeKey: 'RECOVERY_COMPLETED',
        displayName: 'Recovery Completed',
        description: 'Database recovery has completed',
        severity: 'HIGH',
        icon: 'check'
      },
      {
        typeKey: 'LOGIN_SECURITY_ALERT',
        displayName: 'Login Security Alert',
        description: 'Unusual login activity detected',
        severity: 'CRITICAL',
        icon: 'shield-alert'
      }
    ];

    for (const type of types) {
      try {
        const id = uuidv4();
        const query = `
          INSERT INTO notification_types (
            id, type_key, display_name, description, severity, icon
          ) VALUES (?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE id=id
        `;

        await db.execute(query, [
          id,
          type.typeKey,
          type.displayName,
          type.description,
          type.severity,
          type.icon
        ]);

        this.notificationTypes.set(type.typeKey, id);
      } catch (error) {
        console.error(`Failed to initialize notification type ${type.typeKey}:`, error);
      }
    }
  }

  /**
   * Send notification
   */
  async sendNotification(recipientId, typeKey, title, message, data = {}, relatedEntity = null) {
    const notificationId = uuidv4();

    try {
      // Get notification type ID
      const typeId = await this.getNotificationTypeId(typeKey);
      if (!typeId) {
        throw new Error(`Notification type not found: ${typeKey}`);
      }

      // Create notification
      const query = `
        INSERT INTO notifications (
          id, notification_type_id, recipient_id, title, message, data,
          related_entity_type, related_entity_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        notificationId,
        typeId,
        recipientId,
        title,
        message,
        JSON.stringify(data),
        relatedEntity?.type || null,
        relatedEntity?.id || null
      ]);

      // Log notification creation
      await this.logNotificationAction(notificationId, 'CREATED', recipientId);

      // Emit event for real-time updates
      this.emit('notification:created', {
        notificationId,
        recipientId,
        typeKey,
        title,
        message
      });

      // Queue delivery
      await this.queueDelivery(notificationId, recipientId, typeKey);

      return {
        notificationId,
        recipientId,
        typeKey,
        title,
        message,
        createdAt: new Date()
      };
    } catch (error) {
      console.error(`Failed to send notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send notification to multiple recipients
   */
  async sendBroadcastNotification(recipientIds, typeKey, title, message, data = {}) {
    const results = [];

    for (const recipientId of recipientIds) {
      try {
        const result = await this.sendNotification(
          recipientId,
          typeKey,
          title,
          message,
          data
        );
        results.push(result);
      } catch (error) {
        console.error(`Failed to send notification to ${recipientId}:`, error);
      }
    }

    return results;
  }

  /**
   * Send notification to role
   */
  async sendNotificationToRole(role, typeKey, title, message, data = {}) {
    try {
      // Get users with specified role
      const query = `SELECT id FROM users WHERE role = ?`;
      const [users] = await db.execute(query, [role]);

      const recipientIds = users.map(u => u.id);
      return await this.sendBroadcastNotification(recipientIds, typeKey, title, message, data);
    } catch (error) {
      console.error(`Failed to send notification to role ${role}:`, error);
      throw error;
    }
  }

  /**
   * Queue notification delivery
   */
  async queueDelivery(notificationId, recipientId, typeKey) {
    try {
      // Get user preferences
      const preferences = await this.getUserPreferences(recipientId);

      // Get notification type
      const typeQuery = `SELECT * FROM notification_types WHERE type_key = ?`;
      const [types] = await db.execute(typeQuery, [typeKey]);

      if (types.length === 0) {
        throw new Error(`Notification type not found: ${typeKey}`);
      }

      const notificationType = types[0];

      // Queue in-app delivery
      if (preferences.in_app_notifications_enabled && notificationType.supports_in_app) {
        await this.queueInAppDelivery(notificationId, recipientId);
      }

      // Queue email delivery
      if (preferences.email_notifications_enabled && notificationType.supports_email) {
        await this.queueEmailDelivery(notificationId, recipientId);
      }

      // Queue web push delivery
      if (preferences.web_push_enabled && notificationType.supports_web) {
        await this.queueWebPushDelivery(notificationId, recipientId);
      }
    } catch (error) {
      console.error(`Failed to queue delivery: ${error.message}`);
    }
  }

  /**
   * Queue in-app delivery
   */
  async queueInAppDelivery(notificationId, recipientId) {
    try {
      const query = `
        INSERT INTO notification_delivery_logs (
          id, notification_id, delivery_channel, delivery_status
        ) VALUES (?, ?, 'IN_APP', 'PENDING')
      `;

      await db.execute(query, [uuidv4(), notificationId]);
    } catch (error) {
      console.error('Failed to queue in-app delivery:', error);
    }
  }

  /**
   * Queue email delivery
   */
  async queueEmailDelivery(notificationId, recipientId) {
    try {
      // Get user email
      const userQuery = `SELECT email FROM users WHERE id = ?`;
      const [users] = await db.execute(userQuery, [recipientId]);

      if (users.length === 0) {
        throw new Error('User not found');
      }

      const email = users[0].email;

      const query = `
        INSERT INTO notification_delivery_logs (
          id, notification_id, delivery_channel, delivery_status, recipient_email
        ) VALUES (?, ?, 'EMAIL', 'PENDING', ?)
      `;

      await db.execute(query, [uuidv4(), notificationId, email]);

      // Emit event for email queue
      this.emit('email:queue', {
        notificationId,
        recipientId,
        email
      });
    } catch (error) {
      console.error('Failed to queue email delivery:', error);
    }
  }

  /**
   * Queue web push delivery
   */
  async queueWebPushDelivery(notificationId, recipientId) {
    try {
      const query = `
        INSERT INTO notification_delivery_logs (
          id, notification_id, delivery_channel, delivery_status
        ) VALUES (?, ?, 'WEB_PUSH', 'PENDING')
      `;

      await db.execute(query, [uuidv4(), notificationId]);

      // Emit event for web push
      this.emit('web-push:queue', {
        notificationId,
        recipientId
      });
    } catch (error) {
      console.error('Failed to queue web push delivery:', error);
    }
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    try {
      const query = `
        UPDATE notifications
        SET is_read = TRUE, read_at = NOW()
        WHERE id = ? AND recipient_id = ?
      `;

      await db.execute(query, [notificationId, userId]);

      // Log action
      await this.logNotificationAction(notificationId, 'READ', userId);

      return { notificationId, read: true };
    } catch (error) {
      throw new Error(`Failed to mark notification as read: ${error.message}`);
    }
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId) {
    try {
      const query = `
        UPDATE notifications
        SET is_read = TRUE, read_at = NOW()
        WHERE recipient_id = ? AND is_read = FALSE
      `;

      const result = await db.execute(query, [userId]);

      return { userId, markedAsRead: result[0].affectedRows };
    } catch (error) {
      throw new Error(`Failed to mark all notifications as read: ${error.message}`);
    }
  }

  /**
   * Archive notification
   */
  async archiveNotification(notificationId, userId) {
    try {
      const query = `
        UPDATE notifications
        SET is_archived = TRUE
        WHERE id = ? AND recipient_id = ?
      `;

      await db.execute(query, [notificationId, userId]);

      // Log action
      await this.logNotificationAction(notificationId, 'ARCHIVED', userId);

      return { notificationId, archived: true };
    } catch (error) {
      throw new Error(`Failed to archive notification: ${error.message}`);
    }
  }

  /**
   * Delete notification
   */
  async deleteNotification(notificationId, userId) {
    try {
      const query = `
        DELETE FROM notifications
        WHERE id = ? AND recipient_id = ?
      `;

      await db.execute(query, [notificationId, userId]);

      // Log action
      await this.logNotificationAction(notificationId, 'DELETED', userId);

      return { notificationId, deleted: true };
    } catch (error) {
      throw new Error(`Failed to delete notification: ${error.message}`);
    }
  }

  /**
   * Get notifications for user
   */
  async getNotifications(userId, limit = 50, offset = 0, filters = {}) {
    try {
      let query = `
        SELECT 
          n.id, n.notification_type_id, n.title, n.message, n.data,
          n.is_read, n.read_at, n.is_archived, n.created_at,
          nt.type_key, nt.severity, nt.icon
        FROM notifications n
        JOIN notification_types nt ON n.notification_type_id = nt.id
        WHERE n.recipient_id = ? AND n.is_archived = FALSE
      `;

      const params = [userId];

      // Apply filters
      if (filters.isRead !== undefined) {
        query += ` AND n.is_read = ?`;
        params.push(filters.isRead);
      }

      if (filters.typeKey) {
        query += ` AND nt.type_key = ?`;
        params.push(filters.typeKey);
      }

      if (filters.severity) {
        query += ` AND nt.severity = ?`;
        params.push(filters.severity);
      }

      if (filters.startDate && filters.endDate) {
        query += ` AND n.created_at BETWEEN ? AND ?`;
        params.push(filters.startDate, filters.endDate);
      }

      query += ` ORDER BY n.created_at DESC LIMIT ? OFFSET ?`;
      params.push(limit, offset);

      const [notifications] = await db.execute(query, params);

      // Get total count
      let countQuery = `
        SELECT COUNT(*) as total FROM notifications n
        WHERE n.recipient_id = ? AND n.is_archived = FALSE
      `;

      const countParams = [userId];

      if (filters.isRead !== undefined) {
        countQuery += ` AND n.is_read = ?`;
        countParams.push(filters.isRead);
      }

      const [countResult] = await db.execute(countQuery, countParams);
      const total = countResult[0].total;

      return {
        notifications,
        total,
        limit,
        offset,
        unreadCount: await this.getUnreadCount(userId)
      };
    } catch (error) {
      throw new Error(`Failed to get notifications: ${error.message}`);
    }
  }

  /**
   * Get unread notification count
   */
  async getUnreadCount(userId) {
    try {
      const query = `
        SELECT COUNT(*) as count FROM notifications
        WHERE recipient_id = ? AND is_read = FALSE AND is_archived = FALSE
      `;

      const [result] = await db.execute(query, [userId]);
      return result[0].count;
    } catch (error) {
      console.error('Failed to get unread count:', error);
      return 0;
    }
  }

  /**
   * Get user preferences
   */
  async getUserPreferences(userId) {
    try {
      const query = `SELECT * FROM notification_preferences WHERE user_id = ?`;
      const [prefs] = await db.execute(query, [userId]);

      if (prefs.length === 0) {
        // Create default preferences
        return await this.createDefaultPreferences(userId);
      }

      return prefs[0];
    } catch (error) {
      console.error('Failed to get user preferences:', error);
      return {
        notifications_enabled: true,
        email_notifications_enabled: true,
        in_app_notifications_enabled: true,
        web_push_enabled: true
      };
    }
  }

  /**
   * Create default preferences
   */
  async createDefaultPreferences(userId) {
    try {
      const prefId = uuidv4();
      const query = `
        INSERT INTO notification_preferences (
          id, user_id, notifications_enabled, email_notifications_enabled,
          in_app_notifications_enabled, web_push_enabled
        ) VALUES (?, ?, TRUE, TRUE, TRUE, TRUE)
      `;

      await db.execute(query, [prefId, userId]);

      return {
        id: prefId,
        user_id: userId,
        notifications_enabled: true,
        email_notifications_enabled: true,
        in_app_notifications_enabled: true,
        web_push_enabled: true
      };
    } catch (error) {
      console.error('Failed to create default preferences:', error);
      throw error;
    }
  }

  /**
   * Get notification type ID
   */
  async getNotificationTypeId(typeKey) {
    try {
      if (this.notificationTypes.has(typeKey)) {
        return this.notificationTypes.get(typeKey);
      }

      const query = `SELECT id FROM notification_types WHERE type_key = ?`;
      const [types] = await db.execute(query, [typeKey]);

      if (types.length > 0) {
        this.notificationTypes.set(typeKey, types[0].id);
        return types[0].id;
      }

      return null;
    } catch (error) {
      console.error('Failed to get notification type ID:', error);
      return null;
    }
  }

  /**
   * Log notification action
   */
  async logNotificationAction(notificationId, action, userId) {
    try {
      const query = `
        INSERT INTO notification_audit_logs (
          id, notification_id, action, user_id, action_timestamp
        ) VALUES (?, ?, ?, ?, NOW())
      `;

      await db.execute(query, [uuidv4(), notificationId, action, userId]);
    } catch (error) {
      console.error('Failed to log notification action:', error);
    }
  }

  /**
   * Get notification statistics
   */
  async getNotificationStatistics(userId, startDate = null, endDate = null) {
    try {
      let query = `
        SELECT 
          nt.type_key,
          COUNT(*) as total_count,
          COUNT(CASE WHEN n.is_read = FALSE THEN 1 END) as unread_count,
          COUNT(CASE WHEN n.is_archived = TRUE THEN 1 END) as archived_count
        FROM notifications n
        JOIN notification_types nt ON n.notification_type_id = nt.id
        WHERE n.recipient_id = ?
      `;

      const params = [userId];

      if (startDate && endDate) {
        query += ` AND n.created_at BETWEEN ? AND ?`;
        params.push(startDate, endDate);
      }

      query += ` GROUP BY nt.type_key`;

      const [stats] = await db.execute(query, params);
      return stats;
    } catch (error) {
      throw new Error(`Failed to get notification statistics: ${error.message}`);
    }
  }
}

module.exports = new NotificationService();
