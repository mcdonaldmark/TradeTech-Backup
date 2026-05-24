const express = require("express");
const router = express.Router();

const {
  createSale,
  getSales,
  getProfitLoss,
  getSaleById,
  deleteSale
} = require("../controllers/salesController");

const authMiddleware = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/authorizeRoles");

router.post(
  "/",
  authMiddleware,
  authorizeRoles("cashier", "manager", "director"),
  createSale
);

router.get(
  "/",
  authMiddleware,
  authorizeRoles("manager", "director"),
  getSales
);

router.get(
  "/profit-loss",
  authMiddleware,
  authorizeRoles("manager", "director"),
  getProfitLoss
);

router.get(
  "/:id",
  authMiddleware,
  authorizeRoles("manager", "director"),
  getSaleById
);

router.delete(
  "/:id",
  authMiddleware,
  authorizeRoles("manager", "director"),
  deleteSale
);

module.exports = router;