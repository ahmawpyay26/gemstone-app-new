-- ============================================================================
-- Gemstone Profit & Loss Calculation Engine - Database Schema
-- ============================================================================

-- ============================================================================
-- 1. LOT PURCHASE MANAGEMENT
-- ============================================================================

-- Lot Purchase Table
CREATE TABLE lot_purchases (
  id VARCHAR(36) PRIMARY KEY,
  purchase_date DATETIME NOT NULL,
  supplier_id VARCHAR(36),
  supplier_name VARCHAR(255),
  lot_number VARCHAR(100) UNIQUE NOT NULL,
  total_stones INT NOT NULL,
  total_carats DECIMAL(10, 2) NOT NULL,
  total_cost DECIMAL(15, 2) NOT NULL,
  cost_per_carat DECIMAL(10, 2) GENERATED ALWAYS AS (total_cost / total_carats) STORED,
  cost_per_stone DECIMAL(10, 2) GENERATED ALWAYS AS (total_cost / total_stones) STORED,
  status ENUM('ACTIVE', 'SPLIT', 'SOLD', 'ARCHIVED') DEFAULT 'ACTIVE',
  notes TEXT,
  created_by VARCHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_lot_number (lot_number),
  INDEX idx_status (status),
  INDEX idx_purchase_date (purchase_date),
  INDEX idx_supplier_id (supplier_id)
);

-- Individual Stone Table
CREATE TABLE gemstones (
  id VARCHAR(36) PRIMARY KEY,
  lot_purchase_id VARCHAR(36) NOT NULL,
  stone_number INT,
  name VARCHAR(255),
  type VARCHAR(100),
  color VARCHAR(100),
  clarity VARCHAR(100),
  carat_weight DECIMAL(10, 2) NOT NULL,
  cost_basis DECIMAL(15, 2) NOT NULL,
  cost_per_carat DECIMAL(10, 2) GENERATED ALWAYS AS (cost_basis / carat_weight) STORED,
  
  -- Stone Status
  status ENUM('INVENTORY', 'WASTE', 'SOLD', 'RESERVED') DEFAULT 'INVENTORY',
  waste_reason VARCHAR(255),
  waste_date DATETIME,
  
  -- Parent-Child Relationship (for split stones)
  parent_stone_id VARCHAR(36),
  split_date DATETIME,
  
  -- Current Location
  branch_id VARCHAR(36),
  location VARCHAR(255),
  
  -- Audit Trail
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (lot_purchase_id) REFERENCES lot_purchases(id),
  FOREIGN KEY (parent_stone_id) REFERENCES gemstones(id),
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  
  INDEX idx_lot_purchase_id (lot_purchase_id),
  INDEX idx_status (status),
  INDEX idx_parent_stone_id (parent_stone_id),
  INDEX idx_branch_id (branch_id),
  INDEX idx_cost_basis (cost_basis)
);

-- ============================================================================
-- 2. LOT SPLITTING TRACKING
-- ============================================================================

CREATE TABLE lot_splits (
  id VARCHAR(36) PRIMARY KEY,
  original_stone_id VARCHAR(36) NOT NULL,
  split_date DATETIME NOT NULL,
  split_reason VARCHAR(255),
  
  -- Split Details
  original_carat DECIMAL(10, 2) NOT NULL,
  original_cost DECIMAL(15, 2) NOT NULL,
  
  -- Cost Allocation Method
  allocation_method ENUM('EQUAL_WEIGHT', 'EQUAL_COUNT', 'CUSTOM') DEFAULT 'EQUAL_WEIGHT',
  
  -- Resulting Stones
  resulting_stone_count INT NOT NULL,
  total_resulting_carat DECIMAL(10, 2) NOT NULL,
  total_resulting_cost DECIMAL(15, 2) NOT NULL,
  
  -- Waste from Split
  waste_carat DECIMAL(10, 2) DEFAULT 0,
  waste_cost DECIMAL(15, 2) DEFAULT 0,
  
  created_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (original_stone_id) REFERENCES gemstones(id),
  
  INDEX idx_original_stone_id (original_stone_id),
  INDEX idx_split_date (split_date)
);

-- Split Result Details
CREATE TABLE lot_split_results (
  id VARCHAR(36) PRIMARY KEY,
  lot_split_id VARCHAR(36) NOT NULL,
  resulting_stone_id VARCHAR(36),
  resulting_carat DECIMAL(10, 2) NOT NULL,
  allocated_cost DECIMAL(15, 2) NOT NULL,
  cost_per_carat DECIMAL(10, 2) GENERATED ALWAYS AS (allocated_cost / resulting_carat) STORED,
  
  FOREIGN KEY (lot_split_id) REFERENCES lot_splits(id),
  FOREIGN KEY (resulting_stone_id) REFERENCES gemstones(id),
  
  INDEX idx_lot_split_id (lot_split_id),
  INDEX idx_resulting_stone_id (resulting_stone_id)
);

-- ============================================================================
-- 3. WASTE STONE TRACKING
-- ============================================================================

CREATE TABLE waste_stones (
  id VARCHAR(36) PRIMARY KEY,
  gemstone_id VARCHAR(36) NOT NULL,
  waste_date DATETIME NOT NULL,
  waste_reason VARCHAR(255) NOT NULL,
  
  -- Original Values
  original_carat DECIMAL(10, 2) NOT NULL,
  original_cost DECIMAL(15, 2) NOT NULL,
  
  -- Waste Allocation
  waste_carat DECIMAL(10, 2) NOT NULL,
  waste_cost DECIMAL(15, 2) NOT NULL,
  
  -- Remaining Values (if partial waste)
  remaining_carat DECIMAL(10, 2),
  remaining_cost DECIMAL(15, 2),
  
  -- Scrap Value (if any)
  scrap_value DECIMAL(15, 2) DEFAULT 0,
  scrap_date DATETIME,
  
  created_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  
  INDEX idx_gemstone_id (gemstone_id),
  INDEX idx_waste_date (waste_date)
);

-- ============================================================================
-- 4. EXPENSE ALLOCATION
-- ============================================================================

CREATE TABLE expenses (
  id VARCHAR(36) PRIMARY KEY,
  expense_date DATETIME NOT NULL,
  branch_id VARCHAR(36),
  
  -- Expense Details
  category ENUM('WORKER', 'MACHINE', 'FUEL_OIL', 'TOOLS', 'BROKER_COMMISSION', 'OTHER') NOT NULL,
  description VARCHAR(255),
  amount DECIMAL(15, 2) NOT NULL,
  
  -- Allocation
  allocation_method ENUM('EQUAL_STONES', 'EQUAL_WEIGHT', 'MANUAL', 'PERCENTAGE') DEFAULT 'EQUAL_STONES',
  
  -- Related Entities
  related_lot_id VARCHAR(36),
  related_sale_id VARCHAR(36),
  related_gemstone_ids JSON, -- Array of stone IDs
  
  status ENUM('PENDING', 'ALLOCATED', 'RECONCILED') DEFAULT 'PENDING',
  
  created_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  FOREIGN KEY (related_lot_id) REFERENCES lot_purchases(id),
  
  INDEX idx_expense_date (expense_date),
  INDEX idx_category (category),
  INDEX idx_status (status),
  INDEX idx_branch_id (branch_id)
);

-- Expense Allocation Details
CREATE TABLE expense_allocations (
  id VARCHAR(36) PRIMARY KEY,
  expense_id VARCHAR(36) NOT NULL,
  gemstone_id VARCHAR(36),
  lot_purchase_id VARCHAR(36),
  
  -- Allocation Amount
  allocated_amount DECIMAL(15, 2) NOT NULL,
  allocation_percentage DECIMAL(5, 2),
  
  -- Allocation Basis
  allocation_basis VARCHAR(100), -- 'WEIGHT', 'COUNT', 'PERCENTAGE', 'MANUAL'
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (expense_id) REFERENCES expenses(id),
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  FOREIGN KEY (lot_purchase_id) REFERENCES lot_purchases(id),
  
  INDEX idx_expense_id (expense_id),
  INDEX idx_gemstone_id (gemstone_id),
  INDEX idx_lot_purchase_id (lot_purchase_id)
);

-- ============================================================================
-- 5. SALES TRACKING
-- ============================================================================

CREATE TABLE sales (
  id VARCHAR(36) PRIMARY KEY,
  sale_date DATETIME NOT NULL,
  branch_id VARCHAR(36),
  
  -- Buyer Information
  buyer_id VARCHAR(36),
  buyer_name VARCHAR(255),
  buyer_type ENUM('RETAIL', 'WHOLESALE', 'BROKER') DEFAULT 'RETAIL',
  
  -- Sale Details
  total_stones INT NOT NULL,
  total_carats DECIMAL(10, 2) NOT NULL,
  total_sale_price DECIMAL(15, 2) NOT NULL,
  price_per_carat DECIMAL(10, 2) GENERATED ALWAYS AS (total_sale_price / total_carats) STORED,
  
  -- Broker Commission (if applicable)
  broker_commission DECIMAL(15, 2) DEFAULT 0,
  broker_commission_percentage DECIMAL(5, 2),
  
  -- Status
  status ENUM('PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED') DEFAULT 'PENDING',
  
  -- Profit Calculation
  total_cost DECIMAL(15, 2),
  gross_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total_sale_price - total_cost) STORED,
  profit_margin_percentage DECIMAL(5, 2) GENERATED ALWAYS AS ((total_sale_price - total_cost) / total_cost * 100) STORED,
  
  created_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  
  INDEX idx_sale_date (sale_date),
  INDEX idx_status (status),
  INDEX idx_branch_id (branch_id),
  INDEX idx_buyer_id (buyer_id)
);

-- Sale Line Items
CREATE TABLE sale_items (
  id VARCHAR(36) PRIMARY KEY,
  sale_id VARCHAR(36) NOT NULL,
  gemstone_id VARCHAR(36),
  
  -- Stone Details
  carat_weight DECIMAL(10, 2) NOT NULL,
  sale_price DECIMAL(15, 2) NOT NULL,
  
  -- Cost Basis
  cost_basis DECIMAL(15, 2) NOT NULL,
  allocated_expenses DECIMAL(15, 2) DEFAULT 0,
  total_cost DECIMAL(15, 2) GENERATED ALWAYS AS (cost_basis + allocated_expenses) STORED,
  
  -- Profit
  profit DECIMAL(15, 2) GENERATED ALWAYS AS (sale_price - total_cost) STORED,
  profit_margin_percentage DECIMAL(5, 2) GENERATED ALWAYS AS ((sale_price - total_cost) / total_cost * 100) STORED,
  
  FOREIGN KEY (sale_id) REFERENCES sales(id),
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  
  INDEX idx_sale_id (sale_id),
  INDEX idx_gemstone_id (gemstone_id)
);

-- ============================================================================
-- 6. PROFIT & LOSS SUMMARY
-- ============================================================================

CREATE TABLE daily_profit_loss (
  id VARCHAR(36) PRIMARY KEY,
  business_date DATE NOT NULL,
  branch_id VARCHAR(36),
  
  -- Sales Summary
  total_sales_count INT DEFAULT 0,
  total_sales_carats DECIMAL(10, 2) DEFAULT 0,
  total_sales_revenue DECIMAL(15, 2) DEFAULT 0,
  
  -- Cost Summary
  total_purchases_count INT DEFAULT 0,
  total_purchases_carats DECIMAL(10, 2) DEFAULT 0,
  total_purchases_cost DECIMAL(15, 2) DEFAULT 0,
  
  -- Expenses
  total_expenses DECIMAL(15, 2) DEFAULT 0,
  
  -- Waste
  waste_count INT DEFAULT 0,
  waste_carats DECIMAL(10, 2) DEFAULT 0,
  waste_cost DECIMAL(15, 2) DEFAULT 0,
  
  -- Profit/Loss
  gross_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total_sales_revenue - total_purchases_cost) STORED,
  net_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total_sales_revenue - total_purchases_cost - total_expenses) STORED,
  profit_margin_percentage DECIMAL(5, 2) GENERATED ALWAYS AS (
    CASE 
      WHEN total_sales_revenue > 0 THEN (total_sales_revenue - total_purchases_cost - total_expenses) / total_sales_revenue * 100
      ELSE 0
    END
  ) STORED,
  
  UNIQUE KEY unique_date_branch (business_date, branch_id),
  
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  
  INDEX idx_business_date (business_date),
  INDEX idx_branch_id (branch_id)
);

-- Monthly Profit & Loss Summary
CREATE TABLE monthly_profit_loss (
  id VARCHAR(36) PRIMARY KEY,
  year_month VARCHAR(7) NOT NULL, -- YYYY-MM
  branch_id VARCHAR(36),
  
  -- Sales Summary
  total_sales_count INT DEFAULT 0,
  total_sales_carats DECIMAL(10, 2) DEFAULT 0,
  total_sales_revenue DECIMAL(15, 2) DEFAULT 0,
  
  -- Cost Summary
  total_purchases_count INT DEFAULT 0,
  total_purchases_carats DECIMAL(10, 2) DEFAULT 0,
  total_purchases_cost DECIMAL(15, 2) DEFAULT 0,
  
  -- Expenses
  total_expenses DECIMAL(15, 2) DEFAULT 0,
  
  -- Waste
  waste_count INT DEFAULT 0,
  waste_carats DECIMAL(10, 2) DEFAULT 0,
  waste_cost DECIMAL(15, 2) DEFAULT 0,
  
  -- Profit/Loss
  gross_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total_sales_revenue - total_purchases_cost) STORED,
  net_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total_sales_revenue - total_purchases_cost - total_expenses) STORED,
  profit_margin_percentage DECIMAL(5, 2) GENERATED ALWAYS AS (
    CASE 
      WHEN total_sales_revenue > 0 THEN (total_sales_revenue - total_purchases_cost - total_expenses) / total_sales_revenue * 100
      ELSE 0
    END
  ) STORED,
  
  UNIQUE KEY unique_month_branch (year_month, branch_id),
  
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  
  INDEX idx_year_month (year_month),
  INDEX idx_branch_id (branch_id)
);

-- ============================================================================
-- 7. COST BASIS TRACKING (Audit Trail)
-- ============================================================================

CREATE TABLE cost_basis_history (
  id VARCHAR(36) PRIMARY KEY,
  gemstone_id VARCHAR(36) NOT NULL,
  
  -- Change Details
  change_type ENUM('INITIAL', 'SPLIT', 'WASTE_ADJUSTMENT', 'EXPENSE_ALLOCATION', 'REVERSAL') NOT NULL,
  change_date DATETIME NOT NULL,
  
  -- Values
  previous_cost_basis DECIMAL(15, 2),
  new_cost_basis DECIMAL(15, 2),
  cost_change DECIMAL(15, 2),
  
  -- Related Transactions
  related_transaction_id VARCHAR(36),
  related_transaction_type VARCHAR(100),
  
  -- Audit
  created_by VARCHAR(36),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id),
  
  INDEX idx_gemstone_id (gemstone_id),
  INDEX idx_change_date (change_date),
  INDEX idx_change_type (change_type)
);

-- ============================================================================
-- 8. FINANCIAL VALIDATION & RECONCILIATION
-- ============================================================================

CREATE TABLE financial_reconciliation (
  id VARCHAR(36) PRIMARY KEY,
  reconciliation_date DATETIME NOT NULL,
  branch_id VARCHAR(36),
  
  -- Inventory Valuation
  total_stones_in_inventory INT,
  total_carats_in_inventory DECIMAL(10, 2),
  total_cost_basis_inventory DECIMAL(15, 2),
  
  -- Validation Results
  validation_status ENUM('PASSED', 'FAILED', 'WARNINGS') DEFAULT 'PASSED',
  validation_errors JSON,
  validation_warnings JSON,
  
  -- Reconciliation Details
  reconciled_by VARCHAR(36),
  reconciliation_notes TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (branch_id) REFERENCES branches(id),
  
  INDEX idx_reconciliation_date (reconciliation_date),
  INDEX idx_branch_id (branch_id)
);

-- ============================================================================
-- 9. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Composite indexes for common queries
CREATE INDEX idx_gemstone_lot_status ON gemstones(lot_purchase_id, status);
CREATE INDEX idx_sale_items_sale_date ON sale_items 
  USING (SELECT s.sale_date FROM sales s WHERE s.id = sale_items.sale_id);
CREATE INDEX idx_expense_allocation_gemstone ON expense_allocations(gemstone_id, expense_id);
CREATE INDEX idx_daily_profit_loss_date_branch ON daily_profit_loss(business_date, branch_id);
CREATE INDEX idx_monthly_profit_loss_month_branch ON monthly_profit_loss(year_month, branch_id);

-- ============================================================================
-- 10. VIEWS FOR REPORTING
-- ============================================================================

-- Current Inventory Valuation
CREATE VIEW inventory_valuation AS
SELECT 
  g.id,
  g.lot_purchase_id,
  g.carat_weight,
  g.cost_basis,
  g.status,
  g.branch_id,
  lp.lot_number,
  lp.purchase_date,
  (SELECT COALESCE(SUM(allocated_amount), 0) 
   FROM expense_allocations 
   WHERE gemstone_id = g.id) as allocated_expenses,
  (g.cost_basis + COALESCE((SELECT SUM(allocated_amount) FROM expense_allocations WHERE gemstone_id = g.id), 0)) as total_cost
FROM gemstones g
LEFT JOIN lot_purchases lp ON g.lot_purchase_id = lp.id
WHERE g.status IN ('INVENTORY', 'RESERVED');

-- Profit Analysis by Lot
CREATE VIEW lot_profit_analysis AS
SELECT 
  lp.id,
  lp.lot_number,
  lp.purchase_date,
  lp.total_stones,
  lp.total_carats,
  lp.total_cost,
  COUNT(DISTINCT si.sale_id) as sales_count,
  SUM(si.carat_weight) as sold_carats,
  SUM(si.sale_price) as total_sale_price,
  SUM(si.total_cost) as total_cost_sold,
  SUM(si.profit) as total_profit,
  AVG(si.profit_margin_percentage) as avg_profit_margin
FROM lot_purchases lp
LEFT JOIN gemstones g ON lp.id = g.lot_purchase_id
LEFT JOIN sale_items si ON g.id = si.gemstone_id
GROUP BY lp.id;

-- Profit Analysis by Branch
CREATE VIEW branch_profit_analysis AS
SELECT 
  b.id,
  b.name,
  DATE(s.sale_date) as sale_date,
  COUNT(DISTINCT s.id) as sales_count,
  SUM(si.carat_weight) as total_carats_sold,
  SUM(si.sale_price) as total_revenue,
  SUM(si.total_cost) as total_cost,
  SUM(si.profit) as total_profit,
  AVG(si.profit_margin_percentage) as avg_profit_margin
FROM branches b
LEFT JOIN sales s ON b.id = s.branch_id
LEFT JOIN sale_items si ON s.id = si.sale_id
GROUP BY b.id, DATE(s.sale_date);
