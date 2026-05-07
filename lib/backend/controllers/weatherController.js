const axios = require('axios');

// Replace with your OpenWeatherMap API key
const openWeatherApiKey = 'd34fe7183faca01c26a18819a8660dba';  // Add your OpenWeatherMap API key here

// Function to fetch city name from coordinates using OpenWeatherMap API
const getCityNameFromCoordinates = async (latitude, longitude) => {
  const url = 'https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=$`{openWeatherApiKey}`';

  try {
    const response = await axios.get(url);
    if (response.data && response.data.name) {
      const city = response.data.name;
      return city || 'Unknown City';
    }
    return 'City Not Found';
  } catch (error) {
    console.error('Reverse geocoding error:', error);
    return 'City Not Found';
  }
};

// Get current weather by coordinates (no cache, direct API call)
const getCurrentWeather = async (req, res) => {
  const { lat, lng } = req.params;
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lng);

  if (isNaN(latitude) || isNaN(longitude)) {
    return res.status(400).json({ error: 'Invalid latitude or longitude' });
  }

  // Get city name from coordinates using OpenWeatherMap API
  const cityName = await getCityNameFromCoordinates(latitude, longitude);

  try {
    // Call external weather API from Open-Meteo or OpenWeatherMap for current weather
    const weatherApiUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${openWeatherApiKey}&units=metric`;
    const weatherResponse = await axios.get(weatherApiUrl);
    const currentWeather = weatherResponse.data;

    // Check if weather data exists
    if (!currentWeather.main || !currentWeather.weather) {
      return res.status(502).json({ error: 'Failed to fetch valid weather data from the API' });
    }

    const liveWeather = {
      temperature: Math.round(currentWeather.main.temp || 0),
      condition: currentWeather.weather[0]?.description || 'Unknown',
      humidity: Math.round(currentWeather.main.humidity || 0),
      wind_speed: Math.round(currentWeather.wind.speed || 0),
      city: cityName,
    };

    return res.json({ weather: liveWeather, cached: false });
  } catch (apiErr) {
    console.error('Weather API error:', apiErr);
    return res.status(502).json({ error: 'Failed to fetch live weather data' });
  }
};

// Helper function to convert weather codes to conditions (not used in OpenWeatherMap API)
const weatherCodeToCondition = (code) => {
  if (code === 0) return 'Clear';
  if ([1, 2].includes(code)) return 'Partly Cloudy';
  if (code === 3) return 'Cloudy';
  if ([45, 48].includes(code)) return 'Fog';
  if ([51, 53, 55].includes(code)) return 'Drizzle';
  if ([61, 63, 65].includes(code)) return 'Rain';
  if ([71, 73, 75].includes(code)) return 'Snow';
  if ([80, 81, 82].includes(code)) return 'Showers';
  if ([85, 86].includes(code)) return 'Snow Showers';
  if ([95, 96, 99].includes(code)) return 'Thunderstorm';
  return 'Unknown';
};

module.exports = {
  getCurrentWeather,
};