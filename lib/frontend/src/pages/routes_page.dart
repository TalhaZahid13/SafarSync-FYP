import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class RoutesPage extends StatelessWidget {
  RoutesPage({super.key});

  // 0.0 = 0%, 1.0 = 100%
  // Abhi yeh hard-coded hai; baad mein isay actual distance se link kar sakte ho.
  final double activeRouteProgress = 0.35;

  final List<Map<String, dynamic>> savedRoutes = [
    {
      'name': 'Northern Pakistan Tour',
      'from': 'Islamabad',
      'to': 'Hunza Valley',
      'distance': '615 km',
      'duration': '12h 30m',
      'fuelCost': 'Rs 5,500',
      'stops': 3,
    },
    {
      'name': 'Coastal Journey',
      'from': 'Karachi',
      'to': 'Gwadar',
      'distance': '653 km',
      'duration': '10h 15m',
      'fuelCost': 'Rs 6,000',
      'stops': 2,
    },
    {
      'name': 'Historical Circuit',
      'from': 'Lahore',
      'to': 'Multan',
      'distance': '340 km',
      'duration': '5h 45m',
      'fuelCost': 'Rs 3,200',
      'stops': 1,
    },
  ];

  Widget _buildInfoCard(String label, String value, Color bgColor) {
    final theme = Theme.of(label is String ? null as BuildContext? : throw UnimplementedError());
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRouteCard(BuildContext context, Map<String, dynamic> route) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Name + Start Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        route['from'],
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '→',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        route['to'],
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [colorScheme.secondary, colorScheme.primary],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'Start',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard('Distance', route['distance'], Colors.amber[50]!),
              _buildInfoCard('Duration', route['duration'], Colors.blue[50]!),
              _buildInfoCard('Fuel', route['fuelCost'], Colors.green[50]!),
              _buildInfoCard(
                'Stops',
                route['stops'].toString(),
                Colors.orange[50]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = ResponsiveUtil.getResponsivePadding(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
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
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Saved and planned routes',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: padding),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                          icon: Icon(
                            Icons.add,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                          label: Text(
                            'New Route',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Saved and planned routes',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                        icon: Icon(
                          Icons.add,
                          size: 16,
                          color: colorScheme.onPrimary,
                        ),
                        label: Text(
                          'New Route',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: padding),

            // Active Route
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.secondary, width: 2),
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
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.secondary, colorScheme.primary],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Route',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'In Progress',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 12,
                            ),
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
                          colorScheme.secondaryContainer,
                          colorScheme.tertiaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.green,
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
                                  style: TextStyle(),
                                ),
                                Text(
                                  'Starting Point',
                                  style: TextStyle(
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          height: 1,
                          color: Colors.grey.shade400,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
                                  style: TextStyle(),
                                ),
                                Text(
                                  'Destination • 45 min away',
                                  style: TextStyle(
                                    fontSize: 10,
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
                        ),
                      ),
                      SizedBox(height: padding * 0.375),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: activeRouteProgress, // 0.0 - 1.0
                          minHeight: 8,
                          backgroundColor: theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding * 0.75),

                  // Info cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard('Distance', '60 km', Colors.amber[50]!),
                      _buildInfoCard('ETA', '45 min', Colors.blue[50]!),
                      _buildInfoCard('Fuel', 'Rs 800', Colors.green[50]!),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: padding),

            // Saved Routes
            Text(
              'Saved Routes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding * 0.75),
            Column(
              children: savedRoutes
                  .map(
                    (route) => Padding(
                      padding: EdgeInsets.only(bottom: padding * 0.75),
                      child: _buildSavedRouteCard(context, route),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
