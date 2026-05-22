const express = require("express");
const router = express.Router();

const { login, registerUser } = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");
const { authorizeCreateRole } = require("../middleware/authorizeRoles");

// LOGIN
router.post("/login", login);

// REGISTER
router.post(
  "/register",
  authMiddleware,
  authorizeCreateRole(),
  registerUser
);
const express = require('express');

const router = express.Router();

// Test Route
router.get('/test', (req, res) => {
  res.json({
    message: 'Auth route working',
  });
});

module.exports = router;