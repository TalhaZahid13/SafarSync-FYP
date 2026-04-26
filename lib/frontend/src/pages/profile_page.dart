import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/pdf_export.dart'; // TripData, Destination, RouteData, Hotel, Restaurant, TripStats
import 'profile_settings.dart';
import '../auth/login.dart';
import '../utils/responsive.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardColor;
    final padding = ResponsiveUtil.getResponsivePadding(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: padding),

          // User Info Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: cardColor,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  isMobile
                      ? Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.secondary,
                                    colorScheme.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                LucideIcons.user,
                                color: colorScheme.onPrimary,
                                size: 40,
                              ),
                            ),
                            SizedBox(height: padding * 0.75),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Muhammad Talha',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'talhazahid710@email.com',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.mapPin,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Islamabad, Pakistan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: padding * 0.75),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfileSettingsPage(),
                                    ),
                                  );
                                },
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
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        colorScheme.secondary,
                                        colorScheme.primary,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.secondary,
                                    colorScheme.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                LucideIcons.user,
                                color: colorScheme.onPrimary,
                                size: 40,
                              ),
                            ),
                            SizedBox(width: padding),

                            // Name + email + location
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Muhammad Talha',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'talhazahid710@email.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.mapPin,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Islamabad, Pakistan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: padding * 0.5),

                            // Edit Profile button (wrapped to avoid overflow)
                            FittedBox(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ProfileSettingsPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        colorScheme.secondary,
                                        colorScheme.primary,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: padding),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      statCard(
                        '24',
                        'Places Visited',
                        Colors.amber.shade200,
                        colorScheme.primary,
                      ),
                      SizedBox(width: padding * 0.5),
                      statCard(
                        '12',
                        'Badges Earned',
                        Colors.yellow.shade200,
                        colorScheme.secondary,
                      ),
                      SizedBox(width: padding * 0.5),
                      statCard(
                        '8',
                        'Trips Planned',
                        Colors.blue.shade100,
                        colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: padding),

          // Recent Badges
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: cardColor,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.award, size: 24, color: colorScheme.secondary),
                      SizedBox(width: 8),
                      Text(
                        'Recent Achievements',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding * 0.5),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: isMobile ? 2 : 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(
                      4,
                      (index) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                          Icon(
                            LucideIcons.award,
                            size: 32,
                            color: Colors.amber,
                          ),
                          SizedBox(height: padding * 0.25),
                          Text(
                            const [
                              'Adventurer',
                              'Explorer',
                              'Globetrotter',
                              'Road Warrior',
                            ][index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodyMedium?.color,
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
          SizedBox(height: padding),

          // Settings Menu
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: cardColor,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: padding * 0.5),
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
                  settingsButton(context, LucideIcons.logOut, 'Log Out', () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }),
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
              textAlign: TextAlign.center,
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
    final isLogout = label.contains('Log Out');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isLogout ? Colors.red : Colors.white70),
            Icon(
              icon,
              size: 20,
              color: isLogout ? Colors.red : theme.iconTheme.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isLogout
                    ? Colors.red
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
