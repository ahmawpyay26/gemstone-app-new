-- Gemstone Management App - SQLite Offline Database Schema
-- This schema is used for local storage in Flutter mobile app
-- All tables include sync_status and updated_at for synchronization

-- ============================================================================
-- SYNC METADATA TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_metadata (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  last_sync_timestamp DATETIME,
  last_sync_status TEXT, -- 'success', 'failed', 'pending'
  pending_changes_count INTEGER DEFAULT 0,
  sync_enabled BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL, -- 'Owner', 'Accountant', 'Worker', 'Broker'
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  is_active BOOLEAN DEFAULT 1,
  last_login DATETIME,
  sync_status TEXT DEFAULT 'synced', -- 'pending', 'synced', 'failed'
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_sync_status ON users(sync_status);

-- ============================================================================
-- GEMSTONES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS gemstones (
  id TEXT PRIMARY KEY,
  qr_code TEXT UNIQUE,
  type TEXT NOT NULL, -- 'Ruby', 'Sapphire', 'Emerald', etc.
  carat_weight REAL NOT NULL,
  cut TEXT,
  color TEXT,
  clarity TEXT,
  shape TEXT,
  dimensions TEXT,
  origin TEXT,
  current_location TEXT,
  status TEXT DEFAULT 'raw', -- 'raw', 'processed', 'sold', 'waste'
  purchase_price REAL,
  purchase_date TEXT, -- ISO 8601 date
  total_cost REAL,
  lot_id TEXT,
  created_by TEXT,
  sync_status TEXT DEFAULT 'pending', -- 'pending', 'synced', 'failed'
  server_id TEXT, -- ID from server after sync
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(lot_id) REFERENCES lots(id),
  FOREIGN KEY(created_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_gemstones_qr_code ON gemstones(qr_code);
CREATE INDEX IF NOT EXISTS idx_gemstones_status ON gemstones(status);
CREATE INDEX IF NOT EXISTS idx_gemstones_lot_id ON gemstones(lot_id);
CREATE INDEX IF NOT EXISTS idx_gemstones_sync_status ON gemstones(sync_status);
CREATE INDEX IF NOT EXISTS idx_gemstones_updated_at ON gemstones(updated_at);

-- ============================================================================
-- LOTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS lots (
  id TEXT PRIMARY KEY,
  lot_number TEXT UNIQUE NOT NULL,
  total_carats REAL,
  total_cost REAL,
  purchase_date TEXT, -- ISO 8601 date
  status TEXT DEFAULT 'active', -- 'active', 'split', 'sold', 'closed'
  created_by TEXT,
  sync_status TEXT DEFAULT 'pending',
  server_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(created_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_lots_status ON lots(status);
CREATE INDEX IF NOT EXISTS idx_lots_sync_status ON lots(sync_status);
CREATE INDEX IF NOT EXISTS idx_lots_updated_at ON lots(updated_at);

-- ============================================================================
-- SALES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS sales (
  id TEXT PRIMARY KEY,
  gemstone_id TEXT NOT NULL,
  sale_price REAL NOT NULL,
  sale_date TEXT NOT NULL, -- ISO 8601 date
  buyer_name TEXT,
  buyer_phone TEXT,
  payment_method TEXT, -- 'cash', 'check', 'transfer', 'other'
  status TEXT DEFAULT 'completed', -- 'pending', 'completed', 'cancelled'
  notes TEXT,
  created_by TEXT,
  sync_status TEXT DEFAULT 'pending',
  server_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(gemstone_id) REFERENCES gemstones(id),
  FOREIGN KEY(created_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_sales_gemstone_id ON sales(gemstone_id);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status);
CREATE INDEX IF NOT EXISTS idx_sales_sync_status ON sales(sync_status);
CREATE INDEX IF NOT EXISTS idx_sales_updated_at ON sales(updated_at);

-- ============================================================================
-- EXPENSES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL, -- 'worker', 'machine', 'fuel', 'tool', 'broker', 'other'
  amount REAL NOT NULL,
  description TEXT,
  expense_date TEXT NOT NULL, -- ISO 8601 date
  related_gemstone_id TEXT,
  related_lot_id TEXT,
  created_by TEXT,
  sync_status TEXT DEFAULT 'pending',
  server_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(related_gemstone_id) REFERENCES gemstones(id),
  FOREIGN KEY(related_lot_id) REFERENCES lots(id),
  FOREIGN KEY(created_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_expenses_type ON expenses(type);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_sync_status ON expenses(sync_status);
CREATE INDEX IF NOT EXISTS idx_expenses_updated_at ON expenses(updated_at);

-- ============================================================================
-- WORKERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS workers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  role TEXT, -- 'cutter', 'polisher', 'cleaner', 'general'
  hourly_rate REAL,
  status TEXT DEFAULT 'active', -- 'active', 'inactive', 'terminated'
  hire_date TEXT, -- ISO 8601 date
  sync_status TEXT DEFAULT 'pending',
  server_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workers_status ON workers(status);
CREATE INDEX IF NOT EXISTS idx_workers_sync_status ON workers(sync_status);
CREATE INDEX IF NOT EXISTS idx_workers_updated_at ON workers(updated_at);

-- ============================================================================
-- WORKER PAYMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS worker_payments (
  id TEXT PRIMARY KEY,
  worker_id TEXT NOT NULL,
  amount REAL NOT NULL,
  payment_date TEXT NOT NULL, -- ISO 8601 date
  hours_worked REAL,
  notes TEXT,
  sync_status TEXT DEFAULT 'pending',
  server_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(worker_id) REFERENCES workers(id)
);

CREATE INDEX IF NOT EXISTS idx_worker_payments_worker_id ON worker_payments(worker_id);
CREATE INDEX IF NOT EXISTS idx_worker_payments_sync_status ON worker_payments(sync_status);
CREATE INDEX IF NOT EXISTS idx_worker_payments_updated_at ON worker_payments(updated_at);

-- ============================================================================
-- SYNC QUEUE TABLE (for tracking unsynced changes)
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT NOT NULL, -- 'gemstone', 'sale', 'expense', 'worker', etc.
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL, -- 'create', 'update', 'delete'
  data JSONB, -- JSON data for the entity
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  last_error TEXT,
  sync_status TEXT DEFAULT 'pending', -- 'pending', 'syncing', 'synced', 'failed'
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(sync_status);
CREATE INDEX IF NOT EXISTS idx_sync_queue_entity_type ON sync_queue(entity_type);
CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at);

-- ============================================================================
-- SYNC CONFLICTS TABLE (for tracking conflicts during sync)
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_conflicts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  local_data JSONB,
  server_data JSONB,
  conflict_type TEXT, -- 'update_conflict', 'delete_conflict', 'version_mismatch'
  resolution TEXT, -- 'local_wins', 'server_wins', 'manual', 'pending'
  resolved_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sync_conflicts_resolution ON sync_conflicts(resolution);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_entity_type ON sync_conflicts(entity_type);

-- ============================================================================
-- OFFLINE CACHE TABLE (for caching server responses)
-- ============================================================================

CREATE TABLE IF NOT EXISTS offline_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cache_key TEXT UNIQUE NOT NULL,
  cache_value JSONB,
  ttl_minutes INTEGER DEFAULT 60,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME
);

CREATE INDEX IF NOT EXISTS idx_offline_cache_expires_at ON offline_cache(expires_at);

-- ============================================================================
-- AUDIT LOGS TABLE (local audit trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  action TEXT NOT NULL,
  module TEXT,
  entity_type TEXT,
  entity_id TEXT,
  before_value JSONB,
  after_value JSONB,
  sync_status TEXT DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_sync_status ON audit_logs(sync_status);

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Pending syncs view
CREATE VIEW IF NOT EXISTS pending_syncs AS
SELECT 
  'gemstone' as entity_type,
  id,
  updated_at,
  sync_status
FROM gemstones
WHERE sync_status = 'pending'
UNION ALL
SELECT 
  'sale' as entity_type,
  id,
  updated_at,
  sync_status
FROM sales
WHERE sync_status = 'pending'
UNION ALL
SELECT 
  'expense' as entity_type,
  id,
  updated_at,
  sync_status
FROM expenses
WHERE sync_status = 'pending'
UNION ALL
SELECT 
  'worker' as entity_type,
  id,
  updated_at,
  sync_status
FROM workers
WHERE sync_status = 'pending'
ORDER BY updated_at DESC;

-- Sync status summary view
CREATE VIEW IF NOT EXISTS sync_status_summary AS
SELECT 
  'gemstones' as table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN sync_status = 'pending' THEN 1 ELSE 0 END) as pending_count,
  SUM(CASE WHEN sync_status = 'synced' THEN 1 ELSE 0 END) as synced_count,
  SUM(CASE WHEN sync_status = 'failed' THEN 1 ELSE 0 END) as failed_count
FROM gemstones
UNION ALL
SELECT 
  'sales' as table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN sync_status = 'pending' THEN 1 ELSE 0 END) as pending_count,
  SUM(CASE WHEN sync_status = 'synced' THEN 1 ELSE 0 END) as synced_count,
  SUM(CASE WHEN sync_status = 'failed' THEN 1 ELSE 0 END) as failed_count
FROM sales
UNION ALL
SELECT 
  'expenses' as table_name,
  COUNT(*) as total_records,
  SUM(CASE WHEN sync_status = 'pending' THEN 1 ELSE 0 END) as pending_count,
  SUM(CASE WHEN sync_status = 'synced' THEN 1 ELSE 0 END) as synced_count,
  SUM(CASE WHEN sync_status = 'failed' THEN 1 ELSE 0 END) as failed_count
FROM expenses;

-- ============================================================================
-- INITIALIZATION TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS gemstones_update_timestamp 
AFTER UPDATE ON gemstones
BEGIN
  UPDATE gemstones SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS sales_update_timestamp 
AFTER UPDATE ON sales
BEGIN
  UPDATE sales SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS expenses_update_timestamp 
AFTER UPDATE ON expenses
BEGIN
  UPDATE expenses SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS workers_update_timestamp 
AFTER UPDATE ON workers
BEGIN
  UPDATE workers SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Initialize sync metadata
INSERT OR IGNORE INTO sync_metadata (id, last_sync_timestamp, last_sync_status, pending_changes_count)
VALUES (1, NULL, 'never', 0);
