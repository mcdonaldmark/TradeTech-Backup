const express = require("express");
const router = express.Router();

const { login, registerUser } = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");
const { authorizeCreateRole } = require("../middleware/authorizeRoles");

/*
 * =========================
 * AUTH ROUTES
 * =========================
 */

// LOGIN
router.post("/login", login);

// REGISTER
router.post(
  "/register",
  authMiddleware,
  authorizeCreateRole(),
  registerUser
);

// TEST ROUTE
router.get("/test", (req, res) => {
  res.json({
    message: "Auth route working",
  });
});

module.exports = router;