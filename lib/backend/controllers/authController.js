// authController.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db'); // Importing the database connection from db.js

// Login User
const loginUser = async (req, res) => {
  const { email, password } = req.body;

  // Check if email or password is provided
  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  // Query to find user by email
  db.query('SELECT * FROM Traveler WHERE email = ?', [email], async (err, results) => {
    if (err) {
      console.error('Database error: ', err);
      return res.status(500).json({ error: 'Internal server error' });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: 'No user found with this email' });
    }

    const user = results[0];

    // Compare provided password with the stored hashed password
    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const payload = {
      userId: user.userId,
      email: user.email,
      name: user.name,
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });

    // Send the JWT token in the response
    res.json({ token });
  });
};

// Register User (for future use)
const registerUser = async (req, res) => {
  const { email, password, name, phoneNumber, bloodGroup } = req.body;

  // Basic validation
  if (!email || !password || !name) {
    return res.status(400).json({ message: 'Email, password, and name are required' });
  }

  // Check if user already exists
  db.query('SELECT * FROM Traveler WHERE email = ?', [email], async (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new user into the database
    db.query(
      'INSERT INTO Traveler (email, passwordHash, name, phoneNumber, bloodGroup) VALUES (?, ?, ?, ?, ?)',
      [email, hashedPassword, name, phoneNumber, bloodGroup],
      (err, results) => {
        if (err) {
          return res.status(500).json({ error: 'Database error' });
        }
        res.status(201).json({ message: 'User registered successfully' });
      }
    );
  });
};

module.exports = {
  loginUser,
  registerUser,
};