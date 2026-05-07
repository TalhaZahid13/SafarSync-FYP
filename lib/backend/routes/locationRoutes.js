const express = require('express');
const { updateLocation, getLatestLocation } = require('../controllers/locationController');

const router = express.Router();

router.post('/update', updateLocation);
router.get('/latest', getLatestLocation);

module.exports = router;
