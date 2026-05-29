const express = require('express');
const router = express.Router();

const productController = require('../controllers/productController');

const authMiddleware = require('../middleware/authMiddleware');

/*** Routes*/
router.post('/', productController.createProduct);
router.get('/', productController.getAllProducts);
router.get('/:id', productController.getProductById);
router.put('/:id', productController.updateProduct);
router.delete('/:id', productController.deleteProduct);


router.post('/', authMiddleware, productController.createProduct);

router.get('/', authMiddleware, productController.getAllProducts);

router.get('/:id', authMiddleware, productController.getProductById);

router.put('/:id', authMiddleware, productController.updateProduct);

router.delete('/:id', authMiddleware, productController.deleteProduct);

module.exports = router;