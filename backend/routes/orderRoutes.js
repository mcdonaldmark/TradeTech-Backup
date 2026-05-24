const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/authorizeRoles");

const {
  createOrder,
  getOrders,
  getOrderById,
} = require("../controllers/orderController");

/*
 * CASHIER CREATES ORDER
 */
router.post(
  "/",
  authMiddleware,
  authorizeRoles("cashier"),
  createOrder
);

/*
 * VIEW ORDERS
 */
router.get(
  "/",
  authMiddleware,
  authorizeRoles("cashier", "manager", "director"),
  getOrders
);

/*
 * ORDER DETAILS
 */
router.get(
  "/:id",
  authMiddleware,
  authorizeRoles("cashier", "manager", "director"),
  getOrderById
);

module.exports = router;