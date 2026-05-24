const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/authorizeRoles");

const {
  createOrder,
  getOrders,
  getOrderById,
  getMyOrders,
} = require("../controllers/orderController");

router.post(
  "/",
  authMiddleware,
  authorizeRoles("cashier", "user"),
  createOrder
);

router.get(
  "/",
  authMiddleware,
  authorizeRoles("cashier", "manager", "director"),
  getOrders
);

router.get(
  "/my",
  authMiddleware,
  authorizeRoles("user", "cashier", "manager", "director"),
  getMyOrders
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