const express = require('express');
const { loginUser, registerUser } = require('../controllers/authController');

const router = express.Router();

router.post('/signup', registerUser);
router.post('/login', loginUser);

router.get('/', (req, res) => {
	res.json({ message: 'Auth routes active' });
});

module.exports = router;
