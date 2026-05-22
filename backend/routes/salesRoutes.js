const express = require("express");
const router = express.Router();

const {
    createSale,
    getSales,
    getProfitLoss,
    getSaleById   // ✅ ADD THIS (THIS WAS MISSING)
} = require("../controllers/salesController");

const authMiddleware = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/authorizeRoles");

/*
 * CREATE SALE → CASHIER + MANAGER + DIRECTOR
 */
router.post(
    "/",
    authMiddleware,
    authorizeRoles("cashier", "manager", "director"),
    createSale
);

/*
 * VIEW SALES → CASHIER + MANAGER + DIRECTOR
 */
router.get(
    "/",
    authMiddleware,
    authorizeRoles("cashier", "manager", "director"),
    getSales
);

/*
 * PROFIT / LOSS → MANAGER + DIRECTOR ONLY
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
    authorizeRoles("cashier", "manager", "director"),
    getSaleById
);

module.exports = router;