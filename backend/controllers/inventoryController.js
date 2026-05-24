const pool = require("../config/db");

const getProducts = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, description, quantity, price, image_url FROM inventory ORDER BY id DESC"
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const getProductById = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, description, quantity, price, image_url FROM inventory WHERE id=$1",
      [req.params.id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const checkStock = async (req, res) => {
  try {
    const { product_name } = req.query;

    const result = await pool.query(
      "SELECT name, quantity FROM inventory WHERE LOWER(name)=LOWER($1)",
      [product_name]
    );

    const product = result.rows[0];

    if (!product) {
      return res.json({ in_stock: false, quantity: 0 });
    }

    res.json({
      product: product.name,
      in_stock: product.quantity > 0,
      quantity: product.quantity
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const createProduct = async (req, res) => {
  try {
    const { name, description, quantity, price, image_url, cost_price } = req.body;

    const result = await pool.query(
      `INSERT INTO inventory (name, description, quantity, price, image_url, cost_price)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [name, description, quantity, price, image_url, cost_price || 0]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const updateProduct = async (req, res) => {
  try {
    const { name, description, quantity, price, image_url, cost_price } = req.body;

    const result = await pool.query(
      `UPDATE inventory
       SET name=$1,
           description=$2,
           quantity=$3,
           price=$4,
           image_url=$5,
           cost_price=$6
       WHERE id=$7
       RETURNING *`,
      [name, description, quantity, price, image_url, cost_price || 0, req.params.id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const deleteProduct = async (req, res) => {
  try {
    const id = req.params.id;

    await pool.query("DELETE FROM inventory WHERE id=$1", [id]);

    await pool.query(
      "UPDATE sales SET product_id = NULL WHERE product_id = $1",
      [id]
    );

    res.json({ message: "Product deleted permanently" });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  checkStock
};