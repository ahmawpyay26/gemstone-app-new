/**
 * Database Initialization Script
 * 
 * This script runs on Railway startup to:
 * 1. Create database tables if they don't exist
 * 2. Run migrations
 * 3. Create default admin user
 * 
 * Called from server startup
 */

const db = require('../config/database');
const logger = require('../config/logger');
const { seedAdminUser } = require('./seedAdminUser');

/**
 * Create all required tables
 */
async function createTables() {
  try {
    logger.info('🔨 Creating database tables...');

    // Users table
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'Worker',
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        phone VARCHAR(20),
        is_active BOOLEAN DEFAULT true,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Gemstones table
    await db.query(`
      CREATE TABLE IF NOT EXISTS gemstones (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        qr_code VARCHAR(255) UNIQUE,
        type VARCHAR(100) NOT NULL,
        carat_weight DECIMAL(10, 2) NOT NULL,
        cut VARCHAR(100),
        color VARCHAR(100),
        clarity VARCHAR(100),
        shape VARCHAR(100),
        dimensions VARCHAR(100),
        origin VARCHAR(100),
        current_location VARCHAR(255),
        status VARCHAR(50) DEFAULT 'raw',
        purchase_price DECIMAL(12, 2),
        purchase_date DATE,
        total_cost DECIMAL(12, 2),
        lot_id UUID,
        created_by UUID,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Lots table
    await db.query(`
      CREATE TABLE IF NOT EXISTS lots (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        lot_number VARCHAR(255) UNIQUE NOT NULL,
        total_carats DECIMAL(10, 2),
        total_cost DECIMAL(12, 2),
        purchase_date DATE,
        status VARCHAR(50) DEFAULT 'active',
        created_by UUID,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Sales table
    await db.query(`
      CREATE TABLE IF NOT EXISTS sales (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        gemstone_id UUID,
        sale_price DECIMAL(12, 2),
        sale_date DATE,
        buyer_name VARCHAR(255),
        status VARCHAR(50) DEFAULT 'completed',
        created_by UUID,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Expenses table
    await db.query(`
      CREATE TABLE IF NOT EXISTS expenses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        type VARCHAR(100),
        amount DECIMAL(12, 2),
        description TEXT,
        expense_date DATE,
        created_by UUID,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Audit logs table
    await db.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID,
        action VARCHAR(100),
        module VARCHAR(100),
        before_value JSONB,
        after_value JSONB,
        ip_address VARCHAR(45),
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Notifications table
    await db.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID,
        type VARCHAR(100),
        title VARCHAR(255),
        message TEXT,
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    logger.info('✅ All tables created successfully');
    return true;
  } catch (error) {
    logger.error('❌ Error creating tables:', error);
    throw error;
  }
}

/**
 * Create indexes for better performance
 */
async function createIndexes() {
  try {
    logger.info('🔍 Creating database indexes...');

    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
      'CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)',
      'CREATE INDEX IF NOT EXISTS idx_gemstones_status ON gemstones(status)',
      'CREATE INDEX IF NOT EXISTS idx_gemstones_lot_id ON gemstones(lot_id)',
      'CREATE INDEX IF NOT EXISTS idx_lots_status ON lots(status)',
      'CREATE INDEX IF NOT EXISTS idx_sales_gemstone_id ON sales(gemstone_id)',
      'CREATE INDEX IF NOT EXISTS idx_expenses_type ON expenses(type)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read)'
    ];

    for (const index of indexes) {
      await db.query(index);
    }

    logger.info('✅ All indexes created successfully');
    return true;
  } catch (error) {
    logger.error('❌ Error creating indexes:', error);
    throw error;
  }
}

/**
 * Initialize database on startup
 */
async function initializeDatabase() {
  try {
    logger.info('🚀 Starting database initialization...');

    // 1. Create tables
    await createTables();

    // 2. Create indexes
    await createIndexes();

    // 3. Seed admin user
    logger.info('👤 Creating default admin user...');
    await seedAdminUser();

    logger.info('✅ Database initialization completed successfully');
    return true;
  } catch (error) {
    logger.error('❌ Database initialization failed:', error);
    throw error;
  }
}

module.exports = {
  initializeDatabase,
  createTables,
  createIndexes
};

// Run if called directly
if (require.main === module) {
  initializeDatabase()
    .then(() => {
      logger.info('✅ Database ready');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Database initialization failed:', error);
      process.exit(1);
    });
}
