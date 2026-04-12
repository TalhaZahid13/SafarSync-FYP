const db = require('../config/db');

// Get current weather by coordinates
const getCurrentWeather = (req, res) => {
  const { lat, lng } = req.params;

  // Check cache first
  const cacheQuery = `SELECT weather_data FROM weather_cache 
    WHERE latitude = ? AND longitude = ? AND expires_at > NOW()`;

  db.query(cacheQuery, [lat, lng], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length > 0) {
      return res.json({ weather: JSON.parse(results[0].weather_data), cached: true });
    }

    // TODO: Call external weather API here (OpenWeatherMap, WeatherAPI, etc.)
    // For now, return mock data
    const mockWeather = {
      temperature: 25,
      condition: 'Clear',
      humidity: 65,
      wind_speed: 10,
      uv_index: 6,
      feels_like: 24,
    };

    // Cache the result
    const cacheInsertQuery = `INSERT INTO weather_cache (latitude, longitude, weather_data, expires_at)
      VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 3 HOUR))
      ON DUPLICATE KEY UPDATE weather_data = VALUES(weather_data), expires_at = DATE_ADD(NOW(), INTERVAL 3 HOUR)`;

    db.query(cacheInsertQuery, [lat, lng, JSON.stringify(mockWeather)], (err) => {
      if (err) console.error('Cache error:', err);
    });

    res.json({ weather: mockWeather, cached: false });
  });
};

// Get weather forecast
const getWeatherForecast = (req, res) => {
  const { lat, lng } = req.params;
  const { days = 7 } = req.query;

  // TODO: Call external weather API for forecast
  const mockForecast = [
    {
      date: new Date().toISOString().split('T')[0],
      high_temp: 28,
      low_temp: 20,
      condition: 'Sunny',
      precipitation: 0,
    },
    {
      date: new Date(Date.now() + 86400000).toISOString().split('T')[0],
      high_temp: 26,
      low_temp: 18,
      condition: 'Cloudy',
      precipitation: 10,
    },
  ];

  res.json({ forecast: mockForecast.slice(0, days) });
};

// Get weather for multiple destinations
const getMultipleWeather = (req, res) => {
  const { locations } = req.body;

  if (!Array.isArray(locations) || locations.length === 0) {
    return res.status(400).json({ error: 'locations array is required' });
  }

  const weatherData = locations.map((loc) => ({
    lat: loc.lat,
    lng: loc.lng,
    temperature: 25,
    condition: 'Clear',
    humidity: 65,
  }));

  res.json({ weather: weatherData });
};

module.exports = {
  getCurrentWeather,
  getWeatherForecast,
  getMultipleWeather,
};
