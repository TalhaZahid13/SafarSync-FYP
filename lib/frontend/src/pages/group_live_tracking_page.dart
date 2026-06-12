import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/api_service.dart';
import '../utils/app_config.dart';

class GroupLiveTrackingPage extends StatefulWidget {
  final int groupBookingId;

  const GroupLiveTrackingPage({super.key, required this.groupBookingId});

  @override
  State<GroupLiveTrackingPage> createState() => _GroupLiveTrackingPageState();
}

class _GroupLiveTrackingPageState extends State<GroupLiveTrackingPage> {
  final MapController _mapController = MapController();
  io.Socket? _socket;

  List<dynamic> memberLocations = [];
  Map<int, LatLng> memberMarkers = {};
  LatLng? currentPosition;
  bool loading = true;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentLocation();
    await _loadMemberLocations();
    await _setupSocket();
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (mounted) {
        setState(() {
          currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Error getting location
    }
  }

  Future<void> _loadMemberLocations() async {
    try {
      final response = await ApiService
          .getRequest('/group-bookings/${widget.groupBookingId}/locations');
      if (mounted && response['success'] == true) {
        setState(() {
          memberLocations = response['member_locations'] as List<dynamic>? ?? [];
          _buildMarkers();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _buildMarkers() {
    memberMarkers.clear();
    for (final loc in memberLocations) {
      if (loc['latitude'] != null && loc['longitude'] != null) {
        memberMarkers[loc['user_id'] as int] =
            LatLng((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble());
      }
    }
  }

  Future<void> _setupSocket() async {
    try {
      _socket = io.io(
        AppConfig.baseUrl.replaceFirst('http://', 'ws://'),
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        _socket!.emit('join:group-tracking', widget.groupBookingId);
      });

      _socket!.on('location:group-updated', (data) {
        if (mounted) {
          setState(() {
            memberMarkers[data['user_id'] as int] =
                LatLng((data['latitude'] as num).toDouble(), (data['longitude'] as num).toDouble());
          });
        }
      });

      _socket!.connect();
    } catch (e) {
      // Socket setup error
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        if (mounted) {
          setState(() {
            currentPosition = LatLng(position.latitude, position.longitude);
          });
        }

        _socket?.emit('location:update-group', {
          'group_booking_id': widget.groupBookingId,
          'user_id': ApiService.userId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'user_name': 'Current User',
        });
      } catch (e) {
        // Error updating location
      }
    });
  }

  List<Marker> _buildMapMarkers() {
    List<Marker> markers = [];

    // Add member markers
    memberMarkers.forEach((userId, location) {
      final member = memberLocations.firstWhere(
        (m) => m['user_id'] == userId,
        orElse: () => null,
      );

      if (member != null) {
        markers.add(
          Marker(
            point: location,
            width: 120,
            height: 140,
            child: GestureDetector(
              onTap: () {
                _showMemberInfo(member);
              },
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        Text(
                          member['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (member['captured_at'] != null)
                          Text(
                            'Updated',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    // Add current position marker
    if (currentPosition != null) {
      markers.add(
        Marker(
          point: currentPosition!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showMemberInfo(dynamic member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member['full_name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${member['email'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            if (member['city'] != null || member['country'] != null)
              Text(
                'Location: ${member['city'] ?? ''}, ${member['country'] ?? ''}',
              ),
            if (member['captured_at'] != null)
              Text('Last Update: ${member['captured_at']}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Group Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMemberLocations,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentPosition ??
                        const LatLng(37.7749, -122.4194), // Default to SF
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.safarsync',
                    ),
                    MarkerLayer(markers: _buildMapMarkers()),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (currentPosition != null) {
                        _mapController.move(currentPosition!, 13);
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Group Members',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${memberLocations.length} active',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: memberLocations.length,
                            itemBuilder: (context, index) {
                              final member = memberLocations[index];
                              return GestureDetector(
                                onTap: () => _showMemberInfo(member),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        child: Text(
                                          member['full_name']?[0] ?? '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member['full_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (member['city'] != null)
                                        Text(
                                          member['city'],
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
