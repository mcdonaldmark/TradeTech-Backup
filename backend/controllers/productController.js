const productModel = require('../models/products');

/**
 * CREATE PRODUCT
 */
const createProduct = async (req, res) => {
    try {

        console.log("📦 HEADERS:", req.headers);
        console.log("📦 BODY:", req.body);

        // Prevent crash if body is missing
        const { name, price, quantity } = req.body || {};

        // Validation
        if (!name || !price || quantity === undefined) {
            return res.status(400).json({
                message: 'All fields are required',
                receivedBody: req.body
            });
        }

        const product = await productModel.createProduct(
            name,
            price,
            quantity
        );

        res.status(201).json({
            message: 'Product created successfully',
            product
        });

    } catch (err) {

        console.log("🔥 CREATE PRODUCT ERROR:", err);

        res.status(500).json({
            message: 'Server error',
            error: err.message,
            stack: err.stack
        });
    }
};

/**
 * GET ALL PRODUCTS
 */
const getAllProducts = async (req, res) => {
    try {
        const products = await productModel.getAllProducts();

        res.json(products);

    } catch (err) {
        console.log("🔥 GET ALL PRODUCTS ERROR:", err);

        res.status(500).json({
            message: 'Server error',
            error: err.message,
            stack: err.stack
        });
    }
};

/**
 * GET SINGLE PRODUCT
 */
const getProductById = async (req, res) => {
    try {
        const product = await productModel.getProductById(req.params.id);

        if (!product) {
            return res.status(404).json({
                message: 'Product not found'
            });
        }

        res.json(product);

    } catch (err) {
        console.log("🔥 GET PRODUCT ERROR:", err);

        res.status(500).json({
            message: 'Server error',
            error: err.message,
            stack: err.stack
        });
    }
};

/**
 * UPDATE PRODUCT
 */
const updateProduct = async (req, res) => {
    try {
        const { name, price, quantity } = req.body;

        const product = await productModel.updateProduct(
            req.params.id,
            name,
            price,
            quantity
        );

        res.json({
            message: 'Product updated successfully',
            product
        });

    } catch (err) {
        console.log("🔥 UPDATE PRODUCT ERROR:", err);

        res.status(500).json({
            message: 'Server error',
            error: err.message,
            stack: err.stack
        });
    }
};

/**
 * DELETE PRODUCT
 */
const deleteProduct = async (req, res) => {
    try {
        await productModel.deleteProduct(req.params.id);

        res.json({
            message: 'Product deleted successfully'
        });

    } catch (err) {
        console.log("🔥 DELETE PRODUCT ERROR:", err);

        res.status(500).json({
            message: 'Server error',
            error: err.message,
            stack: err.stack
        });
    }
};

module.exports = {
    createProduct,
    getAllProducts,
    getProductById,
    updateProduct,
    deleteProduct
};