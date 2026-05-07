import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../utils/api_service.dart';
import 'dart:convert';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String _locationText = 'Fetching location...';
  String? _city;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = true;
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
    _resolveLocationAndSync();
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
      _city = city.isNotEmpty ? city : 'Unknown city';
      _locationText = city.isNotEmpty
          ? (country.isNotEmpty ? '$city, $country' : city)
          : 'Unknown city';
      _isFetchingLocation = false;
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
      } catch (_) {
        // Keep fallback city when reverse geocoding is unavailable.
      }

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _city = city;
        _locationText = country.isEmpty ? city : '$city, $country';
        _isFetchingLocation = false;
      });

      await _syncLocationToBackend(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        accuracy: position.accuracy,
      );

      await _loadWeatherForCoordinates(position.latitude, position.longitude);
    } catch (_) {
      await _tryLoadLocationFromBackend();
    }
  }

  Future<void> _loadWeatherForCoordinates(double lat, double lng) async {
    try {
      // Fetch the current weather data and forecast
      final currentResult = await ApiService.getWeather(lat, lng);
      final forecastResult = await ApiService.getWeatherForecast(
        lat,
        lng,
        days: 4,
      );

      // Check if the widget is still mounted before calling setState
      if (!mounted) return;

      // Extract current weather data
      final currentWeather = currentResult['weather'] as Map<String, dynamic>?;
      final forecastList = (forecastResult['forecast'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      setState(() {
        // Handle current weather data if available
        if (currentResult['success'] == true && currentWeather != null) {
          _temperature = (currentWeather['temperature'] as num?)?.round() ?? 0;
          _humidity = (currentWeather['humidity'] as num?)?.round() ?? 0;
          _windSpeed = (currentWeather['wind_speed'] as num?)?.round() ?? 0;
          _feelsLike = (currentWeather['feels_like'] as num?)?.round() ?? 0;
          _condition = currentWeather['condition'] ?? 'Unknown';
          _weatherCode =
              (currentWeather['weather_code'] as num?)?.toInt() ?? -1;
        } else {
          // Set fallback values in case weather data is not available
          _temperature = 0;
          _humidity = 0;
          _windSpeed = 0;
          _feelsLike = 0;
          _condition = 'Unavailable';
          _weatherCode = -1;
        }

        // Handle the weather forecast data if available
        _forecast = forecastList.isNotEmpty ? forecastList : [];
      });
    } catch (e) {
      print('Error loading weather data: $e');
      // Handle any errors that occur during the API requests
      setState(() {
        _condition = 'Error fetching data';
        _forecast = [];
      });
    }
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
      _isFetchingLocation = false;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecastItems = _forecast.take(4).toList();
    while (forecastItems.length < 4) {
      forecastItems.add({'date': '', 'high_temp': '--', 'weather_code': -1});
    }

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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.92),
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
                            Text(
                              '$_condition ${_temperature ?? '--'}°',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _iconFromWeatherCode(_weatherCode),
                              color: Color(0xFFF59E0B),
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
                      _metricChip(Icons.air, '${_windSpeed ?? '--'} mph'),
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
                          (item['weather_code'] as num?)?.toInt() ?? -1,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
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
