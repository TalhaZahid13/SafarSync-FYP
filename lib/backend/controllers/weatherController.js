const axios = require('axios');
const openWeatherApiKey = process.env.OWM_API_KEY || 'd34fe7183faca01c26a18819a8660dba';
const getCityNameFromCoordinates = async (latitude, longitude) => {
  const url = `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${openWeatherApiKey}`;

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

const getCurrentWeather = async (req, res) => {
  const { lat, lng } = req.params;
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lng);

  if (isNaN(latitude) || isNaN(longitude)) {
    return res.status(400).json({ error: 'Invalid latitude or longitude' });
  }

  const cityName = await getCityNameFromCoordinates(latitude, longitude);

  try {
    const weatherApiUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&appid=${openWeatherApiKey}&units=metric`;
    const weatherResponse = await axios.get(weatherApiUrl);
    const currentWeather = weatherResponse.data;

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

const getWeatherForecast = async (req, res) => {
  const { lat, lng } = req.params;
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lng);

  if (isNaN(latitude) || isNaN(longitude)) {
    return res.status(400).json({ error: 'Invalid latitude or longitude' });
  }

  try {
    const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${latitude}&lon=${longitude}&appid=${openWeatherApiKey}&units=metric`;
    const response = await axios.get(url);
    const data = response.data;

    const byDay = {};
    for (const item of data.list) {
      const date = item.dt_txt.split(' ')[0];
      const hour = item.dt_txt.split(' ')[1];
      if (!byDay[date] || hour === '12:00:00') {
        byDay[date] = {
          date,
          temp_min: Math.round(item.main.temp_min),
          temp_max: Math.round(item.main.temp_max),
          condition: item.weather[0]?.description || 'Unknown',
          icon: item.weather[0]?.icon || '',
          humidity: item.main.humidity,
          wind_speed: Math.round(item.wind.speed),
        };
      }
    }

    return res.json({
      city: data.city?.name || 'Unknown',
      forecast: Object.values(byDay).slice(0, 7),
    });
  } catch (error) {
    console.error('Forecast API error:', error);
    return res.status(502).json({ error: 'Failed to fetch weather forecast' });
  }
};

const getMultipleWeather = async (req, res) => {
  const { locations } = req.body;

  if (!Array.isArray(locations) || locations.length === 0) {
    return res.status(400).json({ error: 'locations array is required' });
  }

  try {
    const results = await Promise.allSettled(
      locations.map(async ({ lat, lng }) => {
        const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${openWeatherApiKey}&units=metric`;
        const response = await axios.get(url);
        const d = response.data;
        return {
          lat,
          lng,
          city: d.name || 'Unknown',
          temperature: Math.round(d.main.temp),
          condition: d.weather[0]?.description || 'Unknown',
          humidity: d.main.humidity,
          wind_speed: Math.round(d.wind.speed),
        };
      })
    );

    const weather = results.map((r, i) =>
      r.status === 'fulfilled'
        ? r.value
        : { lat: locations[i].lat, lng: locations[i].lng, error: r.reason?.message }
    );

    return res.json({ weather });
  } catch (error) {
    console.error('Batch weather error:', error);
    return res.status(502).json({ error: 'Failed to fetch batch weather data' });
  }
};

module.exports = {
  getCurrentWeather,
  getWeatherForecast,
  getMultipleWeather,
};