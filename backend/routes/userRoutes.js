const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const bcrypt = require("bcrypt");
const authMiddleware = require("../middleware/authMiddleware");

router.use(authMiddleware);

const roleRank = {
  user: 1,
  cashier: 2,
  manager: 3,
  director: 4,
};

/*
 * =========================
 * ROLE FILTER PER USER
 * =========================
 */
const getAllowedRolesForViewer = (role) => {
  if (role === "director") return ["user", "cashier", "manager", "director"];
  if (role === "manager") return ["user", "cashier"]; // ❌ hides manager + director
  if (role === "cashier") return ["user"]; // ❌ only users visible
  return ["user"];
};

/*
 * =========================
 * CREATE USER (STRICT RULES)
 * =========================
 */
router.post("/", async (req, res) => {
  try {
    const { name, email, password, role = "user" } = req.body;

    const creatorRole = req.user.role;

    const allowedRolesToCreate = {
      director: ["user", "cashier", "manager", "director"],
      manager: ["user", "cashier"], // ❌ cannot create manager/director
      cashier: ["user"], // ❌ only users
      user: [],
    };

    if (!allowedRolesToCreate[creatorRole]?.includes(role)) {
      return res.status(403).json({
        message: `${creatorRole} cannot create ${role} accounts`,
      });
    }

    const hash = await bcrypt.hash(password, 10);

    const result = await pool.query(
      "INSERT INTO users(name,email,password,role) VALUES ($1,$2,$3,$4) RETURNING id,name,email,role",
      [name, email, hash, role]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * =========================
 * GET USERS (FILTERED)
 * =========================
 */
router.get("/", async (req, res) => {
  try {
    const viewerRole = req.user.role;
    const allowedRoles = getAllowedRolesForViewer(viewerRole);

    const result = await pool.query(
      `SELECT id,name,email,role,created_at 
       FROM users 
       WHERE role = ANY($1)
       ORDER BY id ASC`,
      [allowedRoles]
    );

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * =========================
 * UPDATE USER (STRICT RULES)
 * =========================
 */
router.put("/:id", async (req, res) => {
  try {
    const viewerRole = req.user.role;

    const { name, email, role } = req.body;

    // 🚨 cashier restrictions
    if (viewerRole === "cashier" && role !== "user") {
      return res.status(403).json({
        message: "Cashier can only manage user accounts",
      });
    }

    // 🚨 manager restrictions
    if (viewerRole === "manager" && ["manager", "director"].includes(role)) {
      return res.status(403).json({
        message: "Manager cannot modify manager/director accounts",
      });
    }

    const result = await pool.query(
      "UPDATE users SET name=$1,email=$2,role=$3 WHERE id=$4 RETURNING id,name,email,role",
      [name, email, role, req.params.id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * =========================
 * DELETE USER (STRICT RULES)
 * =========================
 */
router.delete("/:id", async (req, res) => {
  try {
    const viewerRole = req.user.role;

    const userResult = await pool.query(
      "SELECT role FROM users WHERE id=$1",
      [req.params.id]
    );

    const targetRole = userResult.rows[0]?.role;

    if (!targetRole) {
      return res.status(404).json({ message: "User not found" });
    }

    if (viewerRole === "cashier" && targetRole !== "user") {
      return res.status(403).json({
        message: "Cashier can only delete user accounts",
      });
    }

    if (
      viewerRole === "manager" &&
      ["manager", "director"].includes(targetRole)
    ) {
      return res.status(403).json({
        message: "Manager cannot delete manager/director accounts",
      });
    }

    await pool.query("DELETE FROM users WHERE id=$1", [req.params.id]);

    res.json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;