const express = require("express");
const cors = require("cors");

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const inventoryRoutes = require("./routes/inventoryRoutes");
const salesRoutes = require("./routes/salesRoutes"); // ✅ ADDED

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  res.json({
    message: "TradeTech API is running",
    status: "OK"
  });
});

/*
 * =========================
 * ROUTES
 * =========================
 */

// Auth routes
app.use("/api/auth", authRoutes);

// User routes
app.use("/api/users", userRoutes);

// Inventory routes
app.use("/api/inventory", inventoryRoutes);

// SALES routes
app.use("/api/sales", salesRoutes);

/*
 * =========================
 * ERROR HANDLING
 * =========================
 */
app.use((req, res) => {
  res.status(404).json({ message: "Route not found" });
});

/*
 * =========================
 * START SERVER
 * =========================
 */
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});