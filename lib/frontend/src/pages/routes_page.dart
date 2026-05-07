import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../ui/app_theme.dart';

class RoutesPage extends StatelessWidget {
  RoutesPage({super.key});

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

  final double activeRouteProgress = 0.35;

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
        border: Border.all(color: borderColor.withOpacity(0.5)),
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
            color: accent.withOpacity(0.1),
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
                onPressed: () {},
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
                  AppTheme.turquoise.withOpacity(0.15),
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
                  AppTheme.turquoise.withOpacity(0.15),
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
                  AppTheme.turquoise.withOpacity(0.15),
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
                  AppTheme.lightGray.withOpacity(0.5),
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
                            onPressed: () {},
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
                          onPressed: () {},
                          icon: Icon(Icons.add, size: 16, color: Colors.white),
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

              // Active Route
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _glassCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _cyan.withOpacity(0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_amber, _orange],
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Route',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _primaryText,
                              ),
                            ),
                            const Text(
                              'In Progress',
                              style: TextStyle(color: _teal, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: padding * 0.75),

                    // Route Stops
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.offWhite,
                            AppTheme.lightGray.withOpacity(0.5),
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
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Islamabad',
                                    style: TextStyle(
                                      color: _primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Starting Point',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _secondaryText,
                                    ),
                                  ),
                                ],
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
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF43F5E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Murree',
                                    style: TextStyle(
                                      color: _primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Destination • 45 min away',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: padding * 0.75),

                    // 🔥 NEW: Route progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _secondaryText,
                          ),
                        ),
                        SizedBox(height: padding * 0.375),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: activeRouteProgress,
                            minHeight: 8,
                            backgroundColor: AppTheme.veryLightGray,
                            valueColor: const AlwaysStoppedAnimation(_cyan),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: padding * 0.75),

                    // Info cards
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 110,
                          child: _buildInfoCard(
                            context,
                            'Distance',
                            '60 km',
                            AppTheme.turquoise.withOpacity(0.15),
                            _amber,
                            Icons.near_me,
                            _amber,
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: _buildInfoCard(
                            context,
                            'ETA',
                            '45 min',
                            AppTheme.turquoise.withOpacity(0.15),
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
                            'Rs 800',
                            AppTheme.turquoise.withOpacity(0.15),
                            _teal,
                            Icons.local_gas_station_outlined,
                            _teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: padding),

              // Saved Routes
              const Text(
                '↗ Saved Routes',
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
