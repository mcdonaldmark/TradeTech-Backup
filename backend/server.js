require('dotenv').config();

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const productRoutes = require('./routes/productRoutes');

const pool = require('./config/db');

const app = express();

/**
 * Middleware
 */
app.use(cors());
app.use(express.json());

/**
 * PostgreSQL Connection Test
 */
async function testDB() {
  try {
    const result = await pool.query('SELECT NOW()');

    console.log('✅ PostgreSQL Connected');
    console.log(result.rows[0]);

  } catch (err) {
    console.error('❌ PostgreSQL Connection Failed');
    console.error(err);
  }
}

testDB();

/**
 * Routes
 */
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);

/**
 * Test Route (TEMPORARY DEBUG)
 */
app.post('/test-body', (req, res) => {

  console.log('📦 BODY:', req.body);

  res.json({
    received: req.body
  });
});

/**
 * Default Route
 */
app.get('/', (req, res) => {
  res.send('TradeTech API Running Successfully');
});

/**
 * Server
 */
const PORT = process.env.PORT || 8000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});