import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import '../ui/app_theme.dart';
import '../utils/api_service.dart';
import '../utils/app_config.dart';
import '../utils/safe_parse.dart';
import '../utils/route_session.dart';
import '../utils/vehicle_type.dart';

/// Auto-detects GPS and opens [LiveMapPage] toward [name].
/// If [lat]/[lng] are provided, uses them directly; otherwise geocodes [name], Pakistan.
Future<void> autoNavigateTo(
  BuildContext context, {
  required String name,
  double? lat,
  double? lng,
}) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Enable them in Settings.')),
      );
    }
    return;
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied. Enable it in app settings.')),
      );
    }
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Finding route to $name…'),
        duration: const Duration(seconds: 15),
      ),
    );
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
    final origin = LatLng(pos.latitude, pos.longitude);

    LatLng destination;
    if (lat != null && lng != null) {
      destination = LatLng(lat, lng);
    } else {
      final locs = await locationFromAddress('$name, Pakistan');
      destination = LatLng(locs.first.latitude, locs.first.longitude);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveMapPage(
          routeOrigin: origin,
          routeDestination: destination,
          destinationName: name,
        ),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lat == null
                ? 'Could not find location — check your connection and try again'
                : 'Could not get your GPS position — try again',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Decodes a Google Maps encoded polyline (precision = 5 decimal places).
/// Must be top-level so it can be passed to [compute].
List<LatLng> _decodePolyline5(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int shift = 0, result = 0, byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0; result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

/// Decodes a Valhalla-encoded polyline (precision = 6 decimal places).
/// Must be top-level so it can be passed to [compute].
List<LatLng> _decodePolyline6(String encoded) {
  final points = <LatLng>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < encoded.length) {
    int shift = 0, result = 0, byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e6, lng / 1e6));
  }
  return points;
}

class LiveMapPage extends StatefulWidget {
  final LatLng? routeOrigin;
  final LatLng? routeDestination;
  final String? destinationName;
  final VehicleType vehicleType;

  const LiveMapPage({
    super.key,
    this.routeOrigin,
    this.routeDestination,
    this.destinationName,
    this.vehicleType = VehicleType.car,
  });

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController _mapController = MapController();
  io.Socket? _socket;

  LatLng? _position;
  double _accuracy = 0;
  double _speed = 0;
  String _address = 'Locating...';
  bool _autoFollow = true;
  bool _isLoading = true;
  bool _mapReady = false;
  String? _error;

  // Route navigation state
  List<LatLng> _routePoints = [];
  double _remainingDistM = 0;
  double _totalDurS = 0;
  double _totalDistM = 0;
  bool _fetchingRoute = false;
  bool _routeFetched = false;

  // Flight overlay (shown for long-distance routes > 180 km)
  List<LatLng> _flightPoints = [];
  double _flightDistM = 0;
  int _flightMinutes = 0;
  bool _hasFlightOption = false;

  // Session-restored route (when no constructor params given)
  LatLng? _sessionDest;
  LatLng? _sessionOrigin;
  String? _sessionDestName;
  VehicleType _sessionVehicleType = VehicleType.car;

  StreamSubscription<Position>? _posStream;
  Timer? _geocodeDebounce;
  Timer? _backendDebounce;

  LatLng? get _effectiveDest => widget.routeDestination ?? _sessionDest;
  LatLng? get _effectiveOrigin => widget.routeOrigin ?? _sessionOrigin;
  String? get _effectiveDestName => widget.destinationName ?? _sessionDestName;
  VehicleType get _effectiveVehicle =>
      widget.routeDestination != null ? widget.vehicleType : _sessionVehicleType;
  bool get _hasRoute => _effectiveDest != null;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Restore active route from session if no route was passed via constructor.
    if (widget.routeDestination == null) {
      final session = await RouteSession.getActive();
      if (session != null && mounted) {
        final endLat = asDouble(session['end_lat']);
        final endLng = asDouble(session['end_lng']);
        final startLat = asDouble(session['start_lat']);
        final startLng = asDouble(session['start_lng']);
        if (endLat != null && endLng != null) {
          setState(() {
            _sessionDest = LatLng(endLat, endLng);
            _sessionDestName = session['to_name'] as String?;
            if (startLat != null && startLng != null) {
              _sessionOrigin = LatLng(startLat, startLng);
            }
            _sessionVehicleType = VehicleTypeX.fromName(
                session['vehicle_type'] as String?);
          });
        }
      }
    }

    if (!await _ensurePermission()) return;
    _connectSocket();
    _startGpsStream();
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _setError('Location services are disabled. Enable them in Settings.');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _setError('Location permission denied.');
      return false;
    }
    return true;
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _error = msg;
        _isLoading = false;
      });
    }
  }

  void _connectSocket() {
    _socket = io.io(
      ApiService.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setTimeout(5000)
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) => debugPrint('LiveMap: socket connected'));
    _socket!.onConnectError((e) => debugPrint('LiveMap: socket error $e'));
    _socket!.on('location:updated', (data) => debugPrint('LiveMap: remote $data'));
  }

  void _startGpsStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );

    _posStream = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position pos) {
        final latlng = LatLng(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _position = latlng;
            _accuracy = pos.accuracy;
            _speed = pos.speed;
            _isLoading = false;
            _error = null;
          });
        }

        // Fetch route once we have an initial GPS fix
        if (_hasRoute && !_routeFetched && !_fetchingRoute) {
          final origin = _effectiveOrigin ?? latlng;
          _fetchRoute(origin, _effectiveDest!);
        }

        // Update remaining distance to destination
        if (_effectiveDest != null) {
          final dist = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            _effectiveDest!.latitude, _effectiveDest!.longitude,
          );
          if (mounted) setState(() => _remainingDistM = dist);
        }

        if (_autoFollow && _mapReady) {
          _mapController.move(latlng, _mapController.camera.zoom);
        }

        _geocodeDebounce?.cancel();
        _geocodeDebounce = Timer(const Duration(seconds: 6), () {
          _reverseGeocode(pos.latitude, pos.longitude);
        });

        _backendDebounce?.cancel();
        _backendDebounce = Timer(const Duration(seconds: 10), () {
          ApiService.updateLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracy: pos.accuracy,
          );
        });
      },
      onError: (e) => _setError('GPS error: $e'),
    );
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    if (_fetchingRoute) return;
    if (mounted) setState(() => _fetchingRoute = true);

    try {
      final (coords, distM, durS) = _effectiveVehicle == VehicleType.car
          ? await _fetchValhallaCarRoute(from, to)
          : await _fetchOsrmCyclingRoute(from, to);

      if (!mounted) return;
      setState(() {
        _routePoints = coords;
        _totalDistM = distM;
        _totalDurS = durS;
        _remainingDistM = distM;
        _fetchingRoute = false;
        _routeFetched = true;
      });

      if (_mapReady && coords.length >= 2) _fitRoute(coords);
      _maybeCalcFlight(from, to);
    } catch (e) {
      debugPrint('fetchRoute error: $e');
      if (mounted) setState(() => _fetchingRoute = false);
    }
  }

  /// Calculates flight straight-line overlay for routes longer than 180 km.
  void _maybeCalcFlight(LatLng from, LatLng to) {
    final meters = Geolocator.distanceBetween(
        from.latitude, from.longitude, to.latitude, to.longitude);
    if (meters < 180000) return; // no commercial flights below ~180 km
    final minutes = (meters / 1000 / 800 * 60 + 25).round();
    if (!mounted) return;
    setState(() {
      _flightPoints = [from, to];
      _flightDistM = meters;
      _flightMinutes = minutes;
      _hasFlightOption = true;
    });
  }

  /// Car routing — three-tier chain:
  ///   1. Google Maps Directions API (identical routes to what Maps shows)
  ///   2. Valhalla with use_highways:1.0  (if no API key or quota exceeded)
  ///   3. OSRM driving                   (final fallback)
  Future<(List<LatLng>, double, double)> _fetchValhallaCarRoute(
      LatLng from, LatLng to) async {
    // ── Tier 1: Google Maps Directions API ──────────────────────────────────
    final key = AppConfig.googleMapsApiKey;
    if (key.isNotEmpty && key != 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      try {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${from.latitude},${from.longitude}'
          '&destination=${to.latitude},${to.longitude}'
          '&mode=driving'
          '&key=$key',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 20));
        if (resp.statusCode == 200) {
          final data = await compute(
            (String b) => jsonDecode(b) as Map<String, dynamic>,
            resp.body,
          );
          if (data['status'] == 'OK') {
            final routes = data['routes'] as List;
            final route = routes[0] as Map<String, dynamic>;
            final leg = (route['legs'] as List)[0] as Map<String, dynamic>;
            final distM =
                ((leg['distance'] as Map)['value'] as num).toDouble();
            final durS =
                ((leg['duration'] as Map)['value'] as num).toDouble();
            final encoded =
                (route['overview_polyline'] as Map)['points'] as String;
            final coords = await compute(_decodePolyline5, encoded);
            debugPrint('Car route: Google Maps Directions API ✓');
            return (coords, distM, durS);
          }
          debugPrint(
              'Google Maps API status: ${data['status']} — trying Valhalla');
        }
      } catch (e) {
        debugPrint('Google Maps Directions failed ($e) — trying Valhalla');
      }
    }

    // ── Tier 2: Valhalla (use_highways:1.0 forces motorway preference) ──────
    try {
      final body = jsonEncode({
        'locations': [
          {'lon': from.longitude, 'lat': from.latitude},
          {'lon': to.longitude, 'lat': to.latitude},
        ],
        'costing': 'auto',
        'costing_options': {
          'auto': {
            'use_highways': 8.0, // >1 encourages motorways; 8 = strong preference
            'use_tolls': 1.0,    // allow toll motorways (M-1, M-2 are tolled)
            'top_speed': 130,
          }
        },
        'directions_options': {'units': 'kilometers'},
      });
      final resp = await http
          .post(
            Uri.parse('https://valhalla.openstreetmap.de/route'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) throw Exception('Valhalla ${resp.statusCode}');
      final data = await compute(
        (String b) => jsonDecode(b) as Map<String, dynamic>,
        resp.body,
      );
      final leg =
          ((data['trip'] as Map)['legs'] as List)[0] as Map<String, dynamic>;
      final summary = leg['summary'] as Map<String, dynamic>;
      final distM = (summary['length'] as num).toDouble() * 1000;
      final durS = (summary['time'] as num).toDouble();
      final coords = await compute(_decodePolyline6, leg['shape'] as String);
      debugPrint('Car route: Valhalla ✓');
      return (coords, distM, durS);
    } catch (e) {
      debugPrint('Valhalla failed ($e) — falling back to OSRM driving');
    }

    // ── Tier 3: OSRM driving ─────────────────────────────────────────────────
    return _fetchOsrmDrivingFallback(from, to);
  }

  /// OSRM cycling profile: naturally avoids motorways restricted to bikes,
  /// routing through national highways (N-5, N-55…) instead.
  Future<(List<LatLng>, double, double)> _fetchOsrmCyclingRoute(
      LatLng from, LatLng to) async {
    final resp = await http
        .get(Uri.parse(
          'https://router.project-osrm.org/route/v1/cycling/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson',
        ))
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) throw Exception('OSRM ${resp.statusCode}');
    return _parseOsrmResponse(resp.body);
  }

  /// OSRM driving — used only as Valhalla fallback.
  Future<(List<LatLng>, double, double)> _fetchOsrmDrivingFallback(
      LatLng from, LatLng to) async {
    final resp = await http
        .get(Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson',
        ))
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) throw Exception('OSRM fallback ${resp.statusCode}');
    return _parseOsrmResponse(resp.body);
  }

  Future<(List<LatLng>, double, double)> _parseOsrmResponse(
      String body) async {
    final data = await compute(
      (String b) => jsonDecode(b) as Map<String, dynamic>,
      body,
    );
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) throw Exception('No route');
    final route = routes[0] as Map<String, dynamic>;
    final coords = (route['geometry']['coordinates'] as List)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    final distM = (route['distance'] as num).toDouble();
    final durS = (route['duration'] as num).toDouble();
    return (coords, distM, durS);
  }

  void _fitRoute(List<LatLng> points) {
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 120, 40, 180),
      ),
    );
  }

  // ETA in seconds, scaled to remaining distance
  double get _remainingDurS {
    if (_totalDistM <= 0) return _totalDurS;
    return _totalDurS * (_remainingDistM / _totalDistM);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.locality != null && p.locality!.isNotEmpty)
            p.locality!
          else if (p.subAdministrativeArea != null)
            p.subAdministrativeArea!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        if (mounted) setState(() => _address = parts.join(', '));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _geocodeDebounce?.cancel();
    _backendDebounce?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A4C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A4C),
        elevation: 0,
        title: Text(
          _hasRoute ? 'Navigation' : 'Live Location',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_fetchingRoute)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          if (_hasRoute)
            IconButton(
              tooltip: 'Stop navigation',
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
              onPressed: () async {
                await RouteSession.clear();
                if (!mounted) return;
                setState(() {
                  _sessionDest = null;
                  _sessionOrigin = null;
                  _sessionDestName = null;
                  _routePoints = [];
                  _routeFetched = false;
                  _remainingDistM = 0;
                  _flightPoints = [];
                  _flightDistM = 0;
                  _flightMinutes = 0;
                  _hasFlightOption = false;
                });
              },
            ),
          IconButton(
            tooltip: _autoFollow ? 'Auto-follow ON' : 'Auto-follow OFF',
            icon: Icon(
              _autoFollow ? Icons.my_location : Icons.location_searching,
              color: _autoFollow ? AppTheme.turquoise : Colors.white54,
            ),
            onPressed: () => setState(() => _autoFollow = !_autoFollow),
          ),
        ],
      ),
      body: _error != null
          ? _ErrorView(error: _error!, onRetry: _start)
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.turquoise),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _position ?? const LatLng(33.6844, 73.0479),
                        initialZoom: 15,
                        onMapReady: () {
                          _mapReady = true;
                          // Fit route if already fetched when map becomes ready
                          if (_routePoints.length >= 2) {
                            _fitRoute(_routePoints);
                          }
                        },
                        onTap: (_, _) {
                          if (_autoFollow) {
                            setState(() => _autoFollow = false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.safarsync.app',
                          maxZoom: 19,
                        ),

                        // Route polyline
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 6,
                                color: const Color(0xFF3B82F6),
                                borderStrokeWidth: 2,
                                borderColor: const Color(0xFF1D4ED8),
                              ),
                            ],
                          ),

                        if (_position != null) ...[
                          // Accuracy radius ring
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _position!,
                                radius: _accuracy,
                                useRadiusInMeter: true,
                                color: AppTheme.turquoise
                                    .withValues(alpha: 0.12),
                                borderColor: AppTheme.turquoise
                                    .withValues(alpha: 0.5),
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          ),
                          // Live position dot
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _position!,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.turquoise,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.turquoise
                                            .withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Destination marker
                        if (_effectiveDest != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _effectiveDest!,
                                width: 48,
                                height: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.flag,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    Container(
                                      width: 3,
                                      height: 12,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        // ── Flight overlay ──────────────────────────────────
                        // Thin straight line from origin → destination
                        if (_hasFlightOption && _flightPoints.length == 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _flightPoints,
                                strokeWidth: 2,
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.5),
                              ),
                            ],
                          ),

                        // Airplane label at midpoint of flight line
                        if (_hasFlightOption && _flightPoints.length == 2)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  (_flightPoints[0].latitude +
                                          _flightPoints[1].latitude) /
                                      2,
                                  (_flightPoints[0].longitude +
                                          _flightPoints[1].longitude) /
                                      2,
                                ),
                                width: 120,
                                height: 34,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(17),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.flight,
                                          size: 14,
                                          color: Color(0xFF3B82F6)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '~$_flightMinutes min',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Navigation top bar (only when a route is active)
                    if (_hasRoute && _routePoints.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _NavigationBar(
                          destName: _effectiveDestName ?? 'Destination',
                          distanceM: _remainingDistM,
                          durationS: _remainingDurS,
                        ),
                      ),

                    // Route alternatives card (car + flight comparison)
                    if (_hasRoute && _hasFlightOption)
                      Positioned(
                        bottom: 148,
                        left: 16,
                        right: 16,
                        child: _RouteAlternativesCard(
                          carDistM: _totalDistM,
                          carDurS: _totalDurS,
                          flightDistM: _flightDistM,
                          flightMinutes: _flightMinutes,
                          destName: _effectiveDestName ?? '',
                        ),
                      ),

                    // Bottom info panel
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _InfoPanel(
                        address: _address,
                        accuracy: _accuracy,
                        speed: _speed,
                        position: _position,
                      ),
                    ),
                  ],
                ),
      floatingActionButton: (_position != null && !_autoFollow)
          ? FloatingActionButton(
              backgroundColor: AppTheme.turquoise,
              foregroundColor: Colors.white,
              onPressed: () {
                if (_position != null && _mapReady) {
                  _mapController.move(_position!, 16);
                }
                setState(() => _autoFollow = true);
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }
}

// ─── Navigation top bar ───────────────────────────────────────────────────────

class _NavigationBar extends StatelessWidget {
  final String destName;
  final double distanceM;
  final double durationS;

  const _NavigationBar({
    required this.destName,
    required this.distanceM,
    required this.durationS,
  });

  String _formatDist(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.toStringAsFixed(0)} m';
  }

  String _formatDur(double s) {
    final mins = (s / 60).round();
    if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}m';
    return '${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A4C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.turn_right,
                color: Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  destName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDist(distanceM)} · ETA ${_formatDur(durationS)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDist(distanceM),
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDur(durationS),
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom info panel ────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final String address;
  final double accuracy;
  final double speed;
  final LatLng? position;

  const _InfoPanel({
    required this.address,
    required this.accuracy,
    required this.speed,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final speedKmh = speed * 3.6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A4C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.turquoise.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on,
                    color: AppTheme.turquoise, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat('Accuracy', '±${accuracy.toStringAsFixed(0)} m'),
              _Stat('Speed', '${speedKmh.toStringAsFixed(1)} km/h'),
              if (position != null)
                _Stat('Lat', position!.latitude.toStringAsFixed(5)),
              if (position != null)
                _Stat('Lng', position!.longitude.toStringAsFixed(5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off,
                size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(error,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.turquoise,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Route Alternatives Card (car + flight) ───────────────────────────────────

class _RouteAlternativesCard extends StatelessWidget {
  final double carDistM;
  final double carDurS;
  final double flightDistM;
  final int flightMinutes;
  final String destName;

  const _RouteAlternativesCard({
    required this.carDistM,
    required this.carDurS,
    required this.flightDistM,
    required this.flightMinutes,
    required this.destName,
  });

  String _dist(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(0)} km' : '${m.toStringAsFixed(0)} m';

  String _dur(double s) {
    final mins = (s / 60).round();
    return mins >= 60 ? '${mins ~/ 60} hr ${mins % 60} min' : '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A4C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Car row
          _RouteRow(
            icon: Icons.directions_car,
            iconColor: const Color(0xFF3B82F6),
            label: 'Car  ·  via Motorway',
            time: _dur(carDurS),
            dist: _dist(carDistM),
          ),
          Divider(
              color: Colors.white.withValues(alpha: 0.12), height: 14),
          // Flight row
          _RouteRow(
            icon: Icons.flight,
            iconColor: AppTheme.turquoise,
            label: 'Flight  ·  approx.',
            time: '~$flightMinutes min',
            dist: _dist(flightDistM),
            trailing: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/travel/flights?q='
                  '${Uri.encodeComponent('flights to $destName')}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.turquoise.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.turquoise.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Book',
                  style: TextStyle(
                    color: AppTheme.turquoise,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;
  final String dist;
  final Widget? trailing;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.dist,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 1),
              Text(time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
            ],
          ),
        ),
        Text(dist,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}
