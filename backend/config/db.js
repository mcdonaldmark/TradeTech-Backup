const { Pool } = require('pg');

const pool = new Pool({
  user: 'tradetech_user',
  host: 'localhost',
  database: 'tradetech_db',
  password: 'admin123',
  port: 5432,
});

pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL error:', err);
});

module.exports = pool;