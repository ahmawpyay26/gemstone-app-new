-- Backup Metadata Table
CREATE TABLE IF NOT EXISTS backup_metadata (
  id VARCHAR(36) PRIMARY KEY,
  backup_name VARCHAR(255) NOT NULL,
  backup_type ENUM('FULL', 'INCREMENTAL', 'DIFFERENTIAL', 'SELECTIVE') NOT NULL,
  backup_status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'VERIFIED') NOT NULL,
  backup_date DATETIME NOT NULL,
  start_time DATETIME,
  end_time DATETIME,
  duration_seconds INT,
  
  -- Storage information
  storage_location VARCHAR(500) NOT NULL,
  storage_type ENUM('LOCAL', 'AWS_S3', 'AZURE_BLOB', 'GOOGLE_CLOUD') NOT NULL,
  file_size BIGINT,
  compressed_size BIGINT,
  compression_ratio DECIMAL(5, 2),
  
  -- Backup scope
  database_name VARCHAR(100),
  tables_included JSON,
  rows_backed_up INT,
  
  -- Encryption and security
  is_encrypted BOOLEAN DEFAULT FALSE,
  encryption_algorithm VARCHAR(50),
  checksum VARCHAR(255),
  
  -- Retention policy
  retention_days INT DEFAULT 30,
  expiration_date DATE,
  is_archived BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  created_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_backup_date (backup_date),
  INDEX idx_backup_status (backup_status),
  INDEX idx_backup_type (backup_type),
  INDEX idx_storage_type (storage_type),
  INDEX idx_expiration_date (expiration_date),
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backup Schedule Table
CREATE TABLE IF NOT EXISTS backup_schedules (
  id VARCHAR(36) PRIMARY KEY,
  schedule_name VARCHAR(255) NOT NULL,
  backup_type ENUM('FULL', 'INCREMENTAL', 'DIFFERENTIAL') NOT NULL,
  schedule_type ENUM('DAILY', 'WEEKLY', 'MONTHLY', 'CUSTOM') NOT NULL,
  
  -- Schedule details
  is_active BOOLEAN DEFAULT TRUE,
  cron_expression VARCHAR(100),
  day_of_week INT,
  day_of_month INT,
  hour INT,
  minute INT,
  
  -- Backup settings
  retention_days INT DEFAULT 30,
  compression_enabled BOOLEAN DEFAULT TRUE,
  encryption_enabled BOOLEAN DEFAULT TRUE,
  storage_type ENUM('LOCAL', 'AWS_S3', 'AZURE_BLOB', 'GOOGLE_CLOUD') DEFAULT 'LOCAL',
  
  -- Notification settings
  notify_on_success BOOLEAN DEFAULT TRUE,
  notify_on_failure BOOLEAN DEFAULT TRUE,
  notification_email VARCHAR(100),
  
  -- Metadata
  created_by VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_schedule_type (schedule_type),
  INDEX idx_is_active (is_active),
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backup Execution Log Table
CREATE TABLE IF NOT EXISTS backup_execution_logs (
  id VARCHAR(36) PRIMARY KEY,
  backup_id VARCHAR(36) NOT NULL,
  schedule_id VARCHAR(36),
  execution_status ENUM('STARTED', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED') NOT NULL,
  
  -- Execution details
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  duration_seconds INT,
  
  -- Progress tracking
  total_tables INT,
  tables_completed INT,
  total_rows INT,
  rows_backed_up INT,
  
  -- Error handling
  error_message TEXT,
  error_code VARCHAR(50),
  retry_count INT DEFAULT 0,
  
  -- Metadata
  executed_by VARCHAR(36),
  execution_log TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_backup_id (backup_id),
  INDEX idx_schedule_id (schedule_id),
  INDEX idx_execution_status (execution_status),
  INDEX idx_start_time (start_time),
  FOREIGN KEY (backup_id) REFERENCES backup_metadata(id),
  FOREIGN KEY (schedule_id) REFERENCES backup_schedules(id),
  FOREIGN KEY (executed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Recovery Request Table
CREATE TABLE IF NOT EXISTS recovery_requests (
  id VARCHAR(36) PRIMARY KEY,
  backup_id VARCHAR(36) NOT NULL,
  recovery_type ENUM('FULL_RESTORE', 'POINT_IN_TIME', 'SELECTIVE_RESTORE') NOT NULL,
  recovery_status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED') NOT NULL,
  
  -- Recovery details
  requested_by VARCHAR(36) NOT NULL,
  approved_by VARCHAR(36),
  recovery_target_time DATETIME,
  target_tables JSON,
  
  -- Validation
  is_validated BOOLEAN DEFAULT FALSE,
  validation_result JSON,
  validation_timestamp DATETIME,
  
  -- Execution
  start_time DATETIME,
  end_time DATETIME,
  duration_seconds INT,
  
  -- Metadata
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_backup_id (backup_id),
  INDEX idx_recovery_status (recovery_status),
  INDEX idx_requested_by (requested_by),
  INDEX idx_created_at (created_at),
  FOREIGN KEY (backup_id) REFERENCES backup_metadata(id),
  FOREIGN KEY (requested_by) REFERENCES users(id),
  FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backup Verification Table
CREATE TABLE IF NOT EXISTS backup_verifications (
  id VARCHAR(36) PRIMARY KEY,
  backup_id VARCHAR(36) NOT NULL,
  verification_type ENUM('CHECKSUM', 'RESTORE_TEST', 'DATA_INTEGRITY', 'FULL') NOT NULL,
  verification_status ENUM('PENDING', 'IN_PROGRESS', 'PASSED', 'FAILED') NOT NULL,
  
  -- Verification details
  start_time DATETIME,
  end_time DATETIME,
  duration_seconds INT,
  
  -- Results
  total_checks INT,
  passed_checks INT,
  failed_checks INT,
  verification_result JSON,
  
  -- Metadata
  verified_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_backup_id (backup_id),
  INDEX idx_verification_status (verification_status),
  INDEX idx_verification_type (verification_type),
  FOREIGN KEY (backup_id) REFERENCES backup_metadata(id),
  FOREIGN KEY (verified_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backup Audit Log Table
CREATE TABLE IF NOT EXISTS backup_audit_logs (
  id VARCHAR(36) PRIMARY KEY,
  backup_id VARCHAR(36),
  recovery_id VARCHAR(36),
  action ENUM('BACKUP_CREATED', 'BACKUP_DELETED', 'BACKUP_RESTORED', 'BACKUP_VERIFIED', 'RECOVERY_REQUESTED', 'RECOVERY_APPROVED', 'RECOVERY_EXECUTED') NOT NULL,
  action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- User information
  user_id VARCHAR(36) NOT NULL,
  user_role VARCHAR(50),
  ip_address VARCHAR(45),
  
  -- Action details
  action_details JSON,
  notes TEXT,
  
  INDEX idx_backup_id (backup_id),
  INDEX idx_recovery_id (recovery_id),
  INDEX idx_action (action),
  INDEX idx_user_id (user_id),
  INDEX idx_timestamp (action_timestamp),
  FOREIGN KEY (backup_id) REFERENCES backup_metadata(id),
  FOREIGN KEY (recovery_id) REFERENCES recovery_requests(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backup Storage Configuration Table
CREATE TABLE IF NOT EXISTS backup_storage_config (
  id VARCHAR(36) PRIMARY KEY,
  storage_type ENUM('LOCAL', 'AWS_S3', 'AZURE_BLOB', 'GOOGLE_CLOUD') NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Connection details
  connection_string VARCHAR(500),
  access_key VARCHAR(255),
  secret_key VARCHAR(255),
  bucket_name VARCHAR(255),
  region VARCHAR(100),
  
  -- Storage settings
  max_storage_gb INT,
  current_usage_gb DECIMAL(10, 2),
  retention_days INT DEFAULT 30,
  
  -- Encryption
  encryption_enabled BOOLEAN DEFAULT TRUE,
  encryption_key_id VARCHAR(100),
  
  -- Metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_storage_type (storage_type),
  INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create views for reporting
CREATE OR REPLACE VIEW backup_summary AS
SELECT 
  DATE(bm.backup_date) as backup_date,
  bm.backup_type,
  COUNT(*) as backup_count,
  SUM(bm.file_size) as total_size,
  SUM(bm.compressed_size) as total_compressed_size,
  COUNT(CASE WHEN bm.backup_status = 'COMPLETED' THEN 1 END) as successful_backups,
  COUNT(CASE WHEN bm.backup_status = 'FAILED' THEN 1 END) as failed_backups
FROM backup_metadata bm
GROUP BY DATE(bm.backup_date), bm.backup_type;

CREATE OR REPLACE VIEW recovery_summary AS
SELECT 
  DATE(rr.created_at) as recovery_date,
  rr.recovery_type,
  COUNT(*) as recovery_count,
  COUNT(CASE WHEN rr.recovery_status = 'COMPLETED' THEN 1 END) as successful_recoveries,
  COUNT(CASE WHEN rr.recovery_status = 'FAILED' THEN 1 END) as failed_recoveries,
  AVG(rr.duration_seconds) as avg_duration_seconds
FROM recovery_requests rr
GROUP BY DATE(rr.created_at), rr.recovery_type;

-- Create indexes for performance
CREATE INDEX idx_backup_metadata_date_status ON backup_metadata(backup_date DESC, backup_status);
CREATE INDEX idx_backup_metadata_storage ON backup_metadata(storage_type, is_archived);
CREATE INDEX idx_backup_schedules_active ON backup_schedules(is_active, schedule_type);
CREATE INDEX idx_recovery_requests_status_date ON recovery_requests(recovery_status, created_at DESC);
CREATE INDEX idx_backup_audit_logs_action_date ON backup_audit_logs(action, action_timestamp DESC);
