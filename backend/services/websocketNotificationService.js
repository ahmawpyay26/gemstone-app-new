const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const NotificationService = require('./notificationService');

class WebSocketNotificationService {
  constructor(httpServer) {
    this.io = new Server(httpServer, {
      cors: {
        origin: process.env.FRONTEND_URL || 'http://localhost:3000',
        credentials: true
      }
    });

    this.userSockets = new Map(); // Map of userId -> Set of socket IDs
    this.setupMiddleware();
    this.setupEventHandlers();
    this.setupNotificationListeners();
  }

  /**
   * Setup authentication middleware
   */
  setupMiddleware() {
    this.io.use((socket, next) => {
      const token = socket.handshake.auth.token;

      if (!token) {
        return next(new Error('Authentication error'));
      }

      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
        socket.userId = decoded.id;
        socket.userRole = decoded.role;
        next();
      } catch (error) {
        next(new Error('Authentication error'));
      }
    });
  }

  /**
   * Setup event handlers
   */
  setupEventHandlers() {
    this.io.on('connection', (socket) => {
      console.log(`User ${socket.userId} connected via WebSocket`);

      // Track user socket
      if (!this.userSockets.has(socket.userId)) {
        this.userSockets.set(socket.userId, new Set());
      }
      this.userSockets.get(socket.userId).add(socket.id);

      // Join user-specific room
      socket.join(`user:${socket.userId}`);

      // Join role-specific room
      socket.join(`role:${socket.userRole}`);

      // Handle disconnect
      socket.on('disconnect', () => {
        console.log(`User ${socket.userId} disconnected`);
        const userSockets = this.userSockets.get(socket.userId);
        if (userSockets) {
          userSockets.delete(socket.id);
          if (userSockets.size === 0) {
            this.userSockets.delete(socket.userId);
          }
        }
      });

      // Handle notification read
      socket.on('notification:read', async (data) => {
        try {
          await NotificationService.markAsRead(data.notificationId, socket.userId);
          socket.emit('notification:read:success', { notificationId: data.notificationId });
        } catch (error) {
          socket.emit('notification:read:error', { error: error.message });
        }
      });

      // Handle notification archive
      socket.on('notification:archive', async (data) => {
        try {
          await NotificationService.archiveNotification(data.notificationId, socket.userId);
          socket.emit('notification:archive:success', { notificationId: data.notificationId });
        } catch (error) {
          socket.emit('notification:archive:error', { error: error.message });
        }
      });

      // Handle notification delete
      socket.on('notification:delete', async (data) => {
        try {
          await NotificationService.deleteNotification(data.notificationId, socket.userId);
          socket.emit('notification:delete:success', { notificationId: data.notificationId });
        } catch (error) {
          socket.emit('notification:delete:error', { error: error.message });
        }
      });

      // Handle mark all as read
      socket.on('notification:markAllRead', async () => {
        try {
          const result = await NotificationService.markAllAsRead(socket.userId);
          socket.emit('notification:markAllRead:success', result);
        } catch (error) {
          socket.emit('notification:markAllRead:error', { error: error.message });
        }
      });

      // Handle notification preferences update
      socket.on('notification:preferencesUpdate', async (data) => {
        try {
          // TODO: Implement preference update
          socket.emit('notification:preferencesUpdate:success', data);
        } catch (error) {
          socket.emit('notification:preferencesUpdate:error', { error: error.message });
        }
      });

      // Send initial unread count
      this.sendUnreadCount(socket.userId);
    });
  }

  /**
   * Setup notification listeners
   */
  setupNotificationListeners() {
    // Listen for new notifications
    NotificationService.on('notification:created', (data) => {
      this.sendNotificationToUser(data.recipientId, 'notification:new', {
        notificationId: data.notificationId,
        typeKey: data.typeKey,
        title: data.title,
        message: data.message,
        createdAt: data.createdAt
      });

      // Update unread count
      this.sendUnreadCount(data.recipientId);
    });

    // Listen for email queue events
    NotificationService.on('email:queue', (data) => {
      console.log(`Email queued for notification ${data.notificationId}`);
    });

    // Listen for web push queue events
    NotificationService.on('web-push:queue', (data) => {
      console.log(`Web push queued for notification ${data.notificationId}`);
    });
  }

  /**
   * Send notification to specific user
   */
  sendNotificationToUser(userId, eventName, data) {
    this.io.to(`user:${userId}`).emit(eventName, data);
  }

  /**
   * Send notification to role
   */
  sendNotificationToRole(role, eventName, data) {
    this.io.to(`role:${role}`).emit(eventName, data);
  }

  /**
   * Broadcast notification to all connected users
   */
  broadcastNotification(eventName, data) {
    this.io.emit(eventName, data);
  }

  /**
   * Send unread count to user
   */
  async sendUnreadCount(userId) {
    try {
      const unreadCount = await NotificationService.getUnreadCount(userId);
      this.sendNotificationToUser(userId, 'notification:unreadCount', {
        unreadCount
      });
    } catch (error) {
      console.error('Failed to send unread count:', error);
    }
  }

  /**
   * Check if user is online
   */
  isUserOnline(userId) {
    return this.userSockets.has(userId) && this.userSockets.get(userId).size > 0;
  }

  /**
   * Get connected users count
   */
  getConnectedUsersCount() {
    return this.userSockets.size;
  }

  /**
   * Get all connected users
   */
  getConnectedUsers() {
    return Array.from(this.userSockets.keys());
  }

  /**
   * Send real-time alert
   */
  sendAlert(userId, alertType, alertData) {
    this.sendNotificationToUser(userId, 'alert:new', {
      alertType,
      ...alertData,
      timestamp: new Date()
    });
  }

  /**
   * Send real-time update
   */
  sendUpdate(userId, updateType, updateData) {
    this.sendNotificationToUser(userId, 'update:new', {
      updateType,
      ...updateData,
      timestamp: new Date()
    });
  }

  /**
   * Send activity update to all users
   */
  broadcastActivityUpdate(activityType, activityData) {
    this.broadcastNotification('activity:update', {
      activityType,
      ...activityData,
      timestamp: new Date()
    });
  }
}

module.exports = WebSocketNotificationService;
