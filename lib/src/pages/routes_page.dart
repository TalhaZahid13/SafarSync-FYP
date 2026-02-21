import 'package:flutter/material.dart';

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
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRouteCard(Map<String, dynamic> route) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // dark card
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        route['from'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '→',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        route['to'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
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
                    return const LinearGradient(
                      colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                    ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // same as main.dart
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'My Routes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Saved and planned routes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon:
                  const Icon(Icons.add, size: 16, color: Colors.black87),
                  label: const Text(
                    'New Route',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor: const Color(0xFFFDB913),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Route
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFC837), width: 2),
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
                            colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Active Route',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'In Progress',
                            style: TextStyle(
                              color: Color(0xFFFFC837),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Route Stops
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amberAccent, Colors.orangeAccent],
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
                                  style: TextStyle(color: Colors.black87),
                                ),
                                Text(
                                  'Starting Point',
                                  style: TextStyle(
                                    color: Colors.grey,
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
                                  style: TextStyle(color: Colors.black87),
                                ),
                                Text(
                                  'Destination • 45 min away',
                                  style: TextStyle(
                                    color: Colors.grey,
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
                  const SizedBox(height: 12),

                  // 🔥 NEW: Route progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route progress',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: activeRouteProgress, // 0.0 - 1.0
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF1B5A6E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
            const SizedBox(height: 16),

            // Saved Routes
            const Text(
              'Saved Routes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: savedRoutes
                  .map(
                    (route) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSavedRouteCard(route),
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
