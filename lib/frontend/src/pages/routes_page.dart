import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../utils/responsive.dart';
import '../utils/api_service.dart';
import '../utils/route_session.dart';
import '../ui/app_theme.dart';
import 'live_map_page.dart';
import 'new_route_page.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  static const Color _pageBgTop = AppTheme.pureWhite;
  static const Color _pageBgMid = AppTheme.offWhite;
  static const Color _pageBgBottom = AppTheme.pureWhite;
  static const Color _glassCard = AppTheme.pureWhite;
  static const Color _routeCard = AppTheme.pureWhite;
  static const Color _primaryText = AppTheme.darkSlate;
  static const Color _secondaryText = AppTheme.mediumGray;
  static const Color _teal = AppTheme.turquoise;
  static const Color _cyan = AppTheme.turquoise;
  static const Color _violet = AppTheme.lightGray;
  static const Color _amber = AppTheme.turquoise;
  static const Color _orange = AppTheme.turquoise;

  Map<String, dynamic>? _activeRoute;
  List<Map<String, dynamic>> _backendRoutes = [];
  bool _loadingRoutes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loadingRoutes = true);
    final session = await RouteSession.getActive();
    final routesResult = await ApiService.getUserRoutes();
    if (!mounted) return;
    setState(() {
      _activeRoute = session;
      if (routesResult['success'] == true) {
        final raw = routesResult['routes'];
        if (raw is List) {
          _backendRoutes = raw.cast<Map<String, dynamic>>();
        }
      }
      _loadingRoutes = false;
    });
  }

  Future<void> _startRoute(
    BuildContext context,
    Map<String, dynamic> route,
  ) async {
    final fromName =
        (route['from'] ?? route['start_location'] ?? '') as String;
    final toName = (route['to'] ?? route['end_location'] ?? '') as String;
    final routeName = (route['name'] ?? route['route_name'] ?? 'Route') as String;

    // Use stored coordinates if available (backend routes have them).
    final startLat = (route['start_lat'] as num?)?.toDouble();
    final startLng = (route['start_lng'] as num?)?.toDouble();
    final endLat = (route['end_lat'] as num?)?.toDouble();
    final endLng = (route['end_lng'] as num?)?.toDouble();

    if (endLat != null && endLng != null) {
      await RouteSession.activate(
        routeName: routeName,
        fromName: fromName,
        toName: toName,
        startLat: startLat ?? 0,
        startLng: startLng ?? 0,
        endLat: endLat,
        endLng: endLng,
      );
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMapPage(
            routeDestination: LatLng(endLat, endLng),
            destinationName: toName,
          ),
        ),
      );
      if (mounted) _loadData();
      return;
    }

    // Static routes: geocode first.
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Loading $fromName → $toName…'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );
    try {
      final fromQ =
          fromName.contains(',') ? fromName : '$fromName, Pakistan';
      final toQ = toName.contains(',') ? toName : '$toName, Pakistan';
      final fromLocs = await locationFromAddress(fromQ);
      final toLocs = await locationFromAddress(toQ);
      scaffold.hideCurrentSnackBar();
      if (!context.mounted) return;
      final nav = Navigator.of(context);
      await RouteSession.activate(
        routeName: routeName,
        fromName: fromName,
        toName: toName,
        startLat: fromLocs.first.latitude,
        startLng: fromLocs.first.longitude,
        endLat: toLocs.first.latitude,
        endLng: toLocs.first.longitude,
      );
      await nav.push(
        MaterialPageRoute(
          builder: (_) => LiveMapPage(
            routeOrigin: LatLng(
                fromLocs.first.latitude, fromLocs.first.longitude),
            routeDestination: LatLng(
                toLocs.first.latitude, toLocs.first.longitude),
            destinationName: toName,
          ),
        ),
      );
      if (mounted) _loadData();
    } catch (_) {
      scaffold.hideCurrentSnackBar();
      if (!context.mounted) return;
      scaffold.showSnackBar(
        SnackBar(
          content: const Text(
              'Could not resolve locations — check spelling'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resumeActiveRoute(BuildContext context) async {
    final route = _activeRoute;
    if (route == null) return;
    final endLat = (route['end_lat'] as num?)?.toDouble();
    final endLng = (route['end_lng'] as num?)?.toDouble();
    if (endLat == null || endLng == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveMapPage()),
    );
    if (mounted) _loadData();
  }

  final List<Map<String, dynamic>> savedRoutes = [
    {
      'name': 'Northern Pakistan Tour',
      'tag': 'Popular',
      'from': 'Islamabad',
      'to': 'Hunza Valley',
      'distance': '615 km',
      'duration': '12h 30m',
      'fuelCost': 'Rs 5,500',
      'stops': 3,
    },
    {
      'name': 'Coastal Journey',
      'tag': 'Scenic',
      'from': 'Karachi',
      'to': 'Gwadar',
      'distance': '653 km',
      'duration': '10h 15m',
      'fuelCost': 'Rs 6,000',
      'stops': 2,
    },
    {
      'name': 'Historical Circuit',
      'tag': 'Heritage',
      'from': 'Lahore',
      'to': 'Multan',
      'distance': '340 km',
      'duration': '5h 45m',
      'fuelCost': 'Rs 3,200',
      'stops': 1,
    },
  ];

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    Color bgColor,
    Color borderColor,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: _secondaryText)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRouteCard(
    BuildContext context,
    Map<String, dynamic> route,
    int index,
  ) {
    final List<Color> accentColors = [_teal, _cyan, _violet];
    final Color accent = accentColors[index % accentColors.length];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _routeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.veryLightGray),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            route['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            route['tag'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: _secondaryText,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${route['from']}  →  ${route['to']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _startRoute(context, route),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 110,
                child: _buildInfoCard(
                  context,
                  'Distance',
                  route['distance'],
                  AppTheme.turquoise.withValues(alpha: 0.15),
                  _amber,
                  Icons.near_me,
                  _amber,
                ),
              ),
              SizedBox(
                width: 110,
                child: _buildInfoCard(
                  context,
                  'Duration',
                  route['duration'],
                  AppTheme.turquoise.withValues(alpha: 0.15),
                  _cyan,
                  Icons.access_time,
                  _cyan,
                ),
              ),
              SizedBox(
                width: 110,
                child: _buildInfoCard(
                  context,
                  'Fuel',
                  route['fuelCost'],
                  AppTheme.turquoise.withValues(alpha: 0.15),
                  _teal,
                  Icons.local_gas_station_outlined,
                  _teal,
                ),
              ),
              SizedBox(
                width: 110,
                child: _buildInfoCard(
                  context,
                  'Stops',
                  route['stops'].toString(),
                  AppTheme.lightGray.withValues(alpha: 0.5),
                  _violet,
                  Icons.room_preferences_outlined,
                  _violet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRouteCard(BuildContext context, double padding) {
    if (_loadingRoutes) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _glassCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cyan.withValues(alpha: 0.3), width: 1.2),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
      );
    }

    if (_activeRoute == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _glassCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.veryLightGray, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.navigation_outlined,
                  color: _secondaryText, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'No active route',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _primaryText),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap "New Route" or Start a route below',
                    style: TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final r = _activeRoute!;
    final fromName = r['from_name'] as String? ?? '';
    final toName = r['to_name'] as String? ?? '';
    final routeName = r['route_name'] as String? ?? 'Active Route';
    final activatedAt = r['activated_at'] as String?;
    final travelDate = r['travel_date'] as String?;

    String activatedLabel = 'In Progress';
    if (activatedAt != null) {
      try {
        final dt = DateTime.parse(activatedAt).toLocal();
        activatedLabel =
            'Started ${DateFormat('d MMM, h:mm a').format(dt)}';
      } catch (_) {}
    }

    String travelLabel = '';
    if (travelDate != null) {
      try {
        final dt = DateTime.parse(travelDate);
        travelLabel = 'Travel date: ${DateFormat('d MMM yyyy').format(dt)}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_amber, _orange]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.navigation, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: _primaryText),
                    ),
                    Text(
                      activatedLabel,
                      style:
                          const TextStyle(color: _teal, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Stop button
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined,
                    color: Colors.redAccent, size: 22),
                tooltip: 'Stop route',
                onPressed: () async {
                  await RouteSession.clear();
                  if (mounted) setState(() => _activeRoute = null);
                },
              ),
            ],
          ),
          SizedBox(height: padding * 0.75),

          // From → To visual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.offWhite,
                  AppTheme.lightGray.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.veryLightGray),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.location_on,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fromName.isNotEmpty ? fromName : 'Starting point',
                        style: const TextStyle(
                            color: _primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  height: 1,
                  color: AppTheme.veryLightGray,
                ),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF43F5E),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.location_on,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        toName.isNotEmpty ? toName : 'Destination',
                        style: const TextStyle(
                            color: _primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (travelLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: _secondaryText),
                const SizedBox(width: 6),
                Text(travelLabel,
                    style: const TextStyle(
                        fontSize: 11, color: _secondaryText)),
              ],
            ),
          ],

          SizedBox(height: padding * 0.75),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _resumeActiveRoute(context),
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Resume Navigation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtil.getResponsivePadding(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_pageBgTop, _pageBgMid, _pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'My Routes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Saved and planned routes',
                              style: TextStyle(
                                fontSize: 12,
                                color: _secondaryText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: padding),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewRoutePage(),
                              ),
                            ),
                            icon: Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'New Route',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              backgroundColor: _orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'My Routes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Saved and planned routes',
                              style: TextStyle(
                                fontSize: 12,
                                color: _secondaryText,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewRoutePage(),
                            ),
                          ),
                          icon: const Icon(Icons.add,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'New Route',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: padding),

              // Active Route card
              _buildActiveRouteCard(context, padding),
              SizedBox(height: padding),

              // User-created routes from backend
              if (_loadingRoutes)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(color: _teal),
                  ),
                )
              else if (_backendRoutes.isNotEmpty) ...[
                const Text(
                  '↗ My Routes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                ),
                SizedBox(height: padding * 0.75),
                Column(
                  children: _backendRoutes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final r = entry.value;
                    final unified = {
                      'name': r['route_name'] ?? 'Unnamed Route',
                      'tag': 'Saved',
                      'from': r['start_location'] ?? '',
                      'to': r['end_location'] ?? '',
                      'distance': '—',
                      'duration': '—',
                      'fuelCost': '—',
                      'stops': 0,
                      'start_lat': r['start_lat'],
                      'start_lng': r['start_lng'],
                      'end_lat': r['end_lat'],
                      'end_lng': r['end_lng'],
                    };
                    return Padding(
                      padding: EdgeInsets.only(bottom: padding * 0.75),
                      child: _buildSavedRouteCard(context, unified, index),
                    );
                  }).toList(),
                ),
                SizedBox(height: padding * 0.5),
              ],

              // Suggested routes
              const Text(
                '↗ Suggested Routes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
              SizedBox(height: padding * 0.75),
              Column(
                children: savedRoutes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final route = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: padding * 0.75),
                    child: _buildSavedRouteCard(context, route, index),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
