const db = require('../config/db');

/**
 * Create product
 */
const createProduct = async (name, price, quantity) => {
    const result = await db.query(
        `INSERT INTO products (name, price, quantity)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [name, price, quantity]
    );

    return result.rows[0];
};

/**
 * Get all products
 */
const getAllProducts = async () => {
    const result = await db.query(
        `SELECT * FROM products ORDER BY product_id DESC`
    );

    return result.rows;
};

/**
 * Get single product
 */
const getProductById = async (id) => {
    const result = await db.query(
        `SELECT * FROM products WHERE product_id = $1`,
        [id]
    );

    return result.rows[0];
};

/**
 * Update product
 */
const updateProduct = async (id, name, price, quantity) => {
    const result = await db.query(
        `UPDATE products
         SET name = $1, price = $2, quantity = $3
         WHERE product_id = $4
         RETURNING *`,
        [name, price, quantity, id]
    );

    return result.rows[0];
};

/**
 * Delete product
 */
const deleteProduct = async (id) => {
    await db.query(
        `DELETE FROM products WHERE product_id = $1`,
        [id]
    );
};

module.exports = {
    createProduct,
    getAllProducts,
    getProductById,
    updateProduct,
    deleteProduct
};