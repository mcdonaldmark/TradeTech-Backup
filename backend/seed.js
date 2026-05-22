const pool = require("./config/db");
const bcrypt = require("bcrypt");

const seedUsers = async () => {
    try {
        console.log("Seeding users...");

        const password = await bcrypt.hash("Admin123!", 10);

        const users = [
            {
                name: "System Director",
                email: "director@tradetech.com",
                role: "director"
            },
            {
                name: "System Manager",
                email: "manager@tradetech.com",
                role: "manager"
            },
            {
                name: "System Cashier",
                email: "cashier@tradetech.com",
                role: "cashier"
            },
            {
                name: "System User",
                email: "user@tradetech.com",
                role: "user"
            }
        ];

        for (const user of users) {
            await pool.query(
                `INSERT INTO users (name, email, password, role)
                 VALUES ($1, $2, $3, $4)
                 ON CONFLICT (email) DO NOTHING`,
                [user.name, user.email, password, user.role]
            );
        }

        console.log("All seed users created successfully");
        process.exit(0);

    } catch (err) {
        console.error("Seeding error:", err.message);
        process.exit(1);
    }
};

seedUsers();