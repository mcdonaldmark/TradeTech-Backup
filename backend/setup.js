const pool = require("./config/db");

const setupDatabase = async () => {
    try {
        console.log("Creating tables...");

        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                role VARCHAR(20) NOT NULL CHECK (
                    role IN ('user', 'cashier', 'manager', 'director')
                ),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);

        await pool.query(`
            CREATE TABLE IF NOT EXISTS inventory (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                quantity INTEGER DEFAULT 0,
                price NUMERIC(10,2),
                cost_price NUMERIC(10,2) NOT NULL DEFAULT 0,
                image_url TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);


        await pool.query(`
            CREATE TABLE IF NOT EXISTS sales (
                id SERIAL PRIMARY KEY,
                product_id INTEGER REFERENCES inventory(id) ON DELETE SET NULL,
                quantity_sold INTEGER NOT NULL CHECK (quantity_sold > 0),
                unit_price NUMERIC(10,2) NOT NULL,
                total_revenue NUMERIC(10,2) NOT NULL,
                cost_price NUMERIC(10,2) NOT NULL,
                total_cost NUMERIC(10,2) NOT NULL,
                profit NUMERIC(10,2) NOT NULL,
                sold_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);

        await pool.query(`
    CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        status VARCHAR(20) DEFAULT 'completed',
        total NUMERIC(10,2) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
`);

await pool.query(`
    CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
        product_id INTEGER REFERENCES inventory(id) ON DELETE SET NULL,
        quantity INTEGER NOT NULL,
        price NUMERIC(10,2) NOT NULL,
        subtotal NUMERIC(10,2) NOT NULL
    );
`);

        console.log("All tables created successfully!");
        process.exit(0);

    } catch (err) {
        console.error("Error creating tables:", err.message);
        process.exit(1);
    }
};

setupDatabase();