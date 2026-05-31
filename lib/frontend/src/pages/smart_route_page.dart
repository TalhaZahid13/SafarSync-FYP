import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../components/smart/smart_route_planner.dart';
import '../ui/app_theme.dart';
import 'live_map_page.dart';

class SmartRoutePage extends StatefulWidget {
  const SmartRoutePage({super.key});

  @override
  State<SmartRoutePage> createState() => _SmartRoutePageState();
}

class _SmartRoutePageState extends State<SmartRoutePage> {
  final TextEditingController _fromCtrl = TextEditingController();
  final TextEditingController _toCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _planRoute() async {
    final fromText = _fromCtrl.text.trim();
    final toText = _toCtrl.text.trim();

    if (fromText.isEmpty || toText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter both From and To locations'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final fromQuery = fromText.contains(',') ? fromText : '$fromText, Pakistan';
      final toQuery = toText.contains(',') ? toText : '$toText, Pakistan';

      final fromLocs = await locationFromAddress(fromQuery);
      final toLocs = await locationFromAddress(toQuery);

      if (!mounted) return;

      final origin = LatLng(fromLocs.first.latitude, fromLocs.first.longitude);
      final destination = LatLng(toLocs.first.latitude, toLocs.first.longitude);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMapPage(
            routeOrigin: origin,
            routeDestination: destination,
            destinationName: toText,
          ),
        ),
      );
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
