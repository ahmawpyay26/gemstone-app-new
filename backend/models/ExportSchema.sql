-- Export Logs Table
CREATE TABLE IF NOT EXISTS export_logs (
  id VARCHAR(36) PRIMARY KEY,
  report_type ENUM('DAILY_SALES', 'MONTHLY_SALES', 'PROFIT_LOSS', 'INVENTORY', 'EXPENSE', 'WORKER_PAYMENT', 'SALES', 'PROFIT_LOSS') NOT NULL,
  filename VARCHAR(255) NOT NULL,
  format ENUM('PDF', 'EXCEL') NOT NULL,
  period VARCHAR(100),
  branch_id VARCHAR(36),
  created_by VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  file_size BIGINT,
  download_count INT DEFAULT 0,
  
  INDEX idx_report_type (report_type),
  INDEX idx_created_at (created_at),
  INDEX idx_branch_id (branch_id),
  INDEX idx_created_by (created_by),
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Export Audit Log Table
CREATE TABLE IF NOT EXISTS export_audit_logs (
  id VARCHAR(36) PRIMARY KEY,
  export_id VARCHAR(36) NOT NULL,
  user_id VARCHAR(36) NOT NULL,
  action ENUM('CREATED', 'DOWNLOADED', 'DELETED', 'SHARED') NOT NULL,
  action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45),
  user_agent VARCHAR(500),
  notes TEXT,
  
  INDEX idx_export_id (export_id),
  INDEX idx_user_id (user_id),
  INDEX idx_action (action),
  INDEX idx_timestamp (action_timestamp),
  FOREIGN KEY (export_id) REFERENCES export_logs(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Export Settings Table
CREATE TABLE IF NOT EXISTS export_settings (
  id VARCHAR(36) PRIMARY KEY,
  branch_id VARCHAR(36),
  company_name VARCHAR(255),
  company_logo_path VARCHAR(500),
  company_address TEXT,
  company_phone VARCHAR(20),
  company_email VARCHAR(100),
  default_language ENUM('mm', 'en') DEFAULT 'mm',
  include_logo BOOLEAN DEFAULT TRUE,
  include_company_info BOOLEAN DEFAULT TRUE,
  page_orientation ENUM('PORTRAIT', 'LANDSCAPE') DEFAULT 'PORTRAIT',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_branch (branch_id),
  FOREIGN KEY (branch_id) REFERENCES branches(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create indexes for performance
CREATE INDEX idx_export_logs_report_type_date ON export_logs(report_type, created_at DESC);
CREATE INDEX idx_export_logs_branch_date ON export_logs(branch_id, created_at DESC);
CREATE INDEX idx_export_audit_logs_user_date ON export_audit_logs(user_id, action_timestamp DESC);

-- View for export summary
CREATE OR REPLACE VIEW export_summary AS
SELECT 
  DATE(el.created_at) as export_date,
  el.report_type,
  el.format,
  COUNT(*) as export_count,
  SUM(el.file_size) as total_size,
  COUNT(DISTINCT el.created_by) as unique_users
FROM export_logs el
GROUP BY DATE(el.created_at), el.report_type, el.format;

-- View for export audit summary
CREATE OR REPLACE VIEW export_audit_summary AS
SELECT 
  DATE(eal.action_timestamp) as audit_date,
  eal.action,
  COUNT(*) as action_count,
  COUNT(DISTINCT eal.user_id) as unique_users
FROM export_audit_logs eal
GROUP BY DATE(eal.action_timestamp), eal.action;
