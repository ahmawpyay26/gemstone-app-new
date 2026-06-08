/**
 * Application Initialization Module
 * 
 * Runs on backend startup to:
 * 1. Create default admin user if not exists
 * 2. Verify database connection
 * 3. Run any pending migrations
 * 4. Initialize caches
 */

const logger = require('../config/logger');
const { seedAdminUser } = require('../scripts/seedAdminUser');
const db = require('../config/database');

/**
 * Verify database connection
 * @returns {Promise<boolean>} - True if connection successful
 */
async function verifyDatabaseConnection() {
  try {
    logger.info('🔍 Verifying database connection...');
    
    const result = await db.query('SELECT NOW()');
    
    if (result.rows.length > 0) {
      logger.info('✅ Database connection verified successfully');
      return true;
    } else {
      logger.error('❌ Database connection verification failed');
      return false;
    }
  } catch (error) {
    logger.error('❌ Database connection error:', error);
    throw error;
  }
}

/**
 * Check if required tables exist
 * @returns {Promise<boolean>} - True if all required tables exist
 */
async function checkRequiredTables() {
  try {
    logger.info('🔍 Checking required database tables...');
    
    const requiredTables = [
      'users',
      'gemstones',
      'lots',
      'sales',
      'expenses',
      'audit_logs',
      'notifications'
    ];

    for (const table of requiredTables) {
      const query = `
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_name = $1
        )
      `;
      
      const result = await db.query(query, [table]);
      
      if (!result.rows[0].exists) {
        logger.warn(`⚠️  Table '${table}' does not exist`);
        return false;
      }
    }

    logger.info('✅ All required tables exist');
    return true;
  } catch (error) {
    logger.error('❌ Error checking tables:', error);
    throw error;
  }
}

/**
 * Initialize application on startup
 * @returns {Promise<Object>} - Initialization status
 */
async function initializeApp() {
  try {
    logger.info('🚀 Starting application initialization...');
    
    const status = {
      databaseConnected: false,
      tablesExist: false,
      adminUserCreated: false,
      timestamp: new Date().toISOString()
    };

    // 1. Verify database connection
    logger.info('📦 Step 1/3: Verifying database connection...');
    status.databaseConnected = await verifyDatabaseConnection();
    
    if (!status.databaseConnected) {
      throw new Error('Database connection failed');
    }

    // 2. Check required tables
    logger.info('📦 Step 2/3: Checking required tables...');
    status.tablesExist = await checkRequiredTables();
    
    if (!status.tablesExist) {
      logger.warn('⚠️  Some required tables are missing. Please run migrations.');
    }

    // 3. Seed admin user
    logger.info('📦 Step 3/3: Seeding default admin user...');
    try {
      await seedAdminUser();
      status.adminUserCreated = true;
    } catch (error) {
      logger.error('❌ Error seeding admin user:', error);
      // Don't throw - continue even if admin creation fails
      status.adminUserCreated = false;
    }

    logger.info('✅ Application initialization completed successfully', status);
    return status;
  } catch (error) {
    logger.error('❌ Application initialization failed:', error);
    throw error;
  }
}

/**
 * Health check function
 * @returns {Promise<Object>} - Health status
 */
async function healthCheck() {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      checks: {}
    };

    // Check database
    try {
      await db.query('SELECT 1');
      health.checks.database = 'ok';
    } catch (error) {
      health.checks.database = 'error';
      health.status = 'unhealthy';
    }

    // Check admin user
    try {
      const query = `
        SELECT COUNT(*) as count FROM users 
        WHERE role = $1
      `;
      const result = await db.query(query, ['Owner']);
      health.checks.adminUser = result.rows[0].count > 0 ? 'ok' : 'missing';
    } catch (error) {
      health.checks.adminUser = 'error';
    }

    return health;
  } catch (error) {
    logger.error('Health check error:', error);
    return {
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    };
  }
}

module.exports = {
  initializeApp,
  verifyDatabaseConnection,
  checkRequiredTables,
  healthCheck
};
