const express = require("express");
const router = express.Router();

const pool = require("../config/db");
const bcrypt = require("bcrypt");
const authMiddleware = require("../middleware/authMiddleware");

const { login, registerUser } = require("../controllers/authController");

// LOGIN
router.post("/login", login);

// REGISTER
router.post("/register", registerUser);

const rolePermissions = {
  user: ["user"],
  cashier: ["user"],
  manager: ["user", "cashier"],
  director: ["user", "cashier", "manager", "director"],
};

const canCreateRole = (creatorRole, targetRole) => {
  return rolePermissions[creatorRole]?.includes(targetRole);
};

/*
 * CREATE USER
 */
router.post("/", authMiddleware, async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    const creatorRole = req.user.role;

    const allowedRoles = ["user", "cashier", "manager", "director"];

    if (!allowedRoles.includes(role)) {
      return res.status(400).json({ error: "Invalid role" });
    }

    if (!canCreateRole(creatorRole, role)) {
      return res.status(403).json({
        error: `Your role (${creatorRole}) cannot create a ${role} account`,
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      "INSERT INTO users (name, email, password, role) VALUES ($1,$2,$3,$4) RETURNING id, name, email, role",
      [name, email, hashedPassword, role]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * GET ALL USERS
 */
router.get("/", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, email, role, created_at FROM users ORDER BY id ASC"
    );

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * UPDATE USER
 */
router.put("/:id", authMiddleware, async (req, res) => {
  try {
    const { name, email, role } = req.body;

    const result = await pool.query(
      "UPDATE users SET name=$1, email=$2, role=$3 WHERE id=$4 RETURNING id, name, email, role",
      [name, email, role, req.params.id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * DELETE USER
 */
router.delete("/:id", authMiddleware, async (req, res) => {
  try {
    await pool.query("DELETE FROM users WHERE id=$1", [req.params.id]);
    res.json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/login", (req, res, next) => {
  console.log("LOGIN HIT:", req.body);
  next();
}, login);

module.exports = router;