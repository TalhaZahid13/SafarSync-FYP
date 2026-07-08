import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../components/smart/smart_route_planner.dart';
import '../ui/app_theme.dart';
import '../utils/route_session.dart';
import '../utils/safe_parse.dart';
import '../utils/vehicle_type.dart';
import 'live_map_page.dart';
import 'map_location_picker.dart';

class SmartRoutePage extends StatefulWidget {
  const SmartRoutePage({super.key});

  @override
  State<SmartRoutePage> createState() => _SmartRoutePageState();
}

class _SmartRoutePageState extends State<SmartRoutePage> {
  final TextEditingController _fromCtrl = TextEditingController();
  final TextEditingController _toCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _activeRoute;

  // Exact coords stored when location is set via GPS or map picker.
  // Cleared automatically when the user manually edits the text field.
  LatLng? _fromCoords;
  LatLng? _toCoords;
  bool _settingFrom = false;
  bool _settingTo = false;

  @override
  void initState() {
    super.initState();
    _loadActiveRoute();
    // Clear stored coords whenever the user edits the field manually.
    _fromCtrl.addListener(() {
      if (!_settingFrom) _fromCoords = null;
    });
    _toCtrl.addListener(() {
      if (!_settingTo) _toCoords = null;
    });
  }

  /// Sets From label + exact coords atomically without triggering the listener clear.
  void _setFrom(String label, LatLng coords) {
    _settingFrom = true;
    _fromCtrl.text = label;
    _fromCoords = coords;
    _settingFrom = false;
  }

  /// Sets To label + exact coords atomically without triggering the listener clear.
  void _setTo(String label, LatLng coords) {
    _settingTo = true;
    _toCtrl.text = label;
    _toCoords = coords;
    _settingTo = false;
  }

  Future<void> _loadActiveRoute() async {
    final session = await RouteSession.getActive();
    if (mounted) setState(() => _activeRoute = session);
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  /// Shows a bottom sheet to choose the starting point when From is empty.
  Future<void> _showStartingPointPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B3A5C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Choose starting point',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _PickerOption(
              icon: Icons.my_location,
              iconColor: AppTheme.turquoise,
              title: 'Use my current location',
              subtitle: 'Auto-detect via GPS',
              onTap: () async {
                Navigator.pop(ctx);
                await _fillFromCurrentLocation();
              },
            ),
            const SizedBox(height: 10),
            _PickerOption(
              icon: Icons.edit_outlined,
              iconColor: const Color(0xFF3B82F6),
              title: 'Type an address',
              subtitle: 'Enter city or street name',
              onTap: () {
                Navigator.pop(ctx);
                // Focus From field after sheet closes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus(FocusNode());
                  _fromCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _fromCtrl.text.length),
                  );
                });
              },
            ),
            const SizedBox(height: 10),
            _PickerOption(
              icon: Icons.map_outlined,
              iconColor: const Color(0xFF10B981),
              title: 'Pick from map',
              subtitle: 'Tap a location on the map',
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromMap(_fromCtrl, 'Pick Starting Point');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fillFromCurrentLocation() async {
    setState(() => _loading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      final exactCoords = LatLng(pos.latitude, pos.longitude);
      String label = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      try {
        final marks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          final city = p.locality?.isNotEmpty == true
              ? p.locality!
              : (p.subAdministrativeArea ?? '');
          final country = p.country ?? '';
          final readable = [city, country].where((s) => s.isNotEmpty).join(', ');
          if (readable.isNotEmpty) label = readable;
        }
      } catch (_) {}
      if (!mounted) return;
      // Store exact GPS coords — no re-geocoding when planning
      _setFrom(label, exactCoords);
      // If To is already filled, proceed immediately
      if (_toCtrl.text.trim().isNotEmpty) _planRoute();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not get current location'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFromMap(
      TextEditingController ctrl, String title) async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerPage(title: title),
      ),
    );
    if (result != null && mounted) {
      // Store exact map-picked coords — no re-geocoding needed
      if (ctrl == _fromCtrl) {
        _setFrom(result.address, result.latlng);
      } else {
        _setTo(result.address, result.latlng);
      }
      if (_fromCtrl.text.trim().isNotEmpty &&
          _toCtrl.text.trim().isNotEmpty) {
        _planRoute();
      }
    }
  }

  Future<void> _planRoute() async {
    final fromText = _fromCtrl.text.trim();
    final toText = _toCtrl.text.trim();

    // If From is empty, show the location picker sheet
    if (fromText.isEmpty) {
      await _showStartingPointPicker();
      return;
    }

    if (toText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a destination'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Use exact stored coords when available (GPS / map picker).
      // Fall back to geocoding only when the user typed a text address.
      LatLng origin;
      if (_fromCoords != null) {
        origin = _fromCoords!;
      } else {
        final q = fromText.contains(',') ? fromText : '$fromText, Pakistan';
        final locs = await locationFromAddress(q);
        origin = LatLng(locs.first.latitude, locs.first.longitude);
      }

      LatLng destination;
      if (_toCoords != null) {
        destination = _toCoords!;
      } else {
        final q = toText.contains(',') ? toText : '$toText, Pakistan';
        final locs = await locationFromAddress(q);
        destination = LatLng(locs.first.latitude, locs.first.longitude);
      }

      if (!mounted) return;

      final vehicle = await showVehiclePickerSheet(context);
      if (vehicle == null || !mounted) return; // user dismissed

      await RouteSession.activate(
        routeName: '$fromText → $toText',
        fromName: fromText,
        toName: toText,
        startLat: origin.latitude,
        startLng: origin.longitude,
        endLat: destination.latitude,
        endLng: destination.longitude,
        vehicleType: vehicle,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMapPage(
            routeOrigin: origin,
            routeDestination: destination,
            destinationName: toText,
            vehicleType: vehicle,
          ),
        ),
      );
      if (mounted) _loadActiveRoute();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not find location — check spelling and try again'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A5C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3A5C),
        elevation: 0,
        title: const Text(
          'Smart Route',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1B3A5C),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final entry in [
                        ('Islamabad', 'Murree', '60 km', '1h 30m', 'Today'),
                        ('Lahore', 'Nathiagali', '180 km', '3h 15m', 'Yesterday'),
                        ('Karachi', 'Hyderabad', '163 km', '2h 45m', '3 days ago'),
                      ])
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.route, color: Colors.white54),
                          title: Text(
                            '${entry.$1} → ${entry.$2}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${entry.$3} · ${entry.$4} · ${entry.$5}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Route History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan your journey with real-time weather & traffic data',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── Active Route Banner ──────────────────────────────────────
            if (_activeRoute != null) ...[
              _ActiveRouteBanner(
                route: _activeRoute!,
                onResume: () async {
                  final r = _activeRoute!;
                  final endLat = asDouble(r['end_lat']);
                  final endLng = asDouble(r['end_lng']);
                  final startLat = asDouble(r['start_lat']);
                  final startLng = asDouble(r['start_lng']);
                  if (endLat == null || endLng == null) return;
                  final vehicle = VehicleTypeX.fromName(
                      r['vehicle_type'] as String?);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveMapPage(
                        routeOrigin: startLat != null && startLng != null
                            ? LatLng(startLat, startLng)
                            : null,
                        routeDestination: LatLng(endLat, endLng),
                        destinationName: r['to_name'] as String?,
                        vehicleType: vehicle,
                      ),
                    ),
                  );
                  if (mounted) _loadActiveRoute();
                },
                onStop: () async {
                  await RouteSession.clear();
                  if (mounted) setState(() => _activeRoute = null);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Live Tracking CTA
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveMapPage()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.turquoise, Color(0xFF1B8E99)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.turquoise.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Open Live Map Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Route planner component with live controllers
            SmartRoutePlanner(
              fromController: _fromCtrl,
              toController: _toCtrl,
              isLoading: _loading,
              onPlanRoute: _planRoute,
            ),

            const SizedBox(height: 20),

            // Recent routes section
            const Text(
              'Recent Routes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _RecentRouteCard(
              from: 'Islamabad',
              to: 'Murree',
              distance: '60 km',
              duration: '1h 30m',
              date: 'Today',
              color: const Color(0xFF3B82F6),
            ),
            _RecentRouteCard(
              from: 'Lahore',
              to: 'Nathiagali',
              distance: '180 km',
              duration: '3h 15m',
              date: 'Yesterday',
              color: const Color(0xFF10B981),
            ),
            _RecentRouteCard(
              from: 'Karachi',
              to: 'Hyderabad',
              distance: '163 km',
              duration: '2h 45m',
              date: '3 days ago',
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final String distance;
  final String duration;
  final String date;
  final Color color;

  const _RecentRouteCard({
    required this.from,
    required this.to,
    required this.distance,
    required this.duration,
    required this.date,
    required this.color,
  });

  Future<void> _reuseRoute(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Loading route $from → $to…'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final fromLocs = await locationFromAddress('$from, Pakistan');
      final toLocs = await locationFromAddress('$to, Pakistan');
      scaffold.hideCurrentSnackBar();
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMapPage(
            routeOrigin:
                LatLng(fromLocs.first.latitude, fromLocs.first.longitude),
            routeDestination:
                LatLng(toLocs.first.latitude, toLocs.first.longitude),
            destinationName: to,
          ),
        ),
      );
    } catch (_) {
      scaffold.hideCurrentSnackBar();
      if (!context.mounted) return;
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Could not resolve locations — try again'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.route, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$distance • $duration • $date',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.replay, color: Colors.white54, size: 20),
            onPressed: () => _reuseRoute(context),
            tooltip: 'Reuse route',
          ),
        ],
      ),
    );
  }
}

// ─── Picker option tile ───────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Active Route Banner ──────────────────────────────────────────────────────

class _ActiveRouteBanner extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _ActiveRouteBanner({
    required this.route,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = (route['from_name'] as String?) ?? '';
    final toName = (route['to_name'] as String?) ?? '';
    final routeName = (route['route_name'] as String?) ?? 'Active Route';
    final activatedAt = route['activated_at'] as String?;

    String timeLabel = 'In progress';
    if (activatedAt != null) {
      try {
        final dt = DateTime.parse(activatedAt).toLocal();
        timeLabel = 'Started ${DateFormat('d MMM, h:mm a').format(dt)}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C75), Color(0xFF1B8E99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.turquoise.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.navigation,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined,
                    color: Colors.redAccent, size: 22),
                tooltip: 'Stop route',
                onPressed: onStop,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Color(0xFF22C55E), size: 10),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fromName.isNotEmpty ? fromName : 'Starting point',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      color: Colors.white54, size: 14),
                ),
                Expanded(
                  child: Text(
                    toName.isNotEmpty ? toName : 'Destination',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.circle, color: Color(0xFFEF4444), size: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text('Resume Navigation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B3A5C),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
