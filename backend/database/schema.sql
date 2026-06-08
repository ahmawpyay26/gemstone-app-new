-- Gemstone Management System Database Schema
-- PostgreSQL

-- ============================================
-- 1. USERS TABLE (Authentication & User Management)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(20),
  role VARCHAR(50) NOT NULL DEFAULT 'worker', -- owner, accountant, worker, broker
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 2. GEMSTONES TABLE (Individual Stone Inventory)
-- ============================================
CREATE TABLE IF NOT EXISTS gemstones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  qr_code VARCHAR(100) UNIQUE NOT NULL,
  type VARCHAR(100) NOT NULL, -- Ruby, Sapphire, Emerald, etc.
  carat_weight DECIMAL(10, 3) NOT NULL,
  cut VARCHAR(100), -- Oval, Round, Cushion, etc.
  color VARCHAR(100),
  clarity VARCHAR(50), -- VS1, SI1, etc.
  shape VARCHAR(100),
  dimensions VARCHAR(100),
  origin VARCHAR(100),
  status VARCHAR(50) DEFAULT 'raw', -- raw, in_process, polished, sold, waste, damaged
  current_location VARCHAR(255),
  
  -- Cost tracking
  purchase_price DECIMAL(15, 2),
  purchase_date DATE,
  total_cost DECIMAL(15, 2), -- Purchase price + processing costs
  
  -- Lot information
  lot_id UUID,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 3. LOTS TABLE (Bulk Gemstone Lots)
-- ============================================
CREATE TABLE IF NOT EXISTS lots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_number VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  total_carats DECIMAL(10, 3) NOT NULL,
  total_stones INT NOT NULL,
  purchase_price DECIMAL(15, 2) NOT NULL,
  purchase_date DATE NOT NULL,
  supplier_name VARCHAR(255),
  status VARCHAR(50) DEFAULT 'active', -- active, split, completed
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 4. LOT SPLITS TABLE (Track lot splitting operations)
-- ============================================
CREATE TABLE IF NOT EXISTS lot_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id UUID NOT NULL,
  split_date DATE NOT NULL,
  waste_carats DECIMAL(10, 3) DEFAULT 0,
  damaged_carats DECIMAL(10, 3) DEFAULT 0,
  notes TEXT,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (lot_id) REFERENCES lots(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 5. PROCESSING RECORDS TABLE (Polishing, Cutting, etc.)
-- ============================================
CREATE TABLE IF NOT EXISTS processing_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gemstone_id UUID NOT NULL,
  process_type VARCHAR(100) NOT NULL, -- polishing, cutting, heating, etc.
  worker_id UUID,
  machine_id UUID,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP,
  status VARCHAR(50) DEFAULT 'in_progress', -- in_progress, completed, failed
  notes TEXT,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  FOREIGN KEY (worker_id) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 6. WORKERS TABLE (Worker Management)
-- ============================================
CREATE TABLE IF NOT EXISTS workers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  specialization VARCHAR(255), -- polishing, cutting, etc.
  hourly_rate DECIMAL(10, 2),
  daily_rate DECIMAL(10, 2),
  status VARCHAR(50) DEFAULT 'active', -- active, inactive, on_leave
  hire_date DATE,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================
-- 7. MACHINES TABLE (Machine Management)
-- ============================================
CREATE TABLE IF NOT EXISTS machines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  machine_type VARCHAR(100), -- polisher, cutter, etc.
  purchase_date DATE,
  purchase_cost DECIMAL(15, 2),
  status VARCHAR(50) DEFAULT 'active', -- active, maintenance, inactive
  last_maintenance_date DATE,
  maintenance_cost_per_month DECIMAL(10, 2),
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 8. EXPENSES TABLE (Cost Tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gemstone_id UUID,
  expense_type VARCHAR(100) NOT NULL, -- worker_cost, machine_cost, oil, tools, etc.
  description TEXT,
  amount DECIMAL(15, 2) NOT NULL,
  expense_date DATE NOT NULL,
  worker_id UUID,
  machine_id UUID,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  FOREIGN KEY (worker_id) REFERENCES workers(id),
  FOREIGN KEY (machine_id) REFERENCES machines(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 9. SALES TABLE (Sales Tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_number VARCHAR(100) UNIQUE NOT NULL,
  customer_name VARCHAR(255),
  customer_email VARCHAR(255),
  customer_phone VARCHAR(20),
  sale_date DATE NOT NULL,
  total_sale_price DECIMAL(15, 2) NOT NULL,
  broker_id UUID,
  broker_commission DECIMAL(15, 2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'completed', -- pending, completed, cancelled
  notes TEXT,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (broker_id) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- 10. SALE ITEMS TABLE (Individual items in a sale)
-- ============================================
CREATE TABLE IF NOT EXISTS sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID NOT NULL,
  gemstone_id UUID NOT NULL,
  sale_price DECIMAL(15, 2) NOT NULL,
  quantity INT DEFAULT 1,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id)
);

-- ============================================
-- 11. BROKERS TABLE (Broker Management)
-- ============================================
CREATE TABLE IF NOT EXISTS brokers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  company_name VARCHAR(255),
  commission_percentage DECIMAL(5, 2), -- e.g., 5.00 for 5%
  status VARCHAR(50) DEFAULT 'active',
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================
-- 12. WASTE STONES TABLE (Track waste/damaged stones)
-- ============================================
CREATE TABLE IF NOT EXISTS waste_stones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gemstone_id UUID,
  lot_id UUID,
  waste_type VARCHAR(50) NOT NULL, -- waste, damaged
  carats DECIMAL(10, 3),
  reason TEXT,
  recorded_date DATE NOT NULL,
  
  -- Audit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL,
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  FOREIGN KEY (lot_id) REFERENCES lots(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- ============================================
-- INDEXES (Performance Optimization)
-- ============================================
CREATE INDEX idx_gemstones_qr_code ON gemstones(qr_code);
CREATE INDEX idx_gemstones_status ON gemstones(status);
CREATE INDEX idx_gemstones_lot_id ON gemstones(lot_id);
CREATE INDEX idx_lots_status ON lots(status);
CREATE INDEX idx_sales_sale_date ON sales(sale_date);
CREATE INDEX idx_sales_status ON sales(status);
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_processing_records_gemstone_id ON processing_records(gemstone_id);
CREATE INDEX idx_processing_records_status ON processing_records(status);

-- ============================================
-- VIEWS (For Reporting)
-- ============================================

-- Profit & Loss Summary View
CREATE OR REPLACE VIEW v_profit_loss_summary AS
SELECT 
  s.id as sale_id,
  s.sale_number,
  s.sale_date,
  s.total_sale_price,
  COALESCE(SUM(e.amount), 0) as total_expenses,
  COALESCE(s.broker_commission, 0) as broker_commission,
  (s.total_sale_price - COALESCE(SUM(e.amount), 0) - COALESCE(s.broker_commission, 0)) as profit
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
LEFT JOIN gemstones g ON si.gemstone_id = g.id
LEFT JOIN expenses e ON g.id = e.gemstone_id
GROUP BY s.id, s.sale_number, s.sale_date, s.total_sale_price, s.broker_commission;

-- Inventory Valuation View
CREATE OR REPLACE VIEW v_inventory_valuation AS
SELECT 
  COUNT(*) as total_stones,
  SUM(carat_weight) as total_carats,
  SUM(total_cost) as total_inventory_value,
  status
FROM gemstones
WHERE status NOT IN ('sold', 'waste', 'damaged')
GROUP BY status;

-- Worker Performance View
CREATE OR REPLACE VIEW v_worker_performance AS
SELECT 
  w.id,
  u.first_name,
  u.last_name,
  COUNT(pr.id) as total_processes,
  COUNT(CASE WHEN pr.status = 'completed' THEN 1 END) as completed_processes,
  COUNT(CASE WHEN pr.status = 'failed' THEN 1 END) as failed_processes
FROM workers w
JOIN users u ON w.user_id = u.id
LEFT JOIN processing_records pr ON w.id = pr.worker_id
GROUP BY w.id, u.first_name, u.last_name;
