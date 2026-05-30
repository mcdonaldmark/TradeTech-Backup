const pool = require("../config/db");

/*
 * CREATE ORDER
 */
exports.createOrder = async (req, res) => {
  try {
    const { items } = req.body;

    const user_id =
      req.user.role === "user"
        ? req.user.id
        : req.body.user_id;

    const created_by = req.user.id;

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

      // -------------------------
      // ORDER ITEMS (unchanged)
      // -------------------------
      await pool.query(
        `INSERT INTO order_items
        (order_id, product_id, product_name, quantity, price, subtotal)
        VALUES ($1,$2,$3,$4,$5,$6)`,
        [
          order.id,
          product.id,
          product.name,
          item.quantity,
          product.price,
          subtotal,
        ]
      );

      await pool.query(
        `UPDATE inventory SET quantity = quantity - $1 WHERE id=$2`,
        [item.quantity, product.id]
      );

      // -------------------------
      // 🔥 FIXED SALES INSERT (THIS WAS BROKEN)
      // -------------------------
      const safeProductName = String(
        product?.name || "Deleted Product"
      );

      await pool.query(
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
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
        [
          product.id,
          safeProductName,
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
 * GET MY ORDERS
 */
exports.getMyOrders = async (req, res) => {
  try {
    const userId = req.user.id;

    if (!userId) {
      return res.status(401).json({ message: "Invalid user session" });
    }

    const result = await pool.query(
      `
      SELECT 
        o.id,
        o.user_id,
        o.total,
        o.status,
        o.created_at,
        COALESCE(u.name, 'Unknown User') AS user_name
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.user_id = $1
      ORDER BY o.created_at DESC
      `,
      [userId]
    );

    return res.json(result.rows);
  } catch (err) {
    console.error("GET MY ORDERS ERROR:", err);
    return res.status(500).json({ error: err.message });
  }
};


/*
 * GET ALL ORDERS
 */
exports.getOrders = async (req, res) => {
  try {
    const role = req.user.role;
    const userId = req.user.id;

    const { user_id, search } = req.query;

    let targetUserId = user_id;

    if (!targetUserId && search) {
      const result = await pool.query(
        `
        SELECT id
        FROM users
        WHERE 
          CAST(id AS TEXT) = $1
          OR LOWER(name) LIKE LOWER($2)
        LIMIT 1
        `,
        [search, `%${search}%`]
      );

      targetUserId = result.rows[0]?.id;
    }

    let result;

    if (role === "user") {
      result = await pool.query(
        `
        SELECT 
          o.*,
          COALESCE(u.name, 'Unknown User') AS user_name
        FROM orders o
        LEFT JOIN users u ON o.user_id = u.id
        WHERE o.user_id = $1
        ORDER BY o.created_at DESC
        `,
        [userId]
      );
    }

    else if (role === "cashier") {

      if (!user_id && !search) {
        return res.json([]);
      }

      let resolvedUserId = user_id;

      if (!resolvedUserId && search) {
        const userResult = await pool.query(
          `
          SELECT id
          FROM users
          WHERE CAST(id AS TEXT) = $1
             OR LOWER(name) ILIKE LOWER($1)
          LIMIT 1
          `,
          [search]
        );

        if (userResult.rows.length === 0) {
          return res.json([]);
        }

        resolvedUserId = userResult.rows[0].id;
      }

      result = await pool.query(
        `
        SELECT 
          o.*,
          COALESCE(u.name, 'Unknown User') AS user_name
        FROM orders o
        LEFT JOIN users u ON o.user_id = u.id
        WHERE o.user_id = $1
        ORDER BY o.created_at DESC
        `,
        [resolvedUserId]
      );
    }

    else {
      result = await pool.query(
        `
        SELECT 
          o.*,
          COALESCE(u.name, 'Unknown User') AS user_name
        FROM orders o
        LEFT JOIN users u ON o.user_id = u.id
        ORDER BY o.created_at DESC
        `
      );
    }

    res.json(result.rows);

  } catch (err) {
    console.error("GET ORDERS ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};


/*
 * GET ORDER BY ID
 */
exports.getOrderById = async (req, res) => {
  try {
    const orderRes = await pool.query(
      `
      SELECT 
        o.id,
        o.user_id,
        o.total,
        o.status,
        o.created_at,
        COALESCE(u.name, 'Unknown User') AS user_name,
        COALESCE(cu.name, 'Unknown User') AS created_by_name
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      LEFT JOIN users cu ON o.created_by = cu.id
      WHERE o.id=$1
      `,
      [req.params.id]
    );

    if (!orderRes.rows.length) {
      return res.status(404).json({ message: "Order not found" });
    }

    const order = orderRes.rows[0];

    if (req.user.role === "user" && order.user_id !== req.user.id) {
      return res.status(403).json({ message: "Access denied" });
    }

    const itemsRes = await pool.query(
      `
      SELECT
        oi.product_id,
        oi.product_name AS name,
        oi.quantity,
        oi.price,
        oi.subtotal
      FROM order_items oi
      WHERE oi.order_id=$1
      ORDER BY oi.id ASC
      `,
      [req.params.id]
    );

    const items = itemsRes.rows || [];

    const subtotal = items.reduce(
      (sum, i) => sum + Number(i.subtotal || 0),
      0
    );

    const taxRate = 0.07;
    const tax = Number((subtotal * taxRate).toFixed(2));
    const total = Number((subtotal + tax).toFixed(2));

    return res.json({
      success: true,
      order: {
        id: order.id,
        user_id: order.user_id,
        user_name: order.user_name,
        created_by: order.created_by_name,
        created_at: order.created_at,
        status: order.status,
        total: Number(order.total),
      },
      items,
      summary: {
        subtotal,
        tax,
        tax_rate: taxRate,
        total,
      }
    });

  } catch (err) {
    console.error("GET ORDER ERROR:", err);
    return res.status(500).json({ error: err.message });
  }
};