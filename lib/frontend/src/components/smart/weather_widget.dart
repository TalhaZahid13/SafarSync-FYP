import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../pages/weather_forecast_page.dart';
import '../../utils/api_service.dart';

// In-memory weather cache shared across all WeatherWidget instances.
// Avoids re-fetching GPS + HTTP on every tab switch while data is fresh.
class _WeatherCache {
  static _WeatherCache? _data;
  static DateTime? _fetchedAt;
  static const _ttl = Duration(minutes: 15);

  final String locationText;
  final String? city;
  final double? latitude;
  final double? longitude;
  final int? temperature;
  final int? humidity;
  final int? windSpeed;
  final int? feelsLike;
  final String condition;
  final int weatherCode;
  final List<Map<String, dynamic>> forecast;

  const _WeatherCache({
    required this.locationText, required this.city,
    required this.latitude, required this.longitude,
    required this.temperature, required this.humidity,
    required this.windSpeed, required this.feelsLike,
    required this.condition, required this.weatherCode,
    required this.forecast,
  });

  static bool get isValid =>
      _data != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _ttl;

  static _WeatherCache? get cached => isValid ? _data : null;
}

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String _locationText = 'Fetching location...';
  double? _latitude;
  double? _longitude;
  int? _temperature;
  int? _humidity;
  int? _windSpeed;
  int? _feelsLike;
  String _condition = 'Loading';
  int _weatherCode = -1;
  List<Map<String, dynamic>> _forecast = [];

  @override
  void initState() {
    super.initState();

    // Serve from cache immediately if data is fresh (< 15 min old)
    final cached = _WeatherCache.cached;
    if (cached != null) {
      _locationText     = cached.locationText;
      _latitude         = cached.latitude;
      _longitude        = cached.longitude;
      _temperature      = cached.temperature;
      _humidity         = cached.humidity;
      _windSpeed        = cached.windSpeed;
      _feelsLike        = cached.feelsLike;
      _condition        = cached.condition;
      _weatherCode      = cached.weatherCode;
      _forecast         = cached.forecast;
      return; // Skip GPS + HTTP
    }

    // Defer past the first frame so the home page can paint before
    // GPS + network calls begin, preventing main-thread frame skipping.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveLocationAndSync();
    });
  }

  Future<void> _tryLoadLocationFromBackend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _setLocationFallback('Unable to fetch location');
      return;
    }

    final result = await ApiService.getLatestLocation(userIdentifier: uid);
    if (result['success'] != true || result['location'] == null) {
      _setLocationFallback('Unable to fetch location');
      return;
    }

    final location = result['location'] as Map<String, dynamic>;
    final lat = double.tryParse('${location['latitude'] ?? ''}');
    final lng = double.tryParse('${location['longitude'] ?? ''}');
    final city = '${location['city'] ?? ''}'.trim();
    final country = '${location['country'] ?? ''}'.trim();

    if (!mounted) return;
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _locationText = city.isNotEmpty
          ? (country.isNotEmpty ? '$city, $country' : city)
          : 'Unknown city';
    });

    if (lat != null && lng != null) {
      await _loadWeatherForCoordinates(lat, lng);
    }
  }

  Future<void> _resolveLocationAndSync() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _tryLoadLocationFromBackend();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _tryLoadLocationFromBackend();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      String city = 'Unknown city';
      String country = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = (place.locality?.isNotEmpty ?? false)
              ? place.locality!
              : (place.subAdministrativeArea?.isNotEmpty ?? false)
              ? place.subAdministrativeArea!
              : city;
          country = place.country ?? '';
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationText = country.isEmpty ? city : '$city, $country';
      });

      // Fire-and-forget — backend sync errors must not affect weather loading.
      _syncLocationToBackend(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        accuracy: position.accuracy,
      ).ignore();

      await _loadWeatherForCoordinates(position.latitude, position.longitude);
    } catch (_) {
      await _tryLoadLocationFromBackend();
    }
  }

  Future<void> _loadWeatherForCoordinates(double lat, double lng) async {
    try {
      // Use Open-Meteo directly — free, no API key, correct field names.
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
        'wind_speed_10m,weather_code'
        '&daily=temperature_2m_max,weather_code'
        '&timezone=auto'
        '&forecast_days=5',
      );

      final response = await http.get(uri);
      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _condition = 'Unavailable';
          _temperature = null;
          _humidity = null;
          _windSpeed = null;
          _feelsLike = null;
          _weatherCode = -1;
          _forecast = [];
        });
        return;
      }

      final data = await compute(
        (String body) => jsonDecode(body) as Map<String, dynamic>,
        response.body,
      );
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;

      final times = (daily['time'] as List).cast<String>();
      final maxTemps = (daily['temperature_2m_max'] as List)
          .map((e) => (e as num).round())
          .toList();
      final codes = (daily['weather_code'] as List)
          .map((e) => (e as num).toInt())
          .toList();

      // Skip today (index 0), show next 4 days.
      final forecastList = List.generate(
        (times.length - 1).clamp(0, 4),
        (i) => {
          'date': times[i + 1],
          'high_temp': maxTemps[i + 1],
          'weather_code': codes[i + 1],
        },
      );

      final weatherCode = (current['weather_code'] as num).toInt();

      if (!mounted) return;
      setState(() {
        _temperature = (current['temperature_2m'] as num).round();
        _humidity = (current['relative_humidity_2m'] as num).round();
        _windSpeed = (current['wind_speed_10m'] as num).round();
        _feelsLike = (current['apparent_temperature'] as num).round();
        _weatherCode = weatherCode;
        _condition = _conditionFromCode(weatherCode);
        _forecast = forecastList;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _condition = 'Unavailable';
        _temperature = null;
        _humidity = null;
        _windSpeed = null;
        _feelsLike = null;
        _weatherCode = -1;
        _forecast = [];
      });
    }
  }

  String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    if (code <= 86) return 'Snow';
    if (code <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  IconData _iconFromWeatherCode(int code) {
    if (code == 0) return Icons.wb_sunny_outlined;
    if ([1, 2].contains(code)) return Icons.cloud_outlined;
    if (code == 3) return Icons.cloud;
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) {
      return Icons.grain;
    }
    if ([71, 73, 75, 77, 85, 86].contains(code)) return Icons.ac_unit;
    if ([95, 96, 99].contains(code)) return Icons.thunderstorm;
    return Icons.cloud_outlined;
  }

  String _dayLabel(String isoDate) {
    try {
      final parsed = DateTime.parse(isoDate);
      return DateFormat('EEE').format(parsed);
    } catch (_) {
      return '--';
    }
  }

  void _setLocationFallback(String text) {
    if (!mounted) return;
    setState(() {
      _locationText = text;
    });
  }

  Future<void> _syncLocationToBackend({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    required double accuracy,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/location/update');
    final headers = await ApiService.getHeaders();
    final currentUser = FirebaseAuth.instance.currentUser;
    final userIdentifier = currentUser?.uid;
    final userEmail = currentUser?.email;

    await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'user_identifier': userIdentifier,
        'user_email': userEmail,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'country': country,
        'accuracy': accuracy,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  void _openForecastPage() {
    if (_latitude == null || _longitude == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherForecastPage(
          initialLat: _latitude,
          initialLng: _longitude,
          initialCity: _locationText,
          initialTemp: _temperature,
          initialCondition: _condition,
          initialWeatherCode: _weatherCode,
          initialHumidity: _humidity,
          initialWindSpeed: _windSpeed,
          initialFeelsLike: _feelsLike,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecastItems = _forecast.take(4).toList();
    while (forecastItems.length < 4) {
      forecastItems.add({'date': '', 'high_temp': '--', 'weather_code': -1});
    }

    final canTap = _latitude != null && _longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT LOCATION',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canTap ? _openForecastPage : null,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationText,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_latitude != null && _longitude != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Lat ${_latitude!.toStringAsFixed(5)}, Lng ${_longitude!.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$_condition ${_temperature ?? '--'}°',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _iconFromWeatherCode(_weatherCode),
                                  color: const Color(0xFFF59E0B),
                                  size: 28,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _metricChip(
                            Icons.water_drop_outlined,
                            '${_humidity ?? '--'}%',
                          ),
                          const SizedBox(height: 8),
                          _metricChip(
                              Icons.air, '${_windSpeed ?? '--'} km/h'),
                          const SizedBox(height: 8),
                          _metricChip(
                            Icons.thermostat,
                            'Feels ${_feelsLike ?? '--'}°',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: forecastItems.map((item) {
                      return Column(
                        children: [
                          Text(
                            _dayLabel('${item['date'] ?? ''}'),
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            _iconFromWeatherCode(
                              (item['weather_code'] as num?)?.toInt() ??
                                  -1,
                            ),
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['high_temp'] ?? '--'}°',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  // Tap hint
                  if (canTap) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_full_rounded,
                            size: 11,
                            color:
                                theme.colorScheme.primary.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Tap for full forecast',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
