/**
 * Seed Script: Create Default Admin User
 * 
 * This script creates a default admin user on backend startup if it doesn't exist.
 * Email: admin@gemstone.com
 * Password: admin123 (hashed with bcrypt)
 * Role: Owner
 * 
 * Usage:
 * - Called automatically on server startup
 * - Can also be run manually: node seedAdminUser.js
 */

const bcrypt = require('bcryptjs');
const db = require('../config/database');
const logger = require('../config/logger');

/**
 * Hash password using bcrypt
 * @param {string} password - Plain text password
 * @returns {Promise<string>} - Hashed password
 */
async function hashPassword(password) {
  try {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    return hashedPassword;
  } catch (error) {
    logger.error('Error hashing password:', error);
    throw error;
  }
}

/**
 * Check if admin user exists
 * @returns {Promise<boolean>} - True if admin exists, false otherwise
 */
async function adminUserExists() {
  try {
    const query = `
      SELECT id FROM users 
      WHERE email = $1 AND role = $2
      LIMIT 1
    `;
    const result = await db.query(query, ['admin@gemstone.com', 'Owner']);
    return result.rows.length > 0;
  } catch (error) {
    logger.error('Error checking admin user existence:', error);
    throw error;
  }
}

/**
 * Create default admin user
 * @returns {Promise<Object>} - Created user object
 */
async function createAdminUser() {
  try {
    const email = 'admin@gemstone.com';
    const plainPassword = 'admin123';
    const role = 'Owner';
    
    // Check if admin already exists
    const exists = await adminUserExists();
    if (exists) {
      logger.info('Admin user already exists. Skipping creation.');
      return null;
    }

    // Hash password
    const hashedPassword = await hashPassword(plainPassword);

    // Create admin user
    const query = `
      INSERT INTO users (
        email, 
        password, 
        role, 
        first_name, 
        last_name, 
        phone, 
        is_active, 
        created_at, 
        updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, NOW(), NOW()
      )
      RETURNING id, email, role, first_name, last_name, is_active, created_at
    `;

    const result = await db.query(query, [
      email,
      hashedPassword,
      role,
      'Admin',
      'User',
      '+95-1-000-0000',
      true
    ]);

    const adminUser = result.rows[0];
    
    logger.info('✅ Default admin user created successfully', {
      id: adminUser.id,
      email: adminUser.email,
      role: adminUser.role,
      createdAt: adminUser.created_at
    });

    return adminUser;
  } catch (error) {
    logger.error('❌ Error creating admin user:', error);
    throw error;
  }
}

/**
 * Verify admin user credentials
 * @returns {Promise<boolean>} - True if credentials are correct
 */
async function verifyAdminCredentials() {
  try {
    const query = `
      SELECT id, password FROM users 
      WHERE email = $1 AND role = $2
      LIMIT 1
    `;
    const result = await db.query(query, ['admin@gemstone.com', 'Owner']);
    
    if (result.rows.length === 0) {
      logger.warn('Admin user not found');
      return false;
    }

    const user = result.rows[0];
    const plainPassword = 'admin123';
    
    // Verify password
    const isPasswordValid = await bcrypt.compare(plainPassword, user.password);
    
    if (isPasswordValid) {
      logger.info('✅ Admin credentials verified successfully');
      return true;
    } else {
      logger.warn('❌ Admin password verification failed');
      return false;
    }
  } catch (error) {
    logger.error('Error verifying admin credentials:', error);
    throw error;
  }
}

/**
 * Main function - Seed admin user
 */
async function seedAdminUser() {
  try {
    logger.info('🌱 Starting admin user seed process...');

    // Create admin user if not exists
    const createdUser = await createAdminUser();

    if (createdUser) {
      logger.info('✅ Admin user creation completed');
      
      // Verify credentials
      const isVerified = await verifyAdminCredentials();
      
      if (isVerified) {
        logger.info('✅ Admin user seed process completed successfully');
        logger.info('📧 Admin Email: admin@gemstone.com');
        logger.info('🔐 Admin Password: admin123');
        logger.info('👤 Admin Role: Owner');
      } else {
        logger.error('❌ Admin credentials verification failed');
        throw new Error('Admin credentials verification failed');
      }
    } else {
      logger.info('ℹ️  Admin user already exists');
    }

    return true;
  } catch (error) {
    logger.error('❌ Admin user seed process failed:', error);
    throw error;
  }
}

/**
 * Export function for use in server startup
 */
module.exports = {
  seedAdminUser,
  createAdminUser,
  adminUserExists,
  verifyAdminCredentials,
  hashPassword
};

/**
 * Run as standalone script
 */
if (require.main === module) {
  seedAdminUser()
    .then(() => {
      logger.info('✅ Seed script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Seed script failed:', error);
      process.exit(1);
    });
}
