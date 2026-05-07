const db = require('../config/db');

const toNumber = (value) => {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const normalizeText = (value, maxLength = 255) => {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }

  return trimmed.slice(0, maxLength);
};

const resolveNearestCity = ({ latitude, longitude, fallbackCity, fallbackCountry }, callback) => {
  const nearestCityQuery = `
    SELECT
      city,
      country,
      (
        6371 * ACOS(
          COS(RADIANS(?))
          * COS(RADIANS(latitude))
          * COS(RADIANS(longitude) - RADIANS(?))
          + SIN(RADIANS(?)) * SIN(RADIANS(latitude))
        )
      ) AS distance_km
    FROM destinations
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND city IS NOT NULL
      AND TRIM(city) <> ''
    ORDER BY distance_km ASC
    LIMIT 1
  `;

  db.query(nearestCityQuery, [latitude, longitude, latitude], (err, rows) => {
    if (err) {
      console.error('Nearest city lookup DB error:', err);
      return callback({ city: fallbackCity, country: fallbackCountry });
    }

    if (!rows || rows.length === 0) {
      return callback({ city: fallbackCity, country: fallbackCountry });
    }

    const nearest = rows[0];
    const resolvedCity = normalizeText(nearest.city, 100) ?? fallbackCity;
    const resolvedCountry = normalizeText(nearest.country, 100) ?? fallbackCountry;

    return callback({ city: resolvedCity, country: resolvedCountry });
  });
};

const updateTravelerLocation = ({
  whereClause,
  whereValue,
  lastLocation,
  latitude,
  longitude,
  capturedAt,
}, callback) => {
  const camelCaseQuery = `
    UPDATE Traveler
    SET
      lastLocation = ?,
      last_latitude = ?,
      last_longitude = ?,
      lastLocationUpdatedAt = ?
    WHERE ${whereClause}
  `;

  const snakeCaseQuery = `
    UPDATE Traveler
    SET
      last_location = ?,
      last_latitude = ?,
      last_longitude = ?,
      last_location_updated_at = ?
    WHERE ${whereClause}
  `;

  const params = [lastLocation, latitude, longitude, capturedAt, whereValue];

  db.query(camelCaseQuery, params, (camelErr, camelResult) => {
    if (!camelErr) {
      return callback(null, camelResult);
    }

    if (camelErr.code !== 'ER_BAD_FIELD_ERROR') {
      return callback(camelErr);
    }

    db.query(snakeCaseQuery, params, (snakeErr, snakeResult) => {
      if (snakeErr) {
        return callback(snakeErr);
      }

      return callback(null, snakeResult);
    });
  });
};

const updateLocation = (req, res) => {
  const latitude = toNumber(req.body.latitude);
  const longitude = toNumber(req.body.longitude);
  const accuracy = toNumber(req.body.accuracy);
  const city = normalizeText(req.body.city, 100);
  const country = normalizeText(req.body.country, 100);
  const userIdentifier = normalizeText(req.body.user_identifier, 128);
  const userEmail = normalizeText(req.body.user_email, 255);
  const travelerUserId = toNumber(req.user?.userId ?? req.body.user_id);

  if (latitude === null || longitude === null) {
    return res.status(400).json({
      success: false,
      error: 'latitude and longitude are required numeric values',
    });
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return res.status(400).json({
      success: false,
      error: 'Invalid coordinate range',
    });
  }

  const capturedAtRaw = req.body.captured_at;
  const capturedAt = capturedAtRaw ? new Date(capturedAtRaw) : new Date();
  if (Number.isNaN(capturedAt.getTime())) {
    return res.status(400).json({
      success: false,
      error: 'captured_at must be a valid ISO datetime',
    });
  }

  resolveNearestCity(
    {
      latitude,
      longitude,
      fallbackCity: city,
      fallbackCountry: country,
    },
    ({ city: resolvedCity, country: resolvedCountry }) => {
      const query = `
        INSERT INTO user_location_updates (
          user_identifier,
          latitude,
          longitude,
          city,
          country,
          accuracy_meters,
          captured_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `;

      const locationParts = [resolvedCity, resolvedCountry].filter(
        (part) => part && part.length > 0
      );
      const lastLocation =
        locationParts.length > 0
          ? locationParts.join(', ')
          : `${latitude.toFixed(5)}, ${longitude.toFixed(5)}`;

      let travelerWhereClause = null;
      let travelerWhereValue = null;

      if (travelerUserId !== null) {
        travelerWhereClause = 'userId = ?';
        travelerWhereValue = travelerUserId;
      } else if (userEmail) {
        travelerWhereClause = 'email = ?';
        travelerWhereValue = userEmail;
      }

      db.query(
        query,
        [
          userIdentifier,
          latitude,
          longitude,
          resolvedCity,
          resolvedCountry,
          accuracy,
          capturedAt,
        ],
        (err, result) => {
          if (err) {
            console.error('Location update DB error:', err);
            return res.status(500).json({
              success: false,
              error: 'Failed to store location update',
            });
          }

          const finishSuccess = (travelerUpdated) => {
            return res.status(201).json({
              success: true,
              message: 'Location updated',
              location_id: result.insertId,
              traveler_updated: travelerUpdated,
              location: {
                user_identifier: userIdentifier,
                latitude,
                longitude,
                city: resolvedCity,
                country: resolvedCountry,
                accuracy_meters: accuracy,
                captured_at: capturedAt.toISOString(),
                last_location: lastLocation,
              },
            });
          };

          if (!travelerWhereClause || travelerWhereValue === null) {
            return finishSuccess(false);
          }

          updateTravelerLocation(
            {
              whereClause: travelerWhereClause,
              whereValue: travelerWhereValue,
              lastLocation,
              latitude,
              longitude,
              capturedAt,
            },
            (travelerErr, travelerResult) => {
              if (travelerErr) {
                console.error('Traveler location update DB error:', travelerErr);
                return res.status(500).json({
                  success: false,
                  error:
                    'Location history saved, but failed to update Traveler last_location',
                });
              }

              return finishSuccess((travelerResult?.affectedRows ?? 0) > 0);
            }
          );
        }
      );
    }
  );
};

const getLatestLocation = (req, res) => {
  const userIdentifier = normalizeText(req.query.user_identifier, 128);
  if (!userIdentifier) {
    return res.status(400).json({
      success: false,
      error: 'user_identifier is required',
    });
  }

  const query = `
    SELECT
      location_update_id,
      user_identifier,
      latitude,
      longitude,
      city,
      country,
      accuracy_meters,
      captured_at,
      created_at
    FROM user_location_updates
    WHERE user_identifier = ?
    ORDER BY captured_at DESC, created_at DESC
    LIMIT 1
  `;

  db.query(query, [userIdentifier], (err, rows) => {
    if (err) {
      console.error('Latest location DB error:', err);
      return res.status(500).json({
        success: false,
        error: 'Failed to fetch latest location',
      });
    }

    if (!rows || rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No location data found',
      });
    }

    return res.json({
      success: true,
      location: rows[0],
    });
  });
};

module.exports = {
  updateLocation,
  getLatestLocation,
};
