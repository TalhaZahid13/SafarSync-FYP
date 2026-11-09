import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/realtime_service.dart';
import '../utils/app_auth.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';

// ─── Colour palette — one per member ────────────────────────────────────────
const _kMarkerColors = [
  Color(0xFF1E88E5), // blue
  Color(0xFFE53935), // red
  Color(0xFF43A047), // green
  Color(0xFF8E24AA), // purple
  Color(0xFFF4511E), // deep-orange
  Color(0xFF00ACC1), // cyan
  Color(0xFFFFB300), // amber
  Color(0xFF6D4C41), // brown
];

Color _colorAt(int index) => _kMarkerColors[index % _kMarkerColors.length];

// ─── Per-member data model ───────────────────────────────────────────────────
class _Member {
  final String userId;
  final String name;
  final String? email;
  LatLng? position;
  DateTime? lastUpdated;
  String? city;
  final int colorIndex;

  _Member({
    required this.userId,
    required this.name,
    this.email,
    this.position,
    this.lastUpdated,
    this.city,
    required this.colorIndex,
  });

  Color get color => _colorAt(colorIndex);
  bool get hasLocation => position != null;

  String get timeAgo {
    if (lastUpdated == null) return 'No location';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─── Main widget ─────────────────────────────────────────────────────────────
class GroupLiveTrackingPage extends StatefulWidget {
  final int groupBookingId;

  const GroupLiveTrackingPage({super.key, required this.groupBookingId});

  @override
  State<GroupLiveTrackingPage> createState() => _GroupLiveTrackingPageState();
}

class _GroupLiveTrackingPageState extends State<GroupLiveTrackingPage> {
  final MapController _mapController = MapController();
  RealtimeRoom? _room;

  // Keyed by userId string
  final Map<String, _Member> _members = {};

  LatLng? _myPosition;
  String _myName = 'Me';
  String _myUserId = '';
  bool _loading = true;
  bool _socketConnected = false;
  DateTime? _lastRefresh;

  Timer? _locationTimer;
  Timer? _uiRefreshTimer;

  // ── Pakistan default centre ─────────────────────────────────────────────
  static const LatLng _defaultCenter = LatLng(30.3753, 69.3451);

  @override
  void initState() {
    super.initState();
    _resolveCurrentUser();
    _initialize();
    // Refresh "X min ago" labels every 30 s without hitting the network
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _resolveCurrentUser() {
    final user = AppAuth.currentUser;
    _myName = user?.displayName ?? user?.email?.split('@').first ?? 'Me';
  }

  Future<void> _initialize() async {
    // Members are keyed by the integer SafarSync user id (same id the API
    // returns in member_locations), so our own pings match our marker.
    _myUserId = '${await ApiService.getCurrentUserId() ?? 'unknown'}';
    await _requestLocationPermission();
    await _fetchCurrentPosition();
    await _loadMembersFromApi();
    _connectSocket();
    _startLocationBroadcast();
  }

  // ── Location permission ─────────────────────────────────────────────────
  Future<void> _requestLocationPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
  }

  // ── Get current device position ─────────────────────────────────────────
  Future<void> _fetchCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _myPosition = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  // ── Load member list + last-known locations from REST API ───────────────
  Future<void> _loadMembersFromApi() async {
    try {
      final resp = await ApiService.getRequest(
        '/group-bookings/${widget.groupBookingId}/locations',
      );
      if (!mounted) return;
      if (resp['success'] == true) {
        final list = resp['member_locations'] as List<dynamic>? ?? [];
        int colorIdx = 0;
        final updated = <String, _Member>{};

        for (final raw in list) {
          final uid = raw['user_id'].toString();
          final existing = _members[uid];
          LatLng? pos;
          DateTime? updatedAt;

          if (raw['latitude'] != null && raw['longitude'] != null) {
            pos = LatLng(
              asDouble(raw['latitude'])!,
              asDouble(raw['longitude'])!,
            );
          }
          if (raw['captured_at'] != null) {
            try {
              updatedAt = DateTime.parse(
                raw['captured_at'].toString(),
              ).toLocal();
            } catch (_) {}
          }

          updated[uid] = _Member(
            userId: uid,
            name: raw['full_name'] as String? ?? 'Unknown',
            email: raw['email'] as String?,
            position: pos ?? existing?.position,
            lastUpdated: updatedAt ?? existing?.lastUpdated,
            city: raw['city'] as String?,
            colorIndex: existing?.colorIndex ?? colorIdx,
          );
          colorIdx++;
        }

        setState(() {
          _members.clear();
          _members.addAll(updated);
          _lastRefresh = DateTime.now();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Realtime (private channel `group-tracking:<id>`) ────────────────────
  void _connectSocket() {
    try {
      _room = RealtimeService.room('group-tracking:${widget.groupBookingId}');
      _room!.connected.addListener(() {
        if (mounted) {
          setState(() => _socketConnected = _room?.connected.value ?? false);
        }
      });

      // Real-time location update from another member
      _room!.on('location:group-updated', (data) {
        if (!mounted) return;
        final uid = data['user_id'].toString();
        if (uid == _myUserId) return;
        final lat = asDouble(data['latitude']);
        final lng = asDouble(data['longitude']);
        if (lat == null || lng == null) return;

        setState(() {
          final existing = _members[uid];
          _members[uid] = _Member(
            userId: uid,
            name: data['user_name'] as String? ?? existing?.name ?? 'Unknown',
            email: existing?.email,
            position: LatLng(lat, lng),
            lastUpdated: DateTime.now(),
            city: existing?.city,
            colorIndex: existing?.colorIndex ?? _members.length,
          );
        });
      });

      // New member accepted invitation → refresh from API
      _room!.on('member:joined', (data) {
        if (data['group_booking_id']?.toString() ==
            widget.groupBookingId.toString()) {
          _loadMembersFromApi();
        }
      });

      _room!.join();
    } catch (_) {}
  }

  // ── Periodic location broadcast + DB save ───────────────────────────────
  void _startLocationBroadcast() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;

        setState(() => _myPosition = LatLng(pos.latitude, pos.longitude));

        // Broadcast live to the other group members
        _room?.emit('location:group-updated', {
          'group_booking_id': widget.groupBookingId,
          'user_id': _myUserId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'user_name': _myName,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });

        // Persist via the API (also forwards to the admin emergency map)
        ApiService.updateLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          groupBookingId: widget.groupBookingId,
        );
      } catch (_) {}
    });
  }

  // ── Fit map to show all member markers ──────────────────────────────────
  void _fitBounds() {
    final points = <LatLng>[];
    for (final m in _members.values) {
      if (m.hasLocation) points.add(m.position!);
    }
    if (_myPosition != null) points.add(_myPosition!);
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      LatLng(minLat - 0.01, minLng - 0.01),
      LatLng(maxLat + 0.01, maxLng + 0.01),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  // ── Build Flutter Map markers ────────────────────────────────────────────
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // One marker per member with known location
    for (final member in _members.values) {
      if (!member.hasLocation) continue;
      markers.add(
        Marker(
          point: member.position!,
          width: 130,
          height: 72,
          child: GestureDetector(
            onTap: () => _showMemberSheet(member),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Name + timestamp bubble ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member.color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        member.timeAgo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Pin icon ────────────────────────────────────────────
                Icon(Icons.location_on, color: member.color, size: 22),
              ],
            ),
          ),
        ),
      );
    }

    // Current device position — green pulse dot
    if (_myPosition != null) {
      markers.add(
        Marker(
          point: _myPosition!,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _mapController.move(_myPosition!, 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ── Member detail bottom sheet ───────────────────────────────────────────
  void _showMemberSheet(_Member member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: member.color,
                  radius: 22,
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (member.email != null)
                      Text(
                        member.email!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, 'Last seen', member.timeAgo),
            if (member.city != null)
              _infoRow(Icons.place, 'Location', member.city!),
            if (member.position != null)
              _infoRow(
                Icons.gps_fixed,
                'Coordinates',
                '${member.position!.latitude.toStringAsFixed(5)}, '
                    '${member.position!.longitude.toStringAsFixed(5)}',
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Centre on map'),
                onPressed: () {
                  Navigator.pop(context);
                  if (member.position != null) {
                    _mapController.move(member.position!, 15);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final membersWithLocation = _members.values
        .where((m) => m.hasLocation)
        .length;
    final totalMembers = _members.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Tracking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // LIVE / OFFLINE badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _socketConnected ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _socketConnected ? 'LIVE' : 'OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$membersWithLocation/$totalMembers on map',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit all members',
            onPressed: _fitBounds,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadMembersFromApi,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── Map ────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _myPosition ?? _defaultCenter,
                    initialZoom: 13,
                    onMapReady: () {
                      Future.delayed(
                        const Duration(milliseconds: 300),
                        _fitBounds,
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.safarsync.app',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // ── My location FAB ────────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: 180,
                  child: FloatingActionButton.small(
                    heroTag: 'myLocation',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    onPressed: () {
                      if (_myPosition != null) {
                        _mapController.move(_myPosition!, 15);
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),

                // ── Fit-all FAB ────────────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: 232,
                  child: FloatingActionButton.small(
                    heroTag: 'fitAll',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    onPressed: _fitBounds,
                    child: const Icon(Icons.fit_screen),
                  ),
                ),

                // ── Member panel (bottom sheet) ────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MemberPanel(
                    members: _members.values.toList(),
                    myUserId: _myUserId,
                    onTapMember: (m) {
                      if (m.position != null) {
                        _mapController.move(m.position!, 15);
                      }
                      _showMemberSheet(m);
                    },
                    lastRefresh: _lastRefresh,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _uiRefreshTimer?.cancel();
    _room?.leave();
    super.dispose();
  }
}

// ─── Bottom member panel ──────────────────────────────────────────────────────
class _MemberPanel extends StatelessWidget {
  final List<_Member> members;
  final String myUserId;
  final void Function(_Member) onTapMember;
  final DateTime? lastRefresh;

  const _MemberPanel({
    required this.members,
    required this.myUserId,
    required this.onTapMember,
    this.lastRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Group Members (${members.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (lastRefresh != null)
                  Text(
                    'Refreshed ${_ago(lastRefresh!)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal member cards
          SizedBox(
            height: 96,
            child: members.isEmpty
                ? const Center(
                    child: Text(
                      'No members',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final isMe = m.userId == myUserId;
                      return GestureDetector(
                        onTap: () => onTapMember(m),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: m.hasLocation
                                ? m.color.withValues(alpha: 0.08)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: m.hasLocation
                                  ? m.color.withValues(alpha: 0.4)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: m.color,
                                    child: Text(
                                      m.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (m.hasLocation)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMe ? 'You' : m.name.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                m.hasLocation ? m.timeAgo : 'offline',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: m.hasLocation
                                      ? Colors.green[700]
                                      : Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }
}
