const pool = require("../config/db");

/*
 * CREATE ORDER (cashier only)
 */
exports.createOrder = async (req, res) => {
  try {
    const { user_id, items } = req.body;

    const created_by = req.user.id || req.user.userId;

    if (!items || items.length === 0) {
      return res.status(400).json({ message: "No items in order" });
    }

    let total = 0;

    const orderResult = await pool.query(
      `INSERT INTO orders (user_id, created_by, total)
       VALUES ($1,$2,$3)
       RETURNING *`,
      [user_id, created_by, 0]
    );

    const order = orderResult.rows[0];

    for (const item of items) {
      const productRes = await pool.query(
        "SELECT * FROM inventory WHERE id=$1",
        [item.product_id]
      );

      const product = productRes.rows[0];
      if (!product) continue;

      const subtotal = product.price * item.quantity;
      total += subtotal;

      await pool.query(
        `INSERT INTO order_items 
        (order_id, product_id, quantity, price, subtotal)
        VALUES ($1,$2,$3,$4,$5)`,
        [
          order.id,
          product.id,
          item.quantity,
          product.price,
          subtotal,
        ]
      );

      await pool.query(
        `UPDATE inventory SET quantity = quantity - $1 WHERE id=$2`,
        [item.quantity, product.id]
      );

      await pool.query(
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
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [
          product.id,
          item.quantity,
          product.price,
          subtotal,
          product.cost_price || 0,
          (product.cost_price || 0) * item.quantity,
          subtotal - (product.cost_price || 0) * item.quantity,
          created_by,
        ]
      );
    }

    await pool.query(
      `UPDATE orders SET total=$1 WHERE id=$2`,
      [total, order.id]
    );

    res.status(201).json({
      message: "Order created successfully",
      order_id: order.id,
      total,
    });

  } catch (err) {
    console.error("CREATE ORDER ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};


/*
 * GET ORDERS (role-based)
 */
exports.getOrders = async (req, res) => {
  try {
    const role = req.user.role;
    const userId = req.user.id || req.user.userId;

    let result;

    if (role === "cashier") {
      result = await pool.query(
        `SELECT * FROM orders 
         WHERE created_by=$1 
         ORDER BY created_at DESC`,
        [userId]
      );
    } else {
      result = await pool.query(
        `SELECT * FROM orders ORDER BY created_at DESC`
      );
    }

    res.json(result.rows);

  } catch (err) {
    console.error("GET ORDERS ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};


/*
 * GET ORDER DETAILS
 */
exports.getOrderById = async (req, res) => {
  try {
    const orderRes = await pool.query(
      `SELECT o.*, u.name AS user_name
       FROM orders o
       LEFT JOIN users u ON o.user_id = u.id
       WHERE o.id=$1`,
      [req.params.id]
    );

    if (!orderRes.rows[0]) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orderRes.rows[0];

    const itemsRes = await pool.query(
      `SELECT 
          oi.product_id,
          COALESCE(i.name, 'Unknown Product') AS name,
          oi.quantity,
          oi.price,
          oi.subtotal
       FROM order_items oi
       LEFT JOIN inventory i ON oi.product_id = i.id
       WHERE oi.order_id=$1`,
      [req.params.id]
    );

    const items = itemsRes.rows;

    const subtotal = items.reduce((sum, i) => sum + Number(i.subtotal), 0);

    const taxRate = 0.07;
    const tax = subtotal * taxRate;
    const total = Number((subtotal + tax).toFixed(2));10;

    res.json({
      order: {
        id: order.id,
        customer: order.user_name,
        created_at: order.created_at,
        status: order.status,   // ✅ FIXED: THIS WAS MISSING
      },
      items,
      summary: {
        subtotal,
        tax,
        total,
        tax_rate: taxRate,
      },
    });

  } catch (err) {
    console.error("GET ORDER ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};