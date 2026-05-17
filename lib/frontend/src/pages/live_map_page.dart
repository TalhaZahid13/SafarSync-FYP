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
import '../ui/app_theme.dart';
import '../utils/api_service.dart';
import '../utils/route_session.dart';

class LiveMapPage extends StatefulWidget {
  final LatLng? routeOrigin;
  final LatLng? routeDestination;
  final String? destinationName;

  const LiveMapPage({
    super.key,
    this.routeOrigin,
    this.routeDestination,
    this.destinationName,
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

  // Session-restored route (when no constructor params given)
  LatLng? _sessionDest;
  LatLng? _sessionOrigin;
  String? _sessionDestName;

  StreamSubscription<Position>? _posStream;
  Timer? _geocodeDebounce;
  Timer? _backendDebounce;

  LatLng? get _effectiveDest => widget.routeDestination ?? _sessionDest;
  LatLng? get _effectiveOrigin => widget.routeOrigin ?? _sessionOrigin;
  String? get _effectiveDestName => widget.destinationName ?? _sessionDestName;
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
        final endLat = (session['end_lat'] as num?)?.toDouble();
        final endLng = (session['end_lng'] as num?)?.toDouble();
        final startLat = (session['start_lat'] as num?)?.toDouble();
        final startLng = (session['start_lng'] as num?)?.toDouble();
        if (endLat != null && endLng != null) {
          setState(() {
            _sessionDest = LatLng(endLat, endLng);
            _sessionDestName = session['to_name'] as String?;
            if (startLat != null && startLng != null) {
              _sessionOrigin = LatLng(startLat, startLng);
            }
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
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = await compute(
          (String body) => jsonDecode(body) as Map<String, dynamic>,
          response.body,
        );

        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final coords = (route['geometry']['coordinates'] as List)
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();

          final dist = (route['distance'] as num).toDouble();
          final dur = (route['duration'] as num).toDouble();

          if (!mounted) return;
          setState(() {
            _routePoints = coords;
            _totalDistM = dist;
            _totalDurS = dur;
            _remainingDistM = dist;
            _fetchingRoute = false;
            _routeFetched = true;
          });

          // Fit the camera to show the full route after map is ready
          if (_mapReady && coords.length >= 2) {
            _fitRoute(coords);
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingRoute = false);
    }
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
                                    // Pin stem
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
