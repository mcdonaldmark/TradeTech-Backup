const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const usersModel = require('../models/users');

const register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        const existingUser = await usersModel.findUserByEmail(email);

        if (existingUser) {
            return res.status(400).json({
                message: 'User already exists'
            });
        }

        const saltRounds = 10;

        const passwordHash = await bcrypt.hash(password, saltRounds);

        const user = await usersModel.createUser(
            name,
            email,
            passwordHash
        );

        res.status(201).json({
            message: 'User created successfully',
            user
        });

    } catch (err) {
    console.log("🔥 FULL ERROR OBJECT:");
    console.log(err);
    console.log("🔥 ERROR MESSAGE:");
    console.log(err.message);

    return res.status(500).json({
        message: 'Server error',
        error: err.message,
        stack: err.stack
    });
}
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await usersModel.findUserByEmail(email);

        if (!user) {
            return res.status(400).json({
                message: 'Invalid credentials'
            });
        }

        const isMatch = await bcrypt.compare(
            password,
            user.password_hash
        );

        if (!isMatch) {
            return res.status(400).json({
                message: 'Invalid credentials'
            });
        }

        const token = jwt.sign(
            {
                userId: user.id,
                role: user.role
            },
            process.env.JWT_SECRET,
            {
                expiresIn: '1d'
            }
        );

        res.json({
            message: 'Login successful',
            token
        });

    } catch (err) {
    console.log("🔥 FULL ERROR OBJECT:");
    console.log(err);
    console.log("🔥 ERROR MESSAGE:");
    console.log(err.message);

res.status(500).json({
    message: 'Server error',
    error: err.message
});
    }
};

module.exports = {
    register,
    login
};