const db = require('../config/db');

/**
 * Create a new user
 * Uses DB column: full_name, email, password_hash, role
 */
const createUser = async (name, email, passwordHash) => {
    const result = await db.query(
        `INSERT INTO users (full_name, email, password_hash)
         VALUES ($1, $2, $3)
         RETURNING id, full_name, email, role, created_at`,
        [name, email, passwordHash]
    );

    return result.rows[0];
};

/**
 * Find user by email (used for login + duplicate check)
 */
const findUserByEmail = async (email) => {
    const result = await db.query(
        `SELECT * FROM users WHERE email = $1`,
        [email]
    );

    return result.rows[0];
};

module.exports = {
    createUser,
    findUserByEmail
};