-- Notification Types Table
CREATE TABLE IF NOT EXISTS notification_types (
  id VARCHAR(36) PRIMARY KEY,
  type_key VARCHAR(100) UNIQUE NOT NULL,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(100),
  color VARCHAR(20),
  severity ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT 'MEDIUM',
  
  -- Delivery settings
  supports_email BOOLEAN DEFAULT TRUE,
  supports_in_app BOOLEAN DEFAULT TRUE,
  supports_web BOOLEAN DEFAULT TRUE,
  
  -- Configuration
  retention_days INT DEFAULT 30,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_type_key (type_key),
  INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(36) PRIMARY KEY,
  notification_type_id VARCHAR(36) NOT NULL,
  recipient_id VARCHAR(36) NOT NULL,
  
  -- Content
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSON,
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at DATETIME,
  is_archived BOOLEAN DEFAULT FALSE,
  
  -- Delivery tracking
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Related entities
  related_entity_type VARCHAR(100),
  related_entity_id VARCHAR(36),
  
  INDEX idx_recipient_id (recipient_id),
  INDEX idx_notification_type_id (notification_type_id),
  INDEX idx_is_read (is_read),
  INDEX idx_created_at (created_at DESC),
  INDEX idx_recipient_read_date (recipient_id, is_read, created_at DESC),
  FOREIGN KEY (notification_type_id) REFERENCES notification_types(id),
  FOREIGN KEY (recipient_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification Delivery Log Table
CREATE TABLE IF NOT EXISTS notification_delivery_logs (
  id VARCHAR(36) PRIMARY KEY,
  notification_id VARCHAR(36) NOT NULL,
  delivery_channel ENUM('IN_APP', 'EMAIL', 'WEB_PUSH') NOT NULL,
  delivery_status ENUM('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'BOUNCED') NOT NULL,
  
  -- Delivery details
  sent_at DATETIME,
  delivered_at DATETIME,
  failed_reason TEXT,
  retry_count INT DEFAULT 0,
  max_retries INT DEFAULT 3,
  
  -- Metadata
  recipient_email VARCHAR(100),
  email_subject VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_notification_id (notification_id),
  INDEX idx_delivery_channel (delivery_channel),
  INDEX idx_delivery_status (delivery_status),
  INDEX idx_sent_at (sent_at),
  FOREIGN KEY (notification_id) REFERENCES notifications(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL UNIQUE,
  
  -- Global settings
  notifications_enabled BOOLEAN DEFAULT TRUE,
  email_notifications_enabled BOOLEAN DEFAULT TRUE,
  in_app_notifications_enabled BOOLEAN DEFAULT TRUE,
  web_push_enabled BOOLEAN DEFAULT TRUE,
  
  -- Notification type preferences (JSON)
  type_preferences JSON,
  
  -- Quiet hours
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  quiet_hours_timezone VARCHAR(50),
  
  -- Digest settings
  digest_enabled BOOLEAN DEFAULT FALSE,
  digest_frequency ENUM('DAILY', 'WEEKLY', 'MONTHLY') DEFAULT 'DAILY',
  digest_time TIME,
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_user_id (user_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification Rules Table
CREATE TABLE IF NOT EXISTS notification_rules (
  id VARCHAR(36) PRIMARY KEY,
  rule_name VARCHAR(255) NOT NULL,
  rule_type VARCHAR(100) NOT NULL,
  
  -- Trigger conditions
  trigger_event VARCHAR(100) NOT NULL,
  trigger_condition JSON NOT NULL,
  
  -- Recipients
  recipient_roles JSON,
  recipient_users JSON,
  
  -- Notification settings
  notification_type_id VARCHAR(36) NOT NULL,
  notification_template TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  priority INT DEFAULT 0,
  
  -- Metadata
  created_by VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_trigger_event (trigger_event),
  INDEX idx_is_active (is_active),
  INDEX idx_priority (priority),
  FOREIGN KEY (notification_type_id) REFERENCES notification_types(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification Audit Log Table
CREATE TABLE IF NOT EXISTS notification_audit_logs (
  id VARCHAR(36) PRIMARY KEY,
  notification_id VARCHAR(36),
  action ENUM('CREATED', 'SENT', 'DELIVERED', 'READ', 'ARCHIVED', 'DELETED', 'FAILED') NOT NULL,
  action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- User information
  user_id VARCHAR(36),
  user_role VARCHAR(50),
  ip_address VARCHAR(45),
  
  -- Action details
  action_details JSON,
  notes TEXT,
  
  INDEX idx_notification_id (notification_id),
  INDEX idx_action (action),
  INDEX idx_user_id (user_id),
  INDEX idx_timestamp (action_timestamp),
  FOREIGN KEY (notification_id) REFERENCES notifications(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notification Template Table
CREATE TABLE IF NOT EXISTS notification_templates (
  id VARCHAR(36) PRIMARY KEY,
  template_name VARCHAR(255) NOT NULL,
  notification_type_id VARCHAR(36) NOT NULL,
  
  -- Template content
  subject_template VARCHAR(500),
  message_template TEXT NOT NULL,
  html_template TEXT,
  
  -- Variables
  required_variables JSON,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  language ENUM('mm', 'en') DEFAULT 'mm',
  
  -- Metadata
  created_by VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_notification_type_id (notification_type_id),
  INDEX idx_language (language),
  FOREIGN KEY (notification_type_id) REFERENCES notification_types(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create views for reporting
CREATE OR REPLACE VIEW notification_summary AS
SELECT 
  DATE(n.created_at) as notification_date,
  nt.type_key,
  COUNT(*) as notification_count,
  COUNT(CASE WHEN n.is_read = FALSE THEN 1 END) as unread_count,
  COUNT(DISTINCT n.recipient_id) as unique_recipients
FROM notifications n
JOIN notification_types nt ON n.notification_type_id = nt.id
GROUP BY DATE(n.created_at), nt.type_key;

CREATE OR REPLACE VIEW delivery_summary AS
SELECT 
  DATE(ndl.created_at) as delivery_date,
  ndl.delivery_channel,
  ndl.delivery_status,
  COUNT(*) as delivery_count,
  AVG(TIMESTAMPDIFF(SECOND, ndl.created_at, ndl.delivered_at)) as avg_delivery_time_seconds
FROM notification_delivery_logs ndl
GROUP BY DATE(ndl.created_at), ndl.delivery_channel, ndl.delivery_status;

-- Create indexes for performance
CREATE INDEX idx_notifications_recipient_date ON notifications(recipient_id, created_at DESC);
CREATE INDEX idx_notifications_type_date ON notifications(notification_type_id, created_at DESC);
CREATE INDEX idx_delivery_logs_status_date ON notification_delivery_logs(delivery_status, created_at DESC);
CREATE INDEX idx_delivery_logs_channel_status ON notification_delivery_logs(delivery_channel, delivery_status);
CREATE INDEX idx_preferences_user ON notification_preferences(user_id);
CREATE INDEX idx_rules_active_priority ON notification_rules(is_active, priority DESC);
