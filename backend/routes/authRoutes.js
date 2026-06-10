const express = require("express");
const router = express.Router();

const authController = require('../controllers/authController');

router.post('/register', authController.register);

router.post('/login', authController.login);

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