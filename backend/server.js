const express = require("express");
const cors = require("cors");
require("dotenv").config();

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const inventoryRoutes = require("./routes/inventoryRoutes");
const salesRoutes = require("./routes/salesRoutes");
const orderRoutes = require("./routes/orderRoutes");

const pool = require("./config/db");
const bcrypt = require("bcrypt");

const app = express();

console.log("SERVER STARTED");

app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));

app.use(express.json());

app.get("/", (req, res) => {
  res.json({ status: "ok", message: "API running" });
});

app.get("/api/seed", async (req, res) => {
  try {
    const password = await bcrypt.hash("Admin123!", 10);

    const users = [
      ["System Director", "director@tradetech.com", "director"],
      ["System Manager", "manager@tradetech.com", "manager"],
      ["System Cashier", "cashier@tradetech.com", "cashier"],
      ["System User", "user@tradetech.com", "user"],
    ];

    for (const u of users) {
      await pool.query(
        `INSERT INTO users (name,email,password,role)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (email) DO NOTHING`,
        [u[0], u[1], password, u[2]]
      );
    }

    res.json({ message: "Seed complete" });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ---------------- ROUTES ----------------
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/inventory", inventoryRoutes);
app.use("/api/sales", salesRoutes);
app.use("/api/orders", orderRoutes);

app.use((req, res) => {
  res.status(404).json({ message: "Route not found" });
});

// ---------------- START SERVER ----------------
const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log("Server running on port", PORT);
});