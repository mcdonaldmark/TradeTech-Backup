const express = require("express");
const router = express.Router();

const {
    getProducts,
    getProductById,
    createProduct,
    updateProduct,
    deleteProduct,
    checkStock
} = require("../controllers/inventoryController");

const authMiddleware = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/authorizeRoles");

/*
 * USER: ONLY STOCK CHECK
 */
router.get(
    "/check",
    authMiddleware,
    authorizeRoles("user"),
    checkStock
);

/*
 * CASHIER + MANAGER + DIRECTOR: VIEW INVENTORY
 */
router.get(
    "/",
    authMiddleware,
    authorizeRoles("cashier", "manager", "director"),
    getProducts
);

router.get(
    "/:id",
    authMiddleware,
    authorizeRoles("cashier", "manager", "director"),
    getProductById
);

/*
 * MANAGER + DIRECTOR: MANAGE INVENTORY
 */
router.post(
    "/",
    authMiddleware,
    authorizeRoles("manager", "director"),
    createProduct
);

router.put(
    "/:id",
    authMiddleware,
    authorizeRoles("manager", "director"),
    updateProduct
);

/*
 * DIRECTOR ONLY: DELETE INVENTORY
 */
router.delete(
    "/:id",
    authMiddleware,
    authorizeRoles("manager", "director"),
    deleteProduct
);

module.exports = router;