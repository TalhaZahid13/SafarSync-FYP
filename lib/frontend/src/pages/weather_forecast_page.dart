import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../ui/app_theme.dart';

// ─── Extended weather cache (location-keyed, 15-min TTL) ────────────────────

class _ExtCache {
  static _ExtCache? _inst;
  static DateTime? _at;
  static double? _lat;
  static double? _lng;
  static const _ttl = Duration(minutes: 15);

  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> hourly;
  final List<Map<String, dynamic>> daily;

  const _ExtCache({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  static bool _valid(double lat, double lng) =>
      _inst != null &&
      _at != null &&
      DateTime.now().difference(_at!) < _ttl &&
      _lat != null &&
      (_lat! - lat).abs() < 0.02 &&
      _lng != null &&
      (_lng! - lng).abs() < 0.02;

  static _ExtCache? get(double lat, double lng) =>
      _valid(lat, lng) ? _inst : null;

  static void store(_ExtCache c, double lat, double lng) {
    _inst = c;
    _at = DateTime.now();
    _lat = lat;
    _lng = lng;
  }

  static void invalidate() {
    _inst = null;
    _at = null;
    _lat = null;
    _lng = null;
  }
}

// ─── WeatherForecastPage ─────────────────────────────────────────────────────

class WeatherForecastPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialCity;
  final int? initialTemp;
  final String? initialCondition;
  final int? initialWeatherCode;
  final int? initialHumidity;
  final int? initialWindSpeed;
  final int? initialFeelsLike;

  const WeatherForecastPage({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialCity,
    this.initialTemp,
    this.initialCondition,
    this.initialWeatherCode,
    this.initialHumidity,
    this.initialWindSpeed,
    this.initialFeelsLike,
  });

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  // ── State ──────────────────────────────────────────────────────────────────

  bool _loading = true;
  String? _error;
  _ExtCache? _data;

  // Header values (from initial props, overwritten by extended data)
  late String _city;
  late int? _temp;
  late String _condition;
  late int _weatherCode;
  late int? _humidity;
  late int? _windSpeed;
  late int? _feelsLike;

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity ?? 'Loading…';
    _temp = widget.initialTemp;
    _condition = widget.initialCondition ?? 'Loading';
    _weatherCode = widget.initialWeatherCode ?? -1;
    _humidity = widget.initialHumidity;
    _windSpeed = widget.initialWindSpeed;
    _feelsLike = widget.initialFeelsLike;
    _load();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _load({bool forceRefresh = false}) async {
    final lat = widget.initialLat;
    final lng = widget.initialLng;

    if (lat == null || lng == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Location not available';
        });
      }
      return;
    }

    if (!forceRefresh) {
      final cached = _ExtCache.get(lat, lng);
      if (cached != null) {
        if (mounted) {
          setState(() {
            _data = cached;
            _loading = false;
          });
        }
        _applyCurrentFields(cached.current);
        return;
      }
    } else {
      _ExtCache.invalidate();
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
        'wind_speed_10m,weather_code,surface_pressure,precipitation'
        '&hourly=temperature_2m,weather_code,precipitation_probability'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,'
        'precipitation_probability_max,uv_index_max'
        '&timezone=auto'
        '&forecast_days=7',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final raw = await compute(
        (String b) => jsonDecode(b) as Map<String, dynamic>,
        response.body,
      );

      // ── Hourly: next 24 h from now ───────────────────────────────────────
      final hourlyRaw = raw['hourly'] as Map<String, dynamic>;
      final hTimes = (hourlyRaw['time'] as List).cast<String>();
      final hTemps = (hourlyRaw['temperature_2m'] as List)
          .map((e) => (e as num).round())
          .toList();
      final hCodes = (hourlyRaw['weather_code'] as List)
          .map((e) => (e as num).toInt())
          .toList();
      final hPrecip = (hourlyRaw['precipitation_probability'] as List)
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList();

      final now = DateTime.now();
      int startIdx = 0;
      for (int i = 0; i < hTimes.length; i++) {
        final t = DateTime.tryParse(hTimes[i]);
        if (t != null && t.isAfter(now.subtract(const Duration(minutes: 30)))) {
          startIdx = i;
          break;
        }
      }
      final hCount = math.min(24, hTimes.length - startIdx);
      final hourly = List.generate(hCount, (i) {
        final idx = startIdx + i;
        return {
          'time': hTimes[idx],
          'temp': hTemps[idx],
          'code': hCodes[idx],
          'precip': hPrecip[idx],
        };
      });

      // ── Daily: 7 days ────────────────────────────────────────────────────
      final dailyRaw = raw['daily'] as Map<String, dynamic>;
      final dTimes = (dailyRaw['time'] as List).cast<String>();
      final dMax = (dailyRaw['temperature_2m_max'] as List)
          .map((e) => (e as num).round())
          .toList();
      final dMin = (dailyRaw['temperature_2m_min'] as List)
          .map((e) => (e as num).round())
          .toList();
      final dCodes = (dailyRaw['weather_code'] as List)
          .map((e) => (e as num).toInt())
          .toList();
      final dPrecip = (dailyRaw['precipitation_probability_max'] as List)
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList();
      final dUV = (dailyRaw['uv_index_max'] as List)
          .map((e) => (e as num?)?.toDouble() ?? 0.0)
          .toList();

      final daily = List.generate(
        dTimes.length,
        (i) => {
          'date': dTimes[i],
          'max': dMax[i],
          'min': dMin[i],
          'code': dCodes[i],
          'precip': dPrecip[i],
          'uv': dUV[i],
        },
      );

      final current = raw['current'] as Map<String, dynamic>;
      final cache = _ExtCache(current: current, hourly: hourly, daily: daily);
      _ExtCache.store(cache, lat, lng);

      if (!mounted) return;
      setState(() {
        _data = cache;
        _loading = false;
      });
      _applyCurrentFields(current);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load forecast. Check connection.';
        });
      }
    }
  }

  void _applyCurrentFields(Map<String, dynamic> c) {
    if (!mounted) return;
    setState(() {
      _temp = (c['temperature_2m'] as num?)?.round() ?? _temp;
      _humidity = (c['relative_humidity_2m'] as num?)?.round() ?? _humidity;
      _windSpeed = (c['wind_speed_10m'] as num?)?.round() ?? _windSpeed;
      _feelsLike = (c['apparent_temperature'] as num?)?.round() ?? _feelsLike;
      _weatherCode = (c['weather_code'] as num?)?.toInt() ?? _weatherCode;
      _condition = _conditionFromCode(_weatherCode);
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _conditionFromCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    if (code <= 86) return 'Snow Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  IconData _iconFromCode(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code <= 48) return Icons.foggy;
    if (code <= 55) return Icons.grain;
    if (code <= 65) return Icons.umbrella;
    if (code <= 77) return Icons.ac_unit_rounded;
    if (code <= 82) return Icons.water_drop_rounded;
    if (code <= 86) return Icons.cloudy_snowing;
    if (code <= 99) return Icons.thunderstorm_rounded;
    return Icons.cloud_rounded;
  }

  Color _iconColorFromCode(int code) {
    if (code == 0) return const Color(0xFFF59E0B);
    if (code <= 2) return const Color(0xFFF97316);
    if (code == 3) return AppTheme.mediumGray;
    if (code <= 48) return AppTheme.mediumGray;
    if (code <= 65) return Colors.blue.shade400;
    if (code <= 77) return Colors.lightBlue.shade200;
    if (code <= 82) return Colors.blue.shade300;
    if (code <= 99) return Colors.deepPurple.shade300;
    return AppTheme.mediumGray;
  }

  String _hourLabel(String isoDateTime) {
    try {
      final dt = DateTime.parse(isoDateTime);
      return DateFormat('h a').format(dt);
    } catch (_) {
      return '--';
    }
  }

  String _dayLabel(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final today = DateTime.now();
      if (dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day) {
        return 'Today';
      }
      if (dt.difference(today).inDays == 1) return 'Tomorrow';
      return DateFormat('EEE, MMM d').format(dt);
    } catch (_) {
      return '--';
    }
  }

  // ── Weather intelligence ───────────────────────────────────────────────────

  List<_Insight> _buildInsights() {
    final insights = <_Insight>[];
    final code = _weatherCode;
    final temp = _temp ?? 25;
    final wind = _windSpeed ?? 0;
    final humidity = _humidity ?? 50;
    final todayUV = (_data?.daily.isNotEmpty == true)
        ? ((_data!.daily[0]['uv'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final todayPrecip = (_data?.daily.isNotEmpty == true)
        ? (_data!.daily[0]['precip'] as int? ?? 0)
        : 0;

    // Condition-based
    if (code == 0) {
      insights.add(
        const _Insight(
          Icons.wb_sunny_rounded,
          'Clear sky — ideal for outdoor activities',
          Color(0xFFF59E0B),
        ),
      );
    } else if (code <= 2) {
      insights.add(
        const _Insight(
          Icons.wb_cloudy_rounded,
          'Mostly clear — great day for travel',
          Color(0xFFF97316),
        ),
      );
    } else if (code == 3) {
      insights.add(
        const _Insight(
          Icons.cloud_rounded,
          'Overcast but comfortable — perfect for sightseeing',
          AppTheme.mediumGray,
        ),
      );
    } else if (code <= 48) {
      insights.add(
        const _Insight(
          Icons.foggy,
          'Fog expected — keep headlights on while driving',
          AppTheme.mediumGray,
        ),
      );
    } else if (code <= 65) {
      insights.add(
        const _Insight(
          Icons.umbrella,
          'Rain expected — carry an umbrella',
          Colors.blue,
        ),
      );
    } else if (code <= 77) {
      insights.add(
        const _Insight(
          Icons.ac_unit_rounded,
          'Snow conditions — dress warmly in layers',
          Colors.lightBlue,
        ),
      );
    } else if (code <= 82) {
      insights.add(
        const _Insight(
          Icons.water_drop_rounded,
          'Showers throughout the day — stay prepared',
          Colors.blue,
        ),
      );
    } else if (code <= 99) {
      insights.add(
        const _Insight(
          Icons.thunderstorm_rounded,
          'Thunderstorm warning — avoid outdoor activities',
          Colors.deepPurple,
        ),
      );
    }

    // Temperature
    if (temp > 38) {
      insights.add(
        const _Insight(
          Icons.thermostat,
          'Extreme heat — stay hydrated and seek shade',
          Colors.red,
        ),
      );
    } else if (temp > 32) {
      insights.add(
        _Insight(
          Icons.thermostat,
          'Very warm at $temp°C — hydrate frequently',
          Colors.orange.shade700,
        ),
      );
    } else if (temp >= 20 && temp <= 28 && code <= 3) {
      insights.add(
        const _Insight(
          Icons.thumb_up_rounded,
          'Perfect temperature — great day for travel',
          Colors.green,
        ),
      );
    } else if (temp < 5) {
      insights.add(
        const _Insight(
          Icons.severe_cold_rounded,
          'Very cold — bundle up with heavy layers',
          Colors.lightBlue,
        ),
      );
    }

    // Wind
    if (wind > 60) {
      insights.add(
        _Insight(
          Icons.air,
          'Strong winds ($wind km/h) — secure loose items outdoors',
          Colors.deepOrange,
        ),
      );
    } else if (wind > 35) {
      insights.add(
        _Insight(
          Icons.air,
          'Breezy at $wind km/h — hold onto hats!',
          Colors.orange,
        ),
      );
    }

    // UV
    if (todayUV >= 8) {
      insights.add(
        _Insight(
          Icons.wb_sunny_outlined,
          'Very high UV (${todayUV.round()}) — SPF 50+ sunscreen essential',
          Colors.red.shade700,
        ),
      );
    } else if (todayUV >= 5) {
      insights.add(
        _Insight(
          Icons.wb_sunny_outlined,
          'Moderate-High UV (${todayUV.round()}) — sunscreen recommended',
          Colors.orange,
        ),
      );
    }

    // Humidity
    if (humidity > 85) {
      insights.add(
        _Insight(
          Icons.water_drop_outlined,
          'Very high humidity ($humidity%) — feels uncomfortable',
          Colors.blue.shade700,
        ),
      );
    }

    // Rain probability from today's daily
    if (todayPrecip > 70 && code <= 65) {
      insights.add(
        _Insight(
          Icons.umbrella,
          '$todayPrecip% chance of rain — umbrella is a must',
          Colors.blue,
        ),
      );
    }

    return insights;
  }

  List<_Advisory> _buildTravelAdvisory() {
    final advisories = <_Advisory>[];
    final code = _weatherCode;
    final wind = _windSpeed ?? 0;
    final todayPrecip = (_data?.daily.isNotEmpty == true)
        ? (_data!.daily[0]['precip'] as int? ?? 0)
        : 0;

    if (code == 0 || code <= 2) {
      advisories.add(
        const _Advisory(
          Icons.directions_car_rounded,
          'Safe for road travel',
          Colors.green,
        ),
      );
      advisories.add(
        const _Advisory(
          Icons.flight_rounded,
          'Excellent flying conditions',
          Colors.green,
        ),
      );
    } else if (code <= 48) {
      advisories.add(
        const _Advisory(
          Icons.visibility_off,
          'Fog advisory — reduce speed, use fog lights',
          Colors.orange,
        ),
      );
    } else if (code <= 65 || todayPrecip > 50) {
      advisories.add(
        const _Advisory(
          Icons.directions_car_rounded,
          'Rain may impact travel — allow extra time',
          Colors.orange,
        ),
      );
      advisories.add(
        const _Advisory(
          Icons.terrain,
          'Hiking trails may be slippery',
          Colors.orange,
        ),
      );
    } else if (code <= 77) {
      advisories.add(
        const _Advisory(
          Icons.directions_car_rounded,
          'Winter driving — check road conditions first',
          Colors.red,
        ),
      );
      advisories.add(
        const _Advisory(
          Icons.hiking_rounded,
          'Outdoor activities not recommended',
          Colors.red,
        ),
      );
    } else if (code >= 95) {
      advisories.add(
        const _Advisory(
          Icons.warning_rounded,
          'Storm warning — postpone non-essential travel',
          Colors.red,
        ),
      );
      advisories.add(
        const _Advisory(
          Icons.flight_rounded,
          'Check with airline for flight updates',
          Colors.red,
        ),
      );
    } else {
      advisories.add(
        const _Advisory(
          Icons.directions_car_rounded,
          'Road conditions are acceptable',
          Colors.teal,
        ),
      );
    }

    if (wind > 50) {
      advisories.add(
        _Advisory(
          Icons.air,
          'Strong wind advisory ($wind km/h) — caution on open roads',
          Colors.deepOrange,
        ),
      );
    }

    return advisories;
  }

  List<_Alert> _buildAlerts() {
    final alerts = <_Alert>[];
    final code = _weatherCode;
    final wind = _windSpeed ?? 0;
    final temp = _temp ?? 25;
    final todayUV = (_data?.daily.isNotEmpty == true)
        ? ((_data!.daily[0]['uv'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final todayPrecip = (_data?.daily.isNotEmpty == true)
        ? (_data!.daily[0]['precip'] as int? ?? 0)
        : 0;

    if (code >= 95) {
      alerts.add(
        const _Alert(
          'Thunderstorm Warning',
          'Severe thunderstorm in the area. Seek shelter indoors.',
          Colors.deepPurple,
        ),
      );
    }
    if (temp >= 40) {
      alerts.add(
        const _Alert(
          'Extreme Heat Alert',
          'Temperature at or above 40°C. Avoid prolonged sun exposure.',
          Colors.red,
        ),
      );
    }
    if (wind >= 60) {
      alerts.add(
        _Alert(
          'Wind Advisory',
          'Winds of $wind km/h expected. Secure outdoor objects.',
          Colors.deepOrange,
        ),
      );
    }
    if (todayPrecip >= 85 && code >= 51 && code <= 82) {
      alerts.add(
        const _Alert(
          'Heavy Rain Warning',
          'High probability of heavy rainfall. Flooding possible in low areas.',
          Colors.blue,
        ),
      );
    }
    if (todayUV >= 10) {
      alerts.add(
        const _Alert(
          'Extreme UV Alert',
          'UV index is extreme. Minimize sun exposure between 10AM–4PM.',
          Colors.orange,
        ),
      );
    }
    return alerts;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);
    final current = _data?.current;
    final todayUV = (_data?.daily.isNotEmpty == true)
        ? ((_data!.daily[0]['uv'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final pressure = (current?['surface_pressure'] as num?)?.round();
    final precipitation =
        (current?['precipitation'] as num?)?.toDouble() ?? 0.0;
    final insights = _buildInsights();
    final advisories = _buildTravelAdvisory();
    final alerts = _buildAlerts();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFB),
      body: RefreshIndicator(
        color: AppTheme.turquoise,
        onRefresh: () => _load(forceRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Expandable hero app bar ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppTheme.turquoise,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: () => _load(forceRefresh: true),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                titlePadding: const EdgeInsets.only(left: 60, bottom: 14),
                title: Text(
                  _city,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: _buildHeroBackground(dateStr, timeStr),
              ),
            ),

            // ── Body content ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.turquoise,
                        ),
                      ),
                    )
                  : _error != null
                  ? _buildError()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Alerts (only if severe)
                        if (alerts.isNotEmpty) _buildAlertsSection(alerts),

                        const SizedBox(height: 16),

                        // Current weather detail grid
                        _buildCurrentDetails(
                          todayUV: todayUV,
                          pressure: pressure,
                          precipitation: precipitation,
                        ),

                        const SizedBox(height: 20),

                        // Hourly forecast
                        if (_data?.hourly.isNotEmpty == true)
                          _buildHourlySection(),

                        const SizedBox(height: 20),

                        // 7-day forecast
                        if (_data?.daily.isNotEmpty == true)
                          _buildDailySection(),

                        const SizedBox(height: 20),

                        // Insights
                        if (insights.isNotEmpty)
                          _buildInsightsSection(insights),

                        const SizedBox(height: 20),

                        // Travel advisory
                        _buildAdvisorySection(advisories),

                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero section (SliverAppBar background) ────────────────────────────────

  Widget _buildHeroBackground(String dateStr, String timeStr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A9DAA), Color(0xFF2CAFBC), Color(0xFF3DBFCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _city,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$dateStr  ·  $timeStr',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Big temperature
                  Text(
                    _temp != null ? '$_temp°' : '--°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Condition + icon
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconFromCode(_weatherCode),
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_feelsLike != null)
                          Text(
                            'Feels like $_feelsLike°',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick stats row
              Row(
                children: [
                  _heroStat(
                    Icons.water_drop_outlined,
                    '${_humidity ?? '--'}%',
                    'Humidity',
                  ),
                  const SizedBox(width: 20),
                  _heroStat(
                    Icons.air_rounded,
                    '${_windSpeed ?? '--'} km/h',
                    'Wind',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    ],
  );

  // ── Current detail grid ───────────────────────────────────────────────────

  Widget _buildCurrentDetails({
    required double todayUV,
    required int? pressure,
    required double precipitation,
  }) {
    final uvColor = todayUV >= 8
        ? Colors.red
        : todayUV >= 5
        ? Colors.orange
        : Colors.green;

    return _sectionCard(
      title: 'Current Conditions',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _detailCell(
              Icons.thermostat_rounded,
              '${_feelsLike ?? '--'}°',
              'Feels Like',
              color: AppTheme.turquoise,
            ),
            _detailCell(
              Icons.water_drop_rounded,
              '${_humidity ?? '--'}%',
              'Humidity',
              color: Colors.blue,
            ),
            _detailCell(
              Icons.air_rounded,
              '${_windSpeed ?? '--'} km/h',
              'Wind',
              color: Colors.teal,
            ),
            _detailCell(
              Icons.wb_sunny_outlined,
              todayUV > 0 ? todayUV.round().toString() : '--',
              'UV Index',
              color: uvColor,
            ),
            _detailCell(
              Icons.compress_rounded,
              pressure != null ? '$pressure hPa' : '--',
              'Pressure',
              color: AppTheme.darkSlate,
            ),
            _detailCell(
              Icons.grain_rounded,
              '${precipitation.toStringAsFixed(1)} mm',
              'Precipitation',
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCell(
    IconData icon,
    String value,
    String label, {
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: AppTheme.mediumGray, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Hourly forecast (24h horizontal scroll) ───────────────────────────────

  Widget _buildHourlySection() {
    return _sectionCard(
      title: 'Hourly Forecast — Next 24 Hours',
      child: SizedBox(
        height: 106,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: _data!.hourly.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final h = _data!.hourly[i];
            final code = h['code'] as int;
            final isNow = i == 0;
            return _HourCard(
              timeLabel: isNow ? 'Now' : _hourLabel(h['time'] as String),
              icon: _iconFromCode(code),
              iconColor: _iconColorFromCode(code),
              temp: '${h['temp']}°',
              precip: h['precip'] as int,
              isNow: isNow,
            );
          },
        ),
      ),
    );
  }

  // ── 7-Day daily forecast ──────────────────────────────────────────────────

  Widget _buildDailySection() {
    final days = _data!.daily;
    // Global min/max across all days for the bar renderer
    final globalMin = days
        .map((d) => d['min'] as int)
        .reduce((a, b) => a < b ? a : b);
    final globalMax = days
        .map((d) => d['max'] as int)
        .reduce((a, b) => a > b ? a : b);

    return _sectionCard(
      title: '7-Day Forecast',
      child: Column(
        children: List.generate(days.length, (i) {
          final d = days[i];
          final code = d['code'] as int;
          return _DayRow(
            dayLabel: _dayLabel(d['date'] as String),
            icon: _iconFromCode(code),
            iconColor: _iconColorFromCode(code),
            condition: _conditionFromCode(code),
            min: d['min'] as int,
            max: d['max'] as int,
            precip: d['precip'] as int,
            globalMin: globalMin,
            globalMax: globalMax,
            isToday: i == 0,
          );
        }),
      ),
    );
  }

  // ── Weather Insights ──────────────────────────────────────────────────────

  Widget _buildInsightsSection(List<_Insight> insights) {
    return _sectionCard(
      title: 'Weather Insights',
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        children: insights
            .map(
              (ins) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ins.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(ins.icon, color: ins.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ins.text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Travel Advisory ───────────────────────────────────────────────────────

  Widget _buildAdvisorySection(List<_Advisory> advisories) {
    return _sectionCard(
      title: 'Travel Advisory',
      icon: Icons.travel_explore_rounded,
      child: Column(
        children: advisories
            .map(
              (adv) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: adv.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(adv.icon, color: adv.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        adv.text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                    _statusDot(adv.color),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _statusDot(Color color) => Container(
    width: 8,
    height: 8,
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  // ── Weather Alerts ────────────────────────────────────────────────────────

  Widget _buildAlertsSection(List<_Alert> alerts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: alerts.map((a) => _AlertBanner(alert: a)).toList(),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _load(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppTheme.turquoise),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _HourCard extends StatelessWidget {
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final String temp;
  final int precip;
  final bool isNow;

  const _HourCard({
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    required this.temp,
    required this.precip,
    this.isNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isNow
            ? AppTheme.turquoise.withValues(alpha: 0.12)
            : const Color(0xFFF5FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNow
              ? AppTheme.turquoise.withValues(alpha: 0.4)
              : AppTheme.lightGray,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            timeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
              color: isNow ? AppTheme.turquoise : AppTheme.mediumGray,
            ),
          ),
          Icon(icon, color: iconColor, size: 22),
          Text(
            temp,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          if (precip > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  size: 9,
                  color: Colors.blue,
                ),
                const SizedBox(width: 1),
                Text(
                  '$precip%',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String dayLabel;
  final IconData icon;
  final Color iconColor;
  final String condition;
  final int min;
  final int max;
  final int precip;
  final int globalMin;
  final int globalMax;
  final bool isToday;

  const _DayRow({
    required this.dayLabel,
    required this.icon,
    required this.iconColor,
    required this.condition,
    required this.min,
    required this.max,
    required this.precip,
    required this.globalMin,
    required this.globalMax,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final range = (globalMax - globalMin).clamp(1, 100);
    final leftFrac = (min - globalMin) / range;
    final widthFrac = ((max - min) / range).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 88,
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? AppTheme.turquoise : AppTheme.darkSlate,
              ),
            ),
          ),
          // Icon + condition
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              condition,
              style: const TextStyle(fontSize: 11, color: AppTheme.mediumGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Temperature bar
          SizedBox(
            width: 120,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$min°',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$max°',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkSlate,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (ctx, box) {
                    return Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Positioned(
                          left: box.maxWidth * leftFrac,
                          child: Container(
                            height: 4,
                            width: box.maxWidth * widthFrac,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3DBFCC), Color(0xFFF59E0B)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Rain probability
          if (precip > 0) ...[
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  size: 11,
                  color: Colors.blue,
                ),
                const SizedBox(width: 2),
                Text(
                  '$precip%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final _Alert alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: alert.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: alert.color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Insight {
  final IconData icon;
  final String text;
  final Color color;
  const _Insight(this.icon, this.text, this.color);
}

class _Advisory {
  final IconData icon;
  final String text;
  final Color color;
  const _Advisory(this.icon, this.text, this.color);
}

class _Alert {
  final String title;
  final String message;
  final Color color;
  const _Alert(this.title, this.message, this.color);
}
