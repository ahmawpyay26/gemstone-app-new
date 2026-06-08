/**
 * Server Startup Example
 * 
 * This shows how to integrate the initialization module into your server startup.
 * Add this code to your main server file (e.g., server.js or index.ts)
 */

const express = require('express');
const logger = require('./config/logger');
const { initializeApp, healthCheck } = require('./utils/initializeApp');

const app = express();
const PORT = process.env.PORT || 3001;

/**
 * EXAMPLE 1: Using async/await with error handling
 */
async function startServerWithInitialization() {
  try {
    logger.info('🚀 Starting Gemstone Management Backend Server...');

    // Initialize application
    const initStatus = await initializeApp();
    
    if (!initStatus.databaseConnected) {
      throw new Error('Failed to connect to database');
    }

    // Setup Express middleware
    app.use(express.json());
    app.use(express.urlencoded({ extended: true }));

    // Setup routes
    app.use('/api/auth', require('./routes/auth.routes'));
    app.use('/api/gemstones', require('./routes/gemstone.routes'));
    app.use('/api/sales', require('./routes/sale.routes'));
    app.use('/api/expenses', require('./routes/expense.routes'));
    app.use('/api/audit', require('./routes/audit.routes'));
    app.use('/api/notifications', require('./routes/notification.routes'));

    // Health check endpoint
    app.get('/health', async (req, res) => {
      const health = await healthCheck();
      res.status(health.status === 'healthy' ? 200 : 503).json(health);
    });

    // Start server
    app.listen(PORT, () => {
      logger.info(`✅ Server running on port ${PORT}`);
      logger.info(`📊 Health check: http://localhost:${PORT}/health`);
      logger.info('');
      logger.info('🔐 Default Admin Credentials:');
      logger.info('   Email: admin@gemstone.com');
      logger.info('   Password: admin123');
      logger.info('   Role: Owner');
      logger.info('');
    });

  } catch (error) {
    logger.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

/**
 * EXAMPLE 2: Using .then() and .catch()
 */
function startServerWithInitializationPromise() {
  logger.info('🚀 Starting Gemstone Management Backend Server...');

  initializeApp()
    .then((initStatus) => {
      if (!initStatus.databaseConnected) {
        throw new Error('Failed to connect to database');
      }

      // Setup Express middleware
      app.use(express.json());
      app.use(express.urlencoded({ extended: true }));

      // Setup routes
      app.use('/api/auth', require('./routes/auth.routes'));
      app.use('/api/gemstones', require('./routes/gemstone.routes'));
      app.use('/api/sales', require('./routes/sale.routes'));
      app.use('/api/expenses', require('./routes/expense.routes'));

      // Health check endpoint
      app.get('/health', async (req, res) => {
        const health = await healthCheck();
        res.status(health.status === 'healthy' ? 200 : 503).json(health);
      });

      // Start server
      app.listen(PORT, () => {
        logger.info(`✅ Server running on port ${PORT}`);
        logger.info(`📊 Health check: http://localhost:${PORT}/health`);
        logger.info('');
        logger.info('🔐 Default Admin Credentials:');
        logger.info('   Email: admin@gemstone.com');
        logger.info('   Password: admin123');
        logger.info('   Role: Owner');
        logger.info('');
      });
    })
    .catch((error) => {
      logger.error('❌ Failed to start server:', error);
      process.exit(1);
    });
}

/**
 * EXAMPLE 3: In your actual server.js file
 * 
 * Replace your existing server startup code with:
 */

// ============================================
// ACTUAL IMPLEMENTATION (Add to server.js)
// ============================================

/*
const express = require('express');
const logger = require('./config/logger');
const { initializeApp, healthCheck } = require('./utils/initializeApp');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/gemstones', require('./routes/gemstone.routes'));
app.use('/api/sales', require('./routes/sale.routes'));
app.use('/api/expenses', require('./routes/expense.routes'));
app.use('/api/audit', require('./routes/audit.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));

// Health check
app.get('/health', async (req, res) => {
  const health = await healthCheck();
  res.status(health.status === 'healthy' ? 200 : 503).json(health);
});

// Initialize and start
async function start() {
  try {
    await initializeApp();
    
    app.listen(PORT, () => {
      logger.info(`✅ Server running on port ${PORT}`);
      logger.info('🔐 Admin: admin@gemstone.com / admin123');
    });
  } catch (error) {
    logger.error('❌ Failed to start:', error);
    process.exit(1);
  }
}

start();
*/

// Export for testing
module.exports = {
  startServerWithInitialization,
  startServerWithInitializationPromise
};
