const pool = require("../config/db");

/*
 * CREATE SALE
 */
exports.createSale = async (req, res) => {
  try {
    const { product_id, product_name, quantity_sold } = req.body;
    const user_id = req.user.id;

    let product = null;

    // 1. Try to find product
    if (product_id) {
      const result = await pool.query(
        "SELECT * FROM inventory WHERE id = $1",
        [product_id]
      );
      product = result.rows[0] || null;

    } else if (product_name) {
      const result = await pool.query(
        "SELECT * FROM inventory WHERE LOWER(name) = LOWER($1)",
        [product_name]
      );
      product = result.rows[0] || null;
    }

    // 2. Validate quantity early
    if (!quantity_sold || quantity_sold <= 0) {
      return res.status(400).json({ message: "Invalid quantity" });
    }

    // 3. SAFE PRODUCT NAME (CRITICAL FIX)
    const safeProductName = String(
      product?.name ||
      product_name ||
      "Deleted Product"
    );

    const productId = product?.id ?? null;

    const unit_price = Number(product?.price ?? 0);
    const cost_price = Number(product?.cost_price ?? 0);

    // 4. Only check stock if product exists
    if (product && product.quantity < quantity_sold) {
      return res.status(400).json({ message: "Insufficient stock" });
    }

    const total_revenue = unit_price * quantity_sold;
    const total_cost = cost_price * quantity_sold;
    const profit = total_revenue - total_cost;

    // 5. INSERT SALE (NEVER NULL product_name)
    const sale = await pool.query(
      `INSERT INTO sales (
        product_id,
        product_name,
        quantity_sold,
        unit_price,
        total_revenue,
        cost_price,
        total_cost,
        profit,
        sold_by
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      RETURNING *`,
      [
        productId,
        safeProductName,
        Number(quantity_sold),
        unit_price,
        total_revenue,
        cost_price,
        total_cost,
        profit,
        user_id
      ]
    );

    // 6. Reduce stock only if product exists
    if (productId) {
      await pool.query(
        "UPDATE inventory SET quantity = quantity - $1 WHERE id = $2",
        [quantity_sold, productId]
      );
    }

    return res.status(201).json({
      message: "Sale recorded successfully",
      sale: sale.rows[0]
    });

  } catch (err) {
    console.error("CREATE SALE ERROR:", err);
    return res.status(500).json({ error: err.message });
  }
};


/*
 * GET SALES
 */
exports.getSales = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        s.id,
        COALESCE(s.product_name, 'Deleted Product') AS product_name,
        s.quantity_sold,
        s.unit_price,
        s.total_revenue,
        s.total_cost,
        s.profit,
        s.created_at
      FROM sales s
      ORDER BY s.created_at DESC
    `);

    res.json(result.rows);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


/*
 * GET PROFIT / LOSS
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
    const result = await pool.query(`
      SELECT
        s.id,
        COALESCE(s.product_name, 'Deleted Product') AS product_name,
        s.quantity_sold,
        s.unit_price,
        s.total_revenue,
        s.total_cost,
        s.profit,
        s.created_at
      FROM sales s
      WHERE s.id = $1
    `, [req.params.id]);

    if (!result.rows[0]) {
      return res.status(404).json({ message: "Sale not found" });
    }

    res.json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


/*
 * DELETE SALE
 */
exports.deleteSale = async (req, res) => {
  try {
    await pool.query("DELETE FROM sales WHERE id = $1", [req.params.id]);

    res.json({ message: "Sale deleted successfully" });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};