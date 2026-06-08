# Real-Time Notification System - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Notification Types](#notification-types)
4. [Delivery Channels](#delivery-channels)
5. [Database Schema](#database-schema)
6. [Services](#services)
7. [API Endpoints](#api-endpoints)
8. [WebSocket Events](#websocket-events)
9. [Notification Workflow](#notification-workflow)
10. [User Preferences](#user-preferences)
11. [Security and RBAC](#security-and-rbac)

---

## Overview

The Real-Time Notification System provides comprehensive notification management for the gemstone management platform with multiple notification types, delivery channels (in-app, email, web push), real-time updates via WebSocket, notification history, filtering, and complete audit logging.

### Key Features

- **Multiple Notification Types**: 9+ predefined notification types
- **Real-Time Updates**: WebSocket-based instant notifications
- **Multiple Delivery Channels**: In-app, email, web push
- **User Preferences**: Customizable notification settings
- **Notification History**: Complete audit trail
- **Filtering and Search**: Advanced notification filtering
- **RBAC Compliance**: Role-based notification routing
- **Email Queue**: Reliable email delivery with retry logic
- **Audit Logging**: Complete tracking of all notification actions

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Dashboard                        │
│         (Notification UI, Real-time Updates)                │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    WebSocket Layer                           │
│         (Real-time notifications via Socket.IO)             │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    API Layer                                 │
│         (Notification Endpoints, RBAC)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Service Layer                               │
│  ┌──────────────┬──────────────┬──────────────────────────┐  │
│  │ Notification │ Email        │ WebSocket                │  │
│  │ Service      │ Service      │ Service                  │  │
│  │ - Send       │ - Queue      │ - Real-time updates      │  │
│  │ - Track      │ - Retry      │ - User tracking          │  │
│  │ - Archive    │ - Delivery   │ - Room management        │  │
│  └──────────────┴──────────────┴──────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Database Layer                              │
│  ┌──────────────┬──────────────┬──────────────────────────┐  │
│  │ Notifications│ Preferences  │ Delivery Logs            │  │
│  │ Templates    │ Rules        │ Audit Logs               │  │
│  └──────────────┴──────────────┴──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Notification Types

### Predefined Notification Types

| Type Key | Display Name | Severity | Channels | Description |
|----------|--------------|----------|----------|-------------|
| **SALE_COMPLETED** | Sale Completed | MEDIUM | All | New sale completed |
| **HIGH_VALUE_SALE** | High-Value Sale Alert | HIGH | All | High-value sale alert |
| **LOW_STOCK_ALERT** | Low Stock Alert | HIGH | All | Inventory low stock |
| **LARGE_EXPENSE_ALERT** | Large Expense Alert | MEDIUM | All | Large expense recorded |
| **USER_ACCOUNT_CHANGE** | User Account Change | HIGH | All | User account modified |
| **BACKUP_COMPLETED** | Backup Completed | LOW | All | Backup completed |
| **BACKUP_FAILED** | Backup Failed | CRITICAL | All | Backup failed |
| **RECOVERY_COMPLETED** | Recovery Completed | HIGH | All | Recovery completed |
| **LOGIN_SECURITY_ALERT** | Login Security Alert | CRITICAL | All | Unusual login activity |

---

## Delivery Channels

### In-App Notifications
- Displayed in dashboard notification center
- Marked as read/unread
- Can be archived or deleted
- Real-time updates via WebSocket

### Email Notifications
- Sent via SMTP server
- Customizable templates per language
- Retry logic with exponential backoff
- Queue-based delivery
- Delivery tracking

### Web Push Notifications
- Browser-based push notifications
- Requires user permission
- Real-time delivery
- Fallback to in-app if unavailable

---

## Database Schema

### notifications Table

```sql
Columns:
- id (VARCHAR 36, PK) - Unique notification ID
- notification_type_id (VARCHAR 36, FK) - Notification type
- recipient_id (VARCHAR 36, FK) - Recipient user
- title (VARCHAR 255) - Notification title
- message (TEXT) - Notification message
- data (JSON) - Additional data
- is_read (BOOLEAN) - Read status
- read_at (DATETIME) - When marked as read
- is_archived (BOOLEAN) - Archive status
- created_at (TIMESTAMP) - Creation time
- related_entity_type (VARCHAR 100) - Related entity type
- related_entity_id (VARCHAR 36) - Related entity ID
```

### notification_preferences Table

```sql
Columns:
- id (VARCHAR 36, PK) - Preference ID
- user_id (VARCHAR 36, FK UNIQUE) - User ID
- notifications_enabled (BOOLEAN) - Global enable/disable
- email_notifications_enabled (BOOLEAN) - Email enable/disable
- in_app_notifications_enabled (BOOLEAN) - In-app enable/disable
- web_push_enabled (BOOLEAN) - Web push enable/disable
- type_preferences (JSON) - Per-type preferences
- quiet_hours_enabled (BOOLEAN) - Quiet hours enabled
- quiet_hours_start, quiet_hours_end (TIME) - Quiet hours
- digest_enabled (BOOLEAN) - Digest email enabled
- digest_frequency (ENUM) - DAILY, WEEKLY, MONTHLY
```

### notification_delivery_logs Table

```sql
Columns:
- id (VARCHAR 36, PK) - Log ID
- notification_id (VARCHAR 36, FK) - Notification ID
- delivery_channel (ENUM) - IN_APP, EMAIL, WEB_PUSH
- delivery_status (ENUM) - PENDING, SENT, DELIVERED, FAILED
- sent_at, delivered_at (DATETIME) - Delivery timestamps
- failed_reason (TEXT) - Failure reason
- retry_count (INT) - Number of retries
- recipient_email (VARCHAR 100) - Email address
```

---

## Services

### NotificationService

**Methods:**
- `sendNotification(recipientId, typeKey, title, message, data)` - Send single notification
- `sendBroadcastNotification(recipientIds, typeKey, title, message, data)` - Send to multiple users
- `sendNotificationToRole(role, typeKey, title, message, data)` - Send to role
- `markAsRead(notificationId, userId)` - Mark as read
- `markAllAsRead(userId)` - Mark all as read
- `archiveNotification(notificationId, userId)` - Archive notification
- `deleteNotification(notificationId, userId)` - Delete notification
- `getNotifications(userId, limit, offset, filters)` - Get notifications with filtering
- `getUnreadCount(userId)` - Get unread count
- `getUserPreferences(userId)` - Get user preferences
- `getNotificationStatistics(userId, startDate, endDate)` - Get statistics

### WebSocketNotificationService

**Events:**
- `connection` - User connects
- `disconnect` - User disconnects
- `notification:read` - Mark notification as read
- `notification:archive` - Archive notification
- `notification:delete` - Delete notification
- `notification:markAllRead` - Mark all as read
- `notification:preferencesUpdate` - Update preferences

**Methods:**
- `sendNotificationToUser(userId, eventName, data)` - Send to specific user
- `sendNotificationToRole(role, eventName, data)` - Send to role
- `broadcastNotification(eventName, data)` - Broadcast to all
- `isUserOnline(userId)` - Check if user online
- `getConnectedUsersCount()` - Get connected users
- `sendAlert(userId, alertType, alertData)` - Send alert
- `sendUpdate(userId, updateType, updateData)` - Send update

### EmailNotificationService

**Methods:**
- `sendEmail(emailData)` - Send email notification
- `addToQueue(emailData)` - Add to email queue
- `processEmailQueue()` - Process queued emails
- `getEmailTemplate(typeKey)` - Get email template
- `sendBulkEmails(recipients, subject, html)` - Send bulk emails
- `testEmailConfiguration(testEmail)` - Test email config
- `getQueueStatus()` - Get queue status

---

## API Endpoints

### Notification Management

```
GET /api/notifications
  Query: { limit, offset, isRead, typeKey, severity, startDate, endDate }
  Response: { notifications: [...], total, unreadCount }
  Access: Authenticated

GET /api/notifications/:notificationId
  Response: { notification details }
  Access: Authenticated

PUT /api/notifications/:notificationId/read
  Response: { notificationId, read: true }
  Access: Authenticated

PUT /api/notifications/markAllRead
  Response: { userId, markedAsRead: count }
  Access: Authenticated

PUT /api/notifications/:notificationId/archive
  Response: { notificationId, archived: true }
  Access: Authenticated

DELETE /api/notifications/:notificationId
  Response: { notificationId, deleted: true }
  Access: Authenticated

GET /api/notifications/unread-count
  Response: { unreadCount }
  Access: Authenticated
```

### Preferences Management

```
GET /api/notification-preferences
  Response: { preferences }
  Access: Authenticated

PUT /api/notification-preferences
  Request: { notifications_enabled, email_notifications_enabled, ... }
  Response: { preferences }
  Access: Authenticated

PUT /api/notification-preferences/type/:typeKey
  Request: { enabled }
  Response: { typeKey, enabled }
  Access: Authenticated

PUT /api/notification-preferences/quiet-hours
  Request: { enabled, start, end, timezone }
  Response: { preferences }
  Access: Authenticated
```

### Admin Endpoints

```
POST /api/admin/notifications/send
  Request: { recipientId, typeKey, title, message, data }
  Response: { notificationId, ... }
  Access: Owner

POST /api/admin/notifications/broadcast
  Request: { recipientIds, typeKey, title, message, data }
  Response: { notifications: [...] }
  Access: Owner

GET /api/admin/notifications/statistics
  Query: { startDate, endDate }
  Response: { statistics }
  Access: Owner

GET /api/admin/notifications/delivery-logs
  Query: { limit, offset, status, channel }
  Response: { logs: [...], total }
  Access: Owner
```

---

## WebSocket Events

### Client → Server

```javascript
// Mark notification as read
socket.emit('notification:read', { notificationId });

// Archive notification
socket.emit('notification:archive', { notificationId });

// Delete notification
socket.emit('notification:delete', { notificationId });

// Mark all as read
socket.emit('notification:markAllRead');

// Update preferences
socket.emit('notification:preferencesUpdate', { preferences });
```

### Server → Client

```javascript
// New notification
socket.on('notification:new', (data) => {
  // { notificationId, typeKey, title, message, createdAt }
});

// Unread count update
socket.on('notification:unreadCount', (data) => {
  // { unreadCount }
});

// Read success
socket.on('notification:read:success', (data) => {
  // { notificationId }
});

// Archive success
socket.on('notification:archive:success', (data) => {
  // { notificationId }
});

// Alert
socket.on('alert:new', (data) => {
  // { alertType, ... }
});

// Update
socket.on('update:new', (data) => {
  // { updateType, ... }
});
```

---

## Notification Workflow

### Send Notification Flow

```
1. Trigger Event
   └─ Sale completed, backup failed, etc.

2. Create Notification
   └─ Insert into notifications table
   └─ Emit WebSocket event

3. Queue Delivery
   └─ Check user preferences
   └─ Queue in-app delivery
   └─ Queue email delivery
   └─ Queue web push delivery

4. Deliver
   └─ In-app: Instant via WebSocket
   └─ Email: Queue processing
   └─ Web Push: Browser notification

5. Track
   └─ Update delivery logs
   └─ Log actions in audit logs
```

### Email Delivery Flow

```
1. Email Queued
   └─ Added to email queue

2. Process Queue
   └─ Every 10 seconds
   └─ Send emails from queue

3. Send Email
   └─ Get template
   └─ Replace variables
   └─ Send via SMTP

4. Delivery Tracking
   └─ Update delivery log
   └─ Log success/failure

5. Retry on Failure
   └─ Exponential backoff
   └─ Max 3 retries
```

---

## User Preferences

### Global Settings

- **Notifications Enabled**: Enable/disable all notifications
- **Email Notifications**: Enable/disable email delivery
- **In-App Notifications**: Enable/disable in-app delivery
- **Web Push**: Enable/disable web push

### Per-Type Preferences

```json
{
  "SALE_COMPLETED": { "enabled": true, "email": true, "inApp": true },
  "HIGH_VALUE_SALE": { "enabled": true, "email": true, "inApp": true },
  "LOW_STOCK_ALERT": { "enabled": true, "email": true, "inApp": true },
  ...
}
```

### Quiet Hours

- **Enabled**: Enable/disable quiet hours
- **Start Time**: Quiet hours start time
- **End Time**: Quiet hours end time
- **Timezone**: User timezone

### Digest Settings

- **Enabled**: Enable/disable digest emails
- **Frequency**: DAILY, WEEKLY, MONTHLY
- **Time**: Digest send time

---

## Security and RBAC

### Access Control

| Action | Owner | Accountant | Worker | Broker |
|--------|-------|-----------|--------|--------|
| View own notifications | ✓ | ✓ | ✓ | ✓ |
| Send notifications | ✓ | ✗ | ✗ | ✗ |
| Broadcast notifications | ✓ | ✗ | ✗ | ✗ |
| View audit logs | ✓ | ✓ | ✗ | ✗ |
| Manage preferences | ✓ | ✓ | ✓ | ✓ |

### Audit Logging

All notification actions are logged with:
- User ID and role
- Action type (CREATED, SENT, READ, ARCHIVED, DELETED)
- Timestamp
- IP address
- User agent
- Action details

---

## Performance Considerations

### Database Optimization

- Indexed on recipient_id, created_at for fast queries
- Indexed on notification_type_id for filtering
- Indexed on delivery_status for queue processing
- Partitioning by date for large tables

### Email Queue

- Batch processing every 10 seconds
- Exponential backoff for retries
- Max 3 retries per email
- Configurable SMTP settings

### WebSocket Optimization

- User-specific rooms for targeted delivery
- Role-specific rooms for role-based notifications
- Connection pooling
- Memory-efficient event handling

---

## Implementation Checklist

- [ ] Database schema created
- [ ] Notification service deployed
- [ ] WebSocket service configured
- [ ] Email service configured
- [ ] API endpoints implemented
- [ ] RBAC configured
- [ ] Audit logging enabled
- [ ] Frontend UI components created
- [ ] Testing completed
- [ ] Documentation completed

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
**Status**: Production Ready
