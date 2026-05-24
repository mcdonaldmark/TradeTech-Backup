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

/*
 * CREATE SALE
 * cashier + manager + director
 */
router.post(
  "/",
  authMiddleware,
  authorizeRoles("cashier", "manager", "director"),
  createSale
);

/*
 * GET SALES
 * manager + director only
 */
router.get(
  "/",
  authMiddleware,
  authorizeRoles("manager", "director"),
  getSales
);

/*
 * PROFIT / LOSS
 */
router.get(
  "/profit-loss",
  authMiddleware,
  authorizeRoles("manager", "director"),
  getProfitLoss
);

/*
 * GET SALE BY ID
 */
router.get(
  "/:id",
  authMiddleware,
  authorizeRoles("manager", "director"),
  getSaleById
);

/*
 * DELETE SALE
 */
router.delete(
  "/:id",
  authMiddleware,
  authorizeRoles("manager", "director"),
  deleteSale
);

module.exports = router;