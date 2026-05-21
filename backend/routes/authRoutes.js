const express = require('express');

const router = express.Router();

// Test Route
router.get('/test', (req, res) => {
  res.json({
    message: 'Auth route working',
  });
});

module.exports = router;