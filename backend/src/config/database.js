const { Sequelize } = require('sequelize');
require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

// Conditionally require pg module to avoid Vercel build issues
let pg;
try {
  pg = require('pg');
} catch (error) {
  console.warn('pg module not available, using dialectModule approach');
}

const sequelizeOptions = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 10,
    min: 0,
    acquire: 60000,
    idle: 10000,
    evict: 60000, // Evict connections that have been idle for 60 seconds
  },
  define: {
    timestamps: true,
    underscored: true, // Use snake_case for column names
    freezeTableName: true, // Don't pluralize table names
  },
  dialectOptions: {
    ssl: process.env.DB_SSL_REQUIRED === 'true' || process.env.DB_SSL_MODE === 'require' ? {
      require: true,
      rejectUnauthorized: false
    } : false,
  },
  retry: {
    max: 3, // Retry failed queries up to 3 times
    match: [
      /SequelizeConnectionError/,
      /Connection terminated/,
      /Connection refused/,
      /Connection lost/,
      /ETIMEDOUT/,
      /ECONNRESET/,
    ],
  },
};

// Add dialectModule if pg is available
if (pg) {
  sequelizeOptions.dialectModule = pg;
}

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  sequelizeOptions
);

// Test database connection
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ PostgreSQL connection established successfully.');
    
    // Log database info
    const [results] = await sequelize.query('SELECT version();');
    console.log(`📊 Database: ${process.env.DB_NAME}`);
    console.log(`🔗 Host: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
  } catch (error) {
    console.error('❌ Unable to connect to PostgreSQL database:', error.message);
    process.exit(1);
  }
};

module.exports = { sequelize, testConnection };