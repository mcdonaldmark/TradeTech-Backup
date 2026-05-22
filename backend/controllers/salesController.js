const pool = require("../config/db");

/**
 * CASHIER: CREATE SALE
 * Bproduct_id or product_name can be used
 */
exports.createSale = async (req, res) => {
    try {
        const { product_id, product_name, quantity_sold } = req.body;
        const user_id = req.user.id;

        let product;

        /*
         * =========================
         * 1. FIND PRODUCT (ID OR NAME)
         * =========================
         */
        if (product_id) {
            const result = await pool.query(
                "SELECT * FROM inventory WHERE id = $1",
                [product_id]
            );
            product = result.rows[0];

        } else if (product_name) {
            const result = await pool.query(
                "SELECT * FROM inventory WHERE LOWER(name) = LOWER($1)",
                [product_name]
            );
            product = result.rows[0];

        } else {
            return res.status(400).json({
                message: "Provide product_id or product_name"
            });
        }

        /*
         * =========================
         * 2. VALIDATE PRODUCT
         * =========================
         */
        if (!product) {
            return res.status(404).json({ message: "Product not found" });
        }

        /*
         * =========================
         * 3. CHECK STOCK
         * =========================
         */
        if (!quantity_sold || quantity_sold <= 0) {
            return res.status(400).json({
                message: "Invalid quantity"
            });
        }

        if (product.quantity < quantity_sold) {
            return res.status(400).json({
                message: "Insufficient stock"
            });
        }

        /*
         * =========================
         * 4. CALCULATIONS
         * =========================
         */
        const unit_price = product.price;
        const cost_price = product.cost_price || 0;

        const total_revenue = unit_price * quantity_sold;
        const total_cost = cost_price * quantity_sold;
        const profit = total_revenue - total_cost;

        /*
         * =========================
         * 5. INSERT SALE RECORD
         * =========================
         */
        const sale = await pool.query(
            `INSERT INTO sales (
                product_id,
                quantity_sold,
                unit_price,
                total_revenue,
                cost_price,
                total_cost,
                profit,
                sold_by
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *`,
            [
                product.id,
                quantity_sold,
                unit_price,
                total_revenue,
                cost_price,
                total_cost,
                profit,
                user_id
            ]
        );

        /*
         * =========================
         * 6. UPDATE INVENTORY
         * =========================
         */
        await pool.query(
            `UPDATE inventory
             SET quantity = quantity - $1
             WHERE id = $2`,
            [quantity_sold, product.id]
        );

        res.status(201).json({
            message: "Sale recorded successfully",
            sale: sale.rows[0]
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

/*
 * MANAGER + DIRECTOR: VIEW SALES + INVENTORY IMPACT
 */
exports.getSales = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                s.id,
                p.name AS product_name,
                s.quantity_sold,
                s.unit_price,
                s.total_revenue,
                s.total_cost,
                s.profit,
                p.quantity AS remaining_stock,
                s.created_at
            FROM sales s
            JOIN inventory p ON s.product_id = p.id
            ORDER BY s.created_at DESC
        `);

        res.json(result.rows);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

/*
 * DIRECTOR: PROFIT / LOSS SUMMARY
 */
exports.getProfitLoss = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                COALESCE(SUM(total_revenue), 0) AS revenue,
                COALESCE(SUM(total_cost), 0) AS cost,
                COALESCE(SUM(profit), 0) AS profit
            FROM sales
        `);

        res.json(result.rows[0]);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

/*
 * GET SALE BY ID
 */
exports.getSaleById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(`
            SELECT 
                s.id,
                p.name AS product_name,
                s.quantity_sold,
                s.unit_price,
                s.total_revenue,
                s.total_cost,
                s.profit,
                s.created_at,
                p.quantity AS remaining_stock
            FROM sales s
            JOIN inventory p ON s.product_id = p.id
            WHERE s.id = $1
        `, [id]);

        const sale = result.rows[0];

        if (!sale) {
            return res.status(404).json({
                message: "Sale not found"
            });
        }

        res.json(sale);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};