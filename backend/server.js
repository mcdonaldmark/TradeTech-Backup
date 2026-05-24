const express = require("express");
const cors = require("cors");
const os = require("os");
require("dotenv").config();

const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");
const inventoryRoutes = require("./routes/inventoryRoutes");
const salesRoutes = require("./routes/salesRoutes");
const orderRoutes = require("./routes/orderRoutes");

const app = express();

/*
 * GET LOCAL IP
 */
const getLocalIP = () => {
  const nets = os.networkInterfaces();

  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === "IPv4" && !net.internal) {
        return net.address;
      }
    }
  }
  return "localhost";
};

const LOCAL_IP = getLocalIP();

/*
 * CORS
 */
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

/*
 * BODY PARSERS
 */
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

/*
 * DEBUG LOGGER (VERY IMPORTANT)
 * Helps you see wrong routes instantly
 */
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

/*
 * HEALTH CHECK
 */
app.get("/", (req, res) => {
  res.json({
    message: "API is running",
    status: "ok",
  });
});

/*
 * ROUTES
 */
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/inventory", inventoryRoutes);
app.use("/api/sales", salesRoutes);
app.use("/api/orders", orderRoutes);

/*
 * 404 HANDLER
 */
app.use((req, res) => {
  console.log(`Route not found: ${req.method} ${req.url}`);

  res.status(404).json({
    message: "Route not found",
  });
});

/*
 * ERROR HANDLER
 */
app.use((err, req, res, next) => {
  console.error("Server error:", err);

  res.status(500).json({
    message: "Internal server error",
  });
});

/*
 * START SERVER
 */
const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log("Server started");
  console.log("Local: http://localhost:" + PORT);
  console.log("Network: http://" + LOCAL_IP + ":" + PORT);
});