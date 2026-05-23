const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const bcrypt = require("bcrypt");
const authMiddleware = require("../middleware/authMiddleware");

// ROLE PERMISSIONS (what each role can CREATE)
const rolePermissions = {
    user: [],
    cashier: [],
    manager: ["user", "cashier"],
    director: ["user", "cashier", "manager", "director"]
};

const canCreateRole = (creatorRole, targetRole) => {
    return rolePermissions[creatorRole]?.includes(targetRole);
};

/*
 * =========================
 * CREATE USER
 * =========================
 * Only manager and director can create users
 */
router.post("/", authMiddleware, async (req, res) => {
    try {
        const creatorRole = req.user.role;

        if (creatorRole !== "manager" && creatorRole !== "director") {
            return res.status(403).json({ error: "Not authorized" });
        }

        const { name, email, password, role } = req.body;

        const allowedRoles = ["user", "cashier", "manager", "director"];

        if (!allowedRoles.includes(role)) {
            return res.status(400).json({ error: "Invalid role" });
        }

        if (!canCreateRole(creatorRole, role)) {
            return res.status(403).json({
                error: `Your role (${creatorRole}) cannot create ${role}`
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const result = await pool.query(
            "INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING id, name, email, role",
            [name, email, hashedPassword, role]
        );

        res.json(result.rows[0]);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/*
 * =========================
 * GET ALL USERS
 * =========================
 * Only manager and director can view users
 */
router.get("/", authMiddleware, async (req, res) => {
    try {
        const role = req.user.role;

        if (role !== "manager" && role !== "director") {
            return res.status(403).json({ error: "Not authorized" });
        }

        const result = await pool.query(
            "SELECT id, name, email, role, created_at FROM users ORDER BY id ASC"
        );

        res.json(result.rows);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/*
 * =========================
 * GET USER BY ID
 * =========================
 */
router.get("/:id", authMiddleware, async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT id, name, email, role, created_at FROM users WHERE id = $1",
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "User not found" });
        }

        res.json(result.rows[0]);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/*
 * =========================
 * UPDATE USER
 * =========================
 * Only manager and director can update users
 */
router.put("/:id", authMiddleware, async (req, res) => {
    try {
        const updaterRole = req.user.role;

        if (updaterRole !== "manager" && updaterRole !== "director") {
            return res.status(403).json({ error: "Not authorized" });
        }

        const { name, email, role } = req.body;

        if (!canCreateRole(updaterRole, role)) {
            return res.status(403).json({
                error: `Your role (${updaterRole}) cannot assign ${role}`
            });
        }

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
 * =========================
 * DELETE USER
 * =========================
 * Only director can delete users
 */
router.delete("/:id", authMiddleware, async (req, res) => {
    try {
        const role = req.user.role;

        if (role !== "director") {
            return res.status(403).json({ error: "Only director can delete users" });
        }

        await pool.query("DELETE FROM users WHERE id = $1", [req.params.id]);

        res.json({ message: "User deleted successfully" });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;