import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/pdf_export.dart'; // TripData, Destination, RouteData, Hotel, Restaurant, TripStats
import '../ui/app_theme.dart';
import 'profile_settings.dart';
import 'admin_dashboard_page.dart';
import 'emergency_sos_screen.dart';
import 'emergency_contacts_page.dart';
import 'notifications_page.dart';
import '../utils/notification_service.dart';
import '../auth/login.dart';
import '../utils/responsive.dart';
import '../utils/theme_controller.dart';
import '../utils/api_service.dart';
import '../utils/session_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isAdmin = false;
  Map<String, dynamic> _stats = {};
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isAdmin = await ApiService.getIsAdmin();
    final statsResp = await ApiService.getRequest('/users/stats');
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _stats = (statsResp['stats'] as Map<String, dynamic>?) ?? {};
        _statsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProfilePageView(
      isAdmin: _isAdmin,
      stats: _stats,
      statsLoaded: _statsLoaded,
    );
  }
}

class _ProfilePageView extends StatelessWidget {
  final bool isAdmin;
  final Map<String, dynamic> stats;
  final bool statsLoaded;

  const _ProfilePageView({
    required this.isAdmin,
    required this.stats,
    required this.statsLoaded,
  });

  void handleExportPDF() {
    final tripData = TripData(
      userName:
          FirebaseAuth.instance.currentUser?.displayName ?? 'Muhammad Talha',
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

    exportTripToPDF(
      tripData,
      options: PdfExportOptions(
        reportType: 'Trip Report',
        filePrefix: 'Trip_Report',
        userInfo: PdfExportUserInfo(
          fullName:
              FirebaseAuth.instance.currentUser?.displayName ?? 'Traveller',
          email: FirebaseAuth.instance.currentUser?.email ?? '',
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'unknown-user',
          profileImageUrl: FirebaseAuth.instance.currentUser?.photoURL,
        ),
        bookingDetails: {
          'Trip': 'Northern Pakistan Adventure',
          'Status': 'Confirmed',
        },
        routeDetails: {
          'Primary Route': 'Islamabad → Hunza Valley',
          'Distance': '615 km',
        },
        travelHistory: ['Islamabad', 'Hunza Valley', 'Naran Kaghan'],
        emergencyEvents: const [],
        groupMembers: const ['Muhammad Talha'],
      ),
    );
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
                            child: statCard(
                              statsLoaded
                                  ? '${stats['completed_trips'] ?? 0}'
                                  : '—',
                              'Places Visited',
                              _teal,
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: statCard(
                              statsLoaded
                                  ? '${stats['group_trips'] ?? 0}'
                                  : '—',
                              'Group Trips',
                              _orange,
                            ),
                          ),
                          SizedBox(
                            width: statWidth,
                            child: statCard(
                              statsLoaded
                                  ? '${stats['total_bookings'] ?? 0}'
                                  : '—',
                              'Trips Planned',
                              _violet,
                            ),
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
                        Container(
                          height: 8,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
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
                          color: const Color(0x33FDB913),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x66FDB913)),
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
                                color: const Color(0x1CFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0x2DFFFFFF),
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
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSettingsPage(),
                      ),
                    ),
                  ),
                  _NotificationsBadgeButton(context: context),
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
                    Icons.sos,
                    'Emergency SOS',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencySOSScreen(),
                      ),
                    ),
                  ),
                  settingsButton(
                    context,
                    Icons.contact_emergency_outlined,
                    'Emergency Contacts',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsPage(),
                      ),
                    ),
                  ),
                  if (isAdmin)
                    settingsButton(
                      context,
                      LucideIcons.layoutDashboard,
                      'Admin Dashboard',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardPage(),
                        ),
                      ),
                    ),
                  settingsButton(
                    context,
                    LucideIcons.fileDown,
                    'Export Trip Data (PDF)',
                    handleExportPDF,
                  ),
                  settingsButton(context, LucideIcons.logOut, 'Log Out', () {
                    SessionManager.clearAuthState(clearRememberMe: true);
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
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : 'Traveller';
    final email = user?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(email, style: const TextStyle(fontSize: 12, color: _mutedText)),
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
            color: Colors.black.withValues(alpha: 0.06),
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
        color: const Color(0x1CFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x2DFFFFFF)),
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
    final isSOS = label == 'Emergency SOS';
    final isContacts = label.contains('Emergency Contacts');
    final activeColor = isSOS
        ? const Color(0xFFB71C1C)
        : isContacts
        ? const Color(0xFFB71C1C)
        : isLogout
        ? const Color(0xFFFF4D6D)
        : null;
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
              color: activeColor ?? (isPdf ? _gold : _mutedText),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: activeColor ?? (isPdf ? _gold : _titleColor),
                fontWeight: (isPdf || isSOS || isContacts)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notifications button with live unread badge ──────────────────────────────
class _NotificationsBadgeButton extends StatefulWidget {
  final BuildContext context;
  const _NotificationsBadgeButton({required this.context});

  @override
  State<_NotificationsBadgeButton> createState() =>
      _NotificationsBadgeButtonState();
}

class _NotificationsBadgeButtonState extends State<_NotificationsBadgeButton> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _unread = NotificationService.instance.unreadCount;
    NotificationService.instance.addUnreadListener(_onUnreadChanged);
    _fetchCount();
  }

  void _onUnreadChanged() {
    if (mounted)
      setState(() => _unread = NotificationService.instance.unreadCount);
  }

  Future<void> _fetchCount() async {
    try {
      final resp = await ApiService.getRequest('/notifications/unread-count');
      if (!mounted) return;
      final count = resp['count'] as int? ?? 0;
      NotificationService.instance.setUnreadCount(count);
      setState(() => _unread = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    NotificationService.instance.removeUnreadListener(_onUnreadChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      ).then((_) => _fetchCount()),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        child: Row(
          children: [
            Badge(
              isLabelVisible: _unread > 0,
              label: Text(_unread > 99 ? '99+' : '$_unread'),
              child: const Icon(
                LucideIcons.bell,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
