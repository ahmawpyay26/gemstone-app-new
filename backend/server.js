const express = require('express');
const cors = require('cors');
require('dotenv').config();

const logger = require('./config/logger');
const { initializeDatabase } = require('./scripts/initDatabase');
const { seedAdminUser } = require('./scripts/seedAdminUser');

const app = express();

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint (before database initialization)
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Gemstone Management API is running',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/gemstones', require('./routes/gemstone.routes'));
app.use('/api/lots', require('./routes/lot.routes'));
app.use('/api/expenses', require('./routes/expense.routes'));
app.use('/api/sales', require('./routes/sale.routes'));
app.use('/api/reports', require('./routes/report.routes'));
app.use('/api/audit', require('./routes/audit.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/export', require('./routes/export.routes'));

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(err.status || 500).json({
    status: 'error',
    message: err.message || 'Internal Server Error',
    code: err.code || 'INTERNAL_ERROR'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    message: 'Route not found',
    code: 'NOT_FOUND'
  });
});

const PORT = process.env.PORT || 3001;

/**
 * Wait for database to be ready with retries
 */
async function waitForDatabase(maxRetries = 10, delay = 5000) {
  const db = require('./config/database');
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      logger.info(`🔄 Checking database connection (attempt ${i + 1}/${maxRetries})...`);
      await db.authenticate();
      logger.info('✅ Database is ready');
      return true;
    } catch (error) {
      logger.warn(`⚠️  Database not ready yet: ${error.message}`);
      if (i < maxRetries - 1) {
        logger.info(`⏳ Waiting ${delay / 1000}s before retry...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  
  logger.error('❌ Database connection failed after all retries');
  return false;
}

/**
 * Start server with database initialization
 */
async function startServer() {
  try {
    logger.info('🚀 Starting Gemstone Management Backend Server...');
    logger.info(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.info(`🔌 Port: ${PORT}`);

    // Wait for database to be ready
    logger.info('⏳ Waiting for database connection...');
    const dbReady = await waitForDatabase();
    
    if (!dbReady) {
      logger.error('❌ Database connection failed. Server starting in limited mode.');
      // Continue anyway - health check will work, but data operations will fail
    } else {
      // Initialize database and create tables
      try {
        logger.info('🔨 Initializing database...');
        await initializeDatabase();
        logger.info('✅ Database tables initialized');
      } catch (error) {
        logger.warn('⚠️  Database initialization warning:', error.message);
        // Don't exit - server can still start
      }

      // Seed admin user
      try {
        logger.info('👤 Seeding admin user...');
        await seedAdminUser();
        logger.info('✅ Admin user seeded');
      } catch (error) {
        logger.warn('⚠️  Admin user seeding warning:', error.message);
        // Don't exit - server can still start
      }
    }

    // Start Express server
    app.listen(PORT, () => {
      logger.info(`✅ Server running on port ${PORT}`);
      logger.info(`🌐 API URL: http://localhost:${PORT}/api`);
      logger.info('');
      logger.info('🔐 Default Admin Credentials:');
      logger.info('   Email: admin@gemstone.com');
      logger.info('   Password: admin123');
      logger.info('   Role: Owner');
      logger.info('');
      logger.info('📊 Health Check: GET /api/health');
      logger.info('🔑 Login: POST /api/auth/login');
      logger.info('');
    });

  } catch (error) {
    logger.error('❌ Failed to start server:', error);
    // Still start the server for health checks
    app.listen(PORT, () => {
      logger.info(`✅ Server running on port ${PORT} (limited mode - database unavailable)`);
      logger.info('📊 Health Check: GET /api/health');
    });
  }
}

// Start server
startServer();
