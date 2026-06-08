/**
 * Notification Routes
 * Handles all notification-related API endpoints
 */

const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// All notification routes require authentication
router.use(authMiddleware);

/**
 * GET /api/notifications
 * Get all notifications for the current user
 */
router.get('/', notificationController.getNotifications);

/**
 * GET /api/notifications/count
 * Get unread notification count
 */
router.get('/count', notificationController.getNotificationCount);

/**
 * PUT /api/notifications/:notificationId/read
 * Mark a specific notification as read
 */
router.put('/:notificationId/read', notificationController.markAsRead);

/**
 * PUT /api/notifications/read-all
 * Mark all notifications as read
 */
router.put('/read-all', notificationController.markAllAsRead);

/**
 * DELETE /api/notifications/:notificationId
 * Delete a specific notification
 */
router.delete('/:notificationId', notificationController.deleteNotification);

module.exports = router;
