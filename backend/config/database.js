const { Sequelize } = require('sequelize');
require('dotenv').config();

let sequelize;

// Log environment for debugging
console.log('🔍 Database Configuration Debug:');
console.log(`   NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`   DATABASE_URL present: ${!!process.env.DATABASE_URL}`);
console.log(`   DB_HOST: ${process.env.DB_HOST || 'not set'}`);
console.log(`   DB_PORT: ${process.env.DB_PORT || 'not set'}`);
console.log(`   DB_NAME: ${process.env.DB_NAME || 'not set'}`);
console.log(`   DB_USER: ${process.env.DB_USER || 'not set'}`);

if (process.env.DATABASE_URL) {
  // Use Render's DATABASE_URL (production)
  console.log('📌 Connecting using DATABASE_URL...');
  sequelize = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    }
  });
} else {
  // Fallback to individual environment variables (development)
  console.log('📌 Connecting using individual environment variables...');
  sequelize = new Sequelize(
    process.env.DB_NAME || 'gemstone_db',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASSWORD || 'postgres',
    {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      dialect: 'postgres',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
      },
      dialectOptions: {
        ssl: process.env.DB_SSL === 'true' ? {
          require: true,
          rejectUnauthorized: false
        } : false
      }
    }
  );
}

// Test database connection with retry logic
const testConnection = async (retries = 5, delay = 3000) => {
  for (let i = 0; i < retries; i++) {
    try {
      console.log(`🔄 Database connection attempt ${i + 1}/${retries}...`);
      await sequelize.authenticate();
      console.log('✅ Database connection established successfully');
      return true;
    } catch (err) {
      console.error(`❌ Database connection attempt ${i + 1}/${retries} failed:`, err.message);
      if (i < retries - 1) {
        console.log(`⏳ Retrying in ${delay / 1000} seconds...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  console.error('❌ Unable to connect to the database after all retries');
  return false;
};

// Don't wait for connection test, let it run in background
testConnection();

module.exports = sequelize;
