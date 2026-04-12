const express = require('express');
const router = express.Router();
const weatherController = require('../controllers/weatherController');

// Get current weather by coordinates
router.get('/:lat/:lng', weatherController.getCurrentWeather);

// Get weather forecast
router.get('/:lat/:lng/forecast', weatherController.getWeatherForecast);

// Get weather for multiple destinations
router.post('/batch', weatherController.getMultipleWeather);

module.exports = router;
