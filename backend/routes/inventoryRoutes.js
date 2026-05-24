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
  USERS + CASHIERS SEE PRODUCTS
*/
router.get("/", authMiddleware,
  authorizeRoles("user","cashier","manager","director"),
  getProducts
);

/*
  ALL ROLES SEE PRODUCT DETAILS
*/
router.get("/:id", authMiddleware,
  authorizeRoles("user","cashier","manager","director"),
  getProductById
);

/*
  CASHIER+ SEE STOCK
*/
router.get("/check", authMiddleware,
  authorizeRoles("cashier","manager","director"),
  checkStock
);

/*
  ONLY MANAGER + DIRECTOR CAN MODIFY
*/
router.post("/", authMiddleware,
  authorizeRoles("manager","director"),
  createProduct
);

router.put("/:id", authMiddleware,
  authorizeRoles("manager","director"),
  updateProduct
);

router.delete("/:id", authMiddleware,
  authorizeRoles("manager","director"),
  deleteProduct
);

module.exports = router;