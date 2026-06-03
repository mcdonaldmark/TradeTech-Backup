const express = require("express");
const cors = require("cors");
const os = require("os");
require("dotenv").config();

const pool = require("./config/db");
const bcrypt = require("bcrypt");

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const inventoryRoutes = require("./routes/inventoryRoutes");
const salesRoutes = require("./routes/salesRoutes");
const orderRoutes = require("./routes/orderRoutes");

const app = express();

console.log("SERVER VERSION: 2026-API-SEED-TEST");

// -------------------- MIDDLEWARE --------------------

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// -------------------- ROOT --------------------

app.get("/", (req, res) => {
  res.json({
    message: "API is running",
    status: "ok",
  });
});

// -------------------- SEED FUNCTION --------------------

const seedUsers = async () => {
  const password = await bcrypt.hash("Admin123!", 10);

  const users = [
    ["System Director", "director@tradetech.com", "director"],
    ["System Manager", "manager@tradetech.com", "manager"],
    ["System Cashier", "cashier@tradetech.com", "cashier"],
    ["System User", "user@tradetech.com", "user"],
  ];

  for (const u of users) {
    await pool.query(
      `INSERT INTO users (name, email, password, role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO NOTHING`,
      [u[0], u[1], password, u[2]]
    );
  }
};

// -------------------- INIT STARTUP --------------------

const init = async () => {
  try {
    console.log("Checking seed data...");
    await seedUsers();
    console.log("Seed check complete");
  } catch (err) {
    console.error("Seed error:", err.message);
  }
};

// -------------------- ROUTES --------------------

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/inventory", inventoryRoutes);
app.use("/api/sales", salesRoutes);
app.use("/api/orders", orderRoutes);

// -------------------- OPTIONAL MANUAL SEED --------------------

app.get("/api/seed", async (req, res) => {
  try {
    await seedUsers();
    res.json({ message: "Seed complete" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -------------------- 404 HANDLER --------------------

app.use((req, res) => {
  console.log(`Route not found: ${req.method} ${req.url}`);

  res.status(404).json({
    message: "Route not found",
  });
});

// -------------------- ERROR HANDLER --------------------

app.use((err, req, res, next) => {
  console.error("Server error:", err);

  res.status(500).json({
    message: "Internal server error",
  });
});

// -------------------- START SERVER --------------------

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", async () => {
  console.log("Server started");
  console.log("Local: http://localhost:" + PORT);
  console.log("Health check ready");

  await init();
});