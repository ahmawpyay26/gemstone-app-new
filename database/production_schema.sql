-- ========================================================
-- Gemstone Management System - Production Database Schema
-- Database: PostgreSQL
-- ========================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS & ROLES
CREATE TYPE user_role AS ENUM ('owner', 'accountant', 'worker', 'broker');

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role user_role NOT NULL DEFAULT 'worker',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. LOT MANAGEMENT (Bulk Purchases)
CREATE TABLE IF NOT EXISTS lots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lot_number VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    total_carats DECIMAL(12, 3) NOT NULL,
    total_stones INTEGER NOT NULL,
    purchase_price DECIMAL(15, 2) NOT NULL,
    purchase_date DATE NOT NULL,
    supplier_name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'split', 'completed'
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. GEMSTONE INVENTORY
CREATE TYPE stone_status AS ENUM ('raw', 'in_process', 'polished', 'sold', 'waste', 'damaged');

CREATE TABLE IF NOT EXISTS gemstones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qr_code VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(100) NOT NULL, -- Ruby, Sapphire, etc.
    carat_weight DECIMAL(10, 3) NOT NULL,
    cut VARCHAR(100),
    color VARCHAR(100),
    clarity VARCHAR(100),
    shape VARCHAR(100),
    origin VARCHAR(100),
    status stone_status DEFAULT 'raw',
    lot_id UUID REFERENCES lots(id) ON DELETE SET NULL, -- Null if individual purchase
    purchase_price DECIMAL(15, 2), -- Allocated price if from lot, or direct price
    total_cost DECIMAL(15, 2) DEFAULT 0, -- purchase_price + accumulated expenses
    current_location VARCHAR(255),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. WORKER & MACHINE MANAGEMENT
CREATE TABLE IF NOT EXISTS workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    specialization VARCHAR(100),
    daily_rate DECIMAL(12, 2),
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS machines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(100),
    purchase_date DATE,
    purchase_cost DECIMAL(15, 2),
    maintenance_interval_days INTEGER,
    status VARCHAR(50) DEFAULT 'active'
);

-- 5. PROCESSING & EXPENSE TRACKING
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gemstone_id UUID REFERENCES gemstones(id) ON DELETE CASCADE,
    expense_type VARCHAR(100) NOT NULL, -- 'worker_cost', 'machine_oil', 'grinding_tool', etc.
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    worker_id UUID REFERENCES workers(id),
    machine_id UUID REFERENCES machines(id),
    expense_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- 6. SALES TRACKING
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(100) UNIQUE NOT NULL,
    customer_name VARCHAR(255),
    sale_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(15, 2) NOT NULL,
    broker_id UUID REFERENCES users(id), -- If role is 'broker'
    broker_commission DECIMAL(15, 2) DEFAULT 0,
    payment_status VARCHAR(50) DEFAULT 'paid', -- 'pending', 'paid', 'partial'
    notes TEXT,
    created_by UUID REFERENCES users(id)
);

-- 7. SALE ITEMS (Link stones to sales)
CREATE TABLE IF NOT EXISTS sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
    gemstone_id UUID REFERENCES gemstones(id),
    sale_price DECIMAL(15, 2) NOT NULL,
    UNIQUE(gemstone_id) -- A stone can only be sold once
);

-- 8. WASTE & DAMAGE TRACKING
CREATE TABLE IF NOT EXISTS waste_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gemstone_id UUID REFERENCES gemstones(id),
    waste_type VARCHAR(50), -- 'waste', 'damaged'
    carat_loss DECIMAL(10, 3),
    reason TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    recorded_by UUID REFERENCES users(id)
);

-- ========================================================
-- VIEWS & LOGIC FOR PROFIT CALCULATION
-- ========================================================

-- Trigger to update gemstone total_cost when an expense is added
CREATE OR REPLACE FUNCTION update_gemstone_cost()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE gemstones 
    SET total_cost = total_cost + NEW.amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.gemstone_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_cost
AFTER INSERT ON expenses
FOR EACH ROW
EXECUTE FUNCTION update_gemstone_cost();

-- View for Profit & Loss per Stone
CREATE OR REPLACE VIEW v_stone_profit_loss AS
SELECT 
    g.id AS stone_id,
    g.qr_code,
    g.type,
    g.carat_weight,
    g.total_cost AS accumulated_cost,
    si.sale_price,
    (si.sale_price - g.total_cost) AS net_profit,
    CASE 
        WHEN g.total_cost > 0 THEN ((si.sale_price - g.total_cost) / g.total_cost) * 100 
        ELSE 0 
    END AS profit_percentage
FROM gemstones g
JOIN sale_items si ON g.id = si.gemstone_id
WHERE g.status = 'sold';

-- View for Overall Sales Report
CREATE OR REPLACE VIEW v_sales_report AS
SELECT 
    s.id AS sale_id,
    s.invoice_number,
    s.sale_date,
    s.total_amount AS gross_sales,
    s.broker_commission,
    SUM(g.total_cost) AS total_cost_of_goods,
    (s.total_amount - s.broker_commission - SUM(g.total_cost)) AS net_profit
FROM sales s
JOIN sale_items si ON s.id = si.sale_id
JOIN gemstones g ON si.gemstone_id = g.id
GROUP BY s.id, s.invoice_number, s.sale_date, s.total_amount, s.broker_commission;

-- ========================================================
-- INDEXES FOR PERFORMANCE
-- ========================================================
CREATE INDEX idx_gemstones_qr ON gemstones(qr_code);
CREATE INDEX idx_gemstones_status ON gemstones(status);
CREATE INDEX idx_expenses_gemstone ON expenses(gemstone_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_lots_number ON lots(lot_number);
