const express = require("express");
const cors = require("cors");
require("dotenv").config();

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const inventoryRoutes = require("./routes/inventoryRoutes");
const salesRoutes = require("./routes/salesRoutes");

const app = express();

/*
 * =========================
 * MIDDLEWARE
 * =========================
 */
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/*
 * =========================
 * HEALTH CHECK
 * =========================
 */
app.get("/", (req, res) => {
  res.json({
    message: "TradeTech API is running",
    status: "OK",
  });
});

/*
 * =========================
 * ROUTES
 * =========================
 */
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/inventory", inventoryRoutes);
app.use("/api/sales", salesRoutes);

/*
 * =========================
 * 404 HANDLER
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