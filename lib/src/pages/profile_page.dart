import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/pdf_export.dart'; // TripData, Destination, RouteData, Hotel, Restaurant, TripStats

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void handleExportPDF() {
    final tripData = TripData(
      userName: 'Muhammad Talha',
      tripName: 'Northern Pakistan Adventure',
      destinations: [
        Destination(
          name: 'Hunza Valley',
          location: 'Gilgit-Baltistan',
          rating: 4.9,
          price: 'Rs 45,000',
        ),
        Destination(
          name: 'Naran Kaghan',
          location: 'Khyber Pakhtunkhwa',
          rating: 4.8,
          price: 'Rs 35,000',
        ),
      ],
      routes: [
        RouteData(
          name: 'Northern Pakistan Tour',
          from: 'Islamabad',
          to: 'Hunza Valley',
          distance: '615 km',
          duration: '12h 30m',
          fuelCost: 'Rs 5,500',
        ),
      ],
      hotels: [
        Hotel(
          name: 'Serena Hotel Islamabad',
          location: 'F-5, Islamabad',
          rating: 4.8,
          price: 'Rs 25,000',
        ),
      ],
      restaurants: [
        Restaurant(
          name: 'Monal Restaurant',
          cuisine: 'Pakistani & Continental',
          rating: 4.9,
          price: 'Rs 3,000',
        ),
        Restaurant(
          name: 'Bundu Khan',
          cuisine: 'Traditional BBQ',
          rating: 4.7,
          price: 'Rs 2,000',
        ),
      ],
      stats: TripStats(placesVisited: 24, badgesEarned: 12, tripsPlanned: 8),
    );

    exportTripToPDF(tripData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // User Info Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Muhammad Talha',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'talhazahid710@email.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 16,
                                  color: Color(0xFF1B5A6E),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Islamabad, Pakistan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      statCard(
                        '24',
                        'Places Visited',
                        Colors.amber.shade200,
                        const Color(0xFF1B5A6E),
                      ),
                      statCard(
                        '12',
                        'Badges Earned',
                        Colors.yellow.shade200,
                        Colors.yellow.shade600,
                      ),
                      statCard(
                        '8',
                        'Trips Planned',
                        Colors.blue.shade100,
                        Colors.blue.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Badges
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.award, size: 24, color: Colors.yellow),
                      SizedBox(width: 8),
                      Text(
                        'Recent Achievements',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      4,
                      (index) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.award,
                            size: 32,
                            color: Colors.yellow,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              'Adventurer',
                              'Explorer',
                              'Globetrotter',
                              'Road Warrior',
                            ][index],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings Menu
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  settingsButton(
                    context,
                    LucideIcons.settings,
                    'Account Settings',
                    () {},
                  ),
                  settingsButton(
                    context,
                    LucideIcons.bell,
                    'Notifications',
                    () {},
                  ),
                  settingsButton(
                    context,
                    LucideIcons.shield,
                    'Privacy & Security',
                    () {},
                  ),
                  settingsButton(
                    context,
                    LucideIcons.fileDown,
                    'Export Trip Data (PDF)',
                    handleExportPDF,
                  ),
                  settingsButton(
                    context,
                    LucideIcons.handHelping,
                    'Help & Support',
                    () {},
                  ),
                  settingsButton(context, LucideIcons.logOut, 'Log Out', () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(String value, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget settingsButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: label.contains('Log Out') ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: label.contains('Log Out') ? Colors.red : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
