const pool = require("../config/db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const roleHierarchy = {
  user: 1,
  cashier: 2,
  manager: 3,
  director: 4
};

const canCreateRole = (creatorRole, targetRole) => {
  // only director can create manager/director
  if (targetRole === "director") return creatorRole === "director";
  if (targetRole === "manager") return ["manager", "director"].includes(creatorRole);
  if (targetRole === "cashier") return ["manager", "director"].includes(creatorRole);
  return true; // user
};

/*
 * LOGIN
 */
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    const user = result.rows[0];

    if (!user) return res.status(401).json({ message: "Invalid credentials" });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ message: "Invalid credentials" });

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.json({
      token,
      user: { id: user.id, role: user.role }
    });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

/*
 * REGISTER USER
 */
const registerUser = async (req, res) => {
  try {
    const { name, email, password, role = "user" } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const allowedRoles = ["user", "cashier", "manager", "director"];
    if (!allowedRoles.includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const creatorRole = req.user?.role;

    if (creatorRole && !canCreateRole(creatorRole, role)) {
      return res.status(403).json({
        message: `Your role (${creatorRole}) cannot create ${role}`
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await pool.query(
      "INSERT INTO users (name, email, password, role) VALUES ($1,$2,$3,$4)",
      [name, email, hashedPassword, role]
    );

    res.status(201).json({ message: "User created successfully" });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = { login, registerUser };