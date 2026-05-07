import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/pdf_export.dart';
import '../ui/app_theme.dart';
import 'profile_settings.dart';
import '../auth/login.dart';
import '../utils/responsive.dart';
import '../utils/theme_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _bgTop = AppTheme.pureWhite;
  static const Color _bgMid = AppTheme.offWhite;
  static const Color _bgBottom = AppTheme.pureWhite;
  static const Color _cardBg = AppTheme.pureWhite;
  static const Color _cardOutline = AppTheme.veryLightGray;
  static const Color _titleColor = AppTheme.darkSlate;
  static const Color _mutedText = AppTheme.mediumGray;
  static const Color _gold = AppTheme.turquoise;
  static const Color _orange = AppTheme.turquoise;
  static const Color _teal = AppTheme.turquoise;
  static const Color _violet = AppTheme.lightGray;
  static const Color _cyan = AppTheme.turquoise;

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
    final padding = ResponsiveUtil.getResponsivePadding(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgMid, _bgBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _surfaceCard(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _avatar(),
                                const SizedBox(width: 10),
                                Expanded(child: _profileMeta()),
                                _editButton(context),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _avatar(),
                            SizedBox(width: padding * 0.8),
                            Expanded(child: _profileMeta()),
                            _editButton(context),
                          ],
                        ),
                  SizedBox(height: padding * 0.8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final statWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: statWidth,
                            child: statCard('24', 'Places Visited', _teal),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: statCard('12', 'Badges Earned', _orange),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: statCard('8', 'Trips Planned', _violet),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: padding * 0.8),
            _surfaceCard(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explorer Progress',
                    style: TextStyle(
                      color: _titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: padding * 0.45),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(height: 8, color: AppTheme.veryLightGray),
                        FractionallySizedBox(
                          widthFactor: 0.68,
                          child: Container(
                            height: 8,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_gold, _orange],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: padding * 0.3),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '320 XP to Level 13 • Keep exploring',
                          style: TextStyle(fontSize: 11, color: _mutedText),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.turquoise.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.turquoise.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '680 / 1000 XP',
                          style: TextStyle(
                            fontSize: 10,
                            color: _gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: padding * 0.8),
            _surfaceCard(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [_gold, _orange],
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.award,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recent Achievements',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding * 0.55),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = isMobile
                          ? (constraints.maxWidth - 8) / 2
                          : (constraints.maxWidth - 24) / 4;
                      final labels = const [
                        'Adventurer',
                        'Explorer',
                        'Globetrotter',
                        'Road Warrior',
                      ];
                      final colors = const [_orange, _teal, _violet, _cyan];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(labels.length, (index) {
                          return SizedBox(
                            width: itemWidth,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: colors[index].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors[index].withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colors[index],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      LucideIcons.award,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    labels[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: padding * 0.8),
            _surfaceCard(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SETTINGS & ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _mutedText,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: padding * 0.4),
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
                    LucideIcons.handHelping,
                    'Help & Support',
                    () {},
                  ),
                  settingsButton(
                    context,
                    LucideIcons.fileDown,
                    'Export Trip Data (PDF)',
                    handleExportPDF,
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
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_gold, _orange]),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Icon(LucideIcons.userRound, color: Colors.white, size: 30),
    );
  }

  Widget _profileMeta() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ahmed Khan',
          style: TextStyle(
            color: _titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'ahmedkhan@email.com',
          style: TextStyle(fontSize: 12, color: _mutedText),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 12, color: _mutedText),
            SizedBox(width: 4),
            Text(
              'Islamabad, Pakistan',
              style: TextStyle(fontSize: 11, color: _mutedText),
            ),
          ],
        ),
        SizedBox(height: 3),
        Row(
          children: [
            Icon(LucideIcons.star, size: 12, color: _gold),
            SizedBox(width: 4),
            Text(
              'Explorer Level 12',
              style: TextStyle(
                fontSize: 11,
                color: _gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _editButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      child: const Text(
        'Edit',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _surfaceCard({required EdgeInsets padding, required Widget child}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardOutline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget statCard(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: valueColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: valueColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _mutedText),
          ),
        ],
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
    final isPdf = label.contains('PDF');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isLogout
                  ? const Color(0xFFFF4D6D)
                  : (isPdf ? _gold : _mutedText),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isLogout
                    ? const Color(0xFFFF4D6D)
                    : (isPdf ? _gold : _titleColor),
                fontWeight: isPdf ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
