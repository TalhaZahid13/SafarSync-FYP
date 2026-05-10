import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../ui/app_theme.dart';
import '../utils/api_service.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

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

  StreamSubscription<Position>? _posStream;
  Timer? _geocodeDebounce;
  Timer? _backendDebounce;

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
    if (mounted) setState(() { _error = msg; _isLoading = false; });
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
    // Listen for other users' location events (future group tracking)
    _socket!.on('location:updated', (data) => debugPrint('LiveMap: remote $data'));
  }

  void _startGpsStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );

    _posStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
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

        if (_autoFollow && _mapReady) {
          _mapController.move(latlng, _mapController.camera.zoom);
        }

        // Reverse geocode — at most once every 6 s
        _geocodeDebounce?.cancel();
        _geocodeDebounce = Timer(const Duration(seconds: 6), () {
          _reverseGeocode(pos.latitude, pos.longitude);
        });

        // Sync to backend — at most once every 10 s
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

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!
          else if (p.subAdministrativeArea != null) p.subAdministrativeArea!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        setState(() => _address = parts.join(', '));
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
        title: const Text(
          'Live Location',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
                  child: CircularProgressIndicator(color: AppTheme.turquoise),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _position ?? const LatLng(33.6844, 73.0479),
                        initialZoom: 16,
                        onMapReady: () => _mapReady = true,
                        onTap: (_, __) {
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
                        if (_position != null) ...[
                          // Accuracy radius ring
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _position!,
                                radius: _accuracy,
                                useRadiusInMeter: true,
                                color:
                                    AppTheme.turquoise.withValues(alpha: 0.12),
                                borderColor:
                                    AppTheme.turquoise.withValues(alpha: 0.5),
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
                      ],
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
            const Icon(Icons.location_off, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(error,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
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
