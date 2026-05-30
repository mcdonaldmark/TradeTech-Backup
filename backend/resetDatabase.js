const pool = require("./config/db");

const reset = async () => {
  try {
    console.log("Dropping all tables...");

    await pool.query(`DROP TABLE IF EXISTS order_items CASCADE`);
    await pool.query(`DROP TABLE IF EXISTS orders CASCADE`);
    await pool.query(`DROP TABLE IF EXISTS sales CASCADE`);
    await pool.query(`DROP TABLE IF EXISTS inventory CASCADE`);
    await pool.query(`DROP TABLE IF EXISTS users CASCADE`);

    console.log("All tables dropped successfully");

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
};

reset();