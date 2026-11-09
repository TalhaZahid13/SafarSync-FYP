import 'package:flutter/material.dart';
import '../utils/app_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/pdf_export.dart'; // TripData, Destination, RouteData, Hotel, Restaurant, TripStats
import 'profile_settings.dart';
import 'admin_dashboard_page.dart';
import 'emergency_sos_screen.dart';
import 'emergency_contacts_page.dart';
import 'notifications_page.dart';
import 'transaction_history_page.dart';
import 'wishlist_page.dart';
import 'wellness_page.dart';
import '../utils/notification_service.dart';
import '../auth/login.dart';
import '../utils/responsive.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';
import '../utils/session_manager.dart';

// ── Profile page palette ──────────────────────────────────────────────────────
const Color _bgTop = Color(0xFFF8FFFE);
const Color _bgMid = Color(0xFFEFF9FA);
const Color _bgBottom = Color(0xFFE3F5F7);
const Color _teal = Color(0xFF2CAFBC);
const Color _orange = Color(0xFFFF8C42);
const Color _violet = Color(0xFF7C6FAF);
const Color _cyan = Color(0xFF00BCD4);
const Color _gold = Color(0xFFFFB830);
const Color _titleColor = Color(0xFF404745);
const Color _mutedText = Color(0xFF9A9E9D);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _cardOutline = Color(0x1A2CAFBC);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isAdmin = false;
  Map<String, dynamic> _stats = {};
  bool _statsLoaded = false;
  int? _appUserId;
  String? _profileName;
  String? _city;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isAdmin = await ApiService.getIsAdmin();
    final appUserId = await ApiService.getCurrentUserId();
    final statsResp = await ApiService.getRequest('/users/stats');
    final profileResp = await ApiService.getRequest('/users/profile');
    if (mounted) {
      String? name;
      String? city;
      String? photoUrl;
      if (profileResp['success'] == true) {
        final u = profileResp['user'] as Map<String, dynamic>? ?? {};
        name = u['full_name'] as String?;
        city = u['city'] as String?;
        photoUrl = u['profile_picture_url'] as String?;
      }
      setState(() {
        _isAdmin = isAdmin;
        _appUserId = appUserId;
        _stats = (statsResp['stats'] as Map<String, dynamic>?) ?? {};
        _statsLoaded = true;
        _profileName = name;
        _city = city;
        _photoUrl = photoUrl;
      });
    }
  }

  // Awaits the Settings screen and always re-fetches on return — the photo
  // upload persists immediately server-side (independent of Save), so this
  // is the only way the Profile page picks it up without an app restart.
  Future<void> _openSettingsAndRefresh(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
    );
    if (mounted) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return _ProfilePageView(
      isAdmin: _isAdmin,
      stats: _stats,
      statsLoaded: _statsLoaded,
      appUserId: _appUserId,
      profileName: _profileName,
      city: _city,
      photoUrl: _photoUrl,
      onEditProfile: () => _openSettingsAndRefresh(context),
    );
  }
}

class _ProfilePageView extends StatelessWidget {
  final bool isAdmin;
  final Map<String, dynamic> stats;
  final bool statsLoaded;
  final int? appUserId;
  final String? profileName;
  final String? city;
  final String? photoUrl;
  final VoidCallback onEditProfile;

  const _ProfilePageView({
    required this.isAdmin,
    required this.stats,
    required this.statsLoaded,
    required this.onEditProfile,
    this.appUserId,
    this.profileName,
    this.city,
    this.photoUrl,
  });

  void handleExportPDF() {
    final user = AppAuth.currentUser;
    final userName = user?.displayName ?? 'Traveller';

    // Use real stats from the backend; fall back to zeros if not yet loaded.
    final placesVisited = asInt(stats['total_bookings']) ?? 0;
    final tripsPlanned = asInt(stats['total_bookings']) ?? 0;
    final groupTrips = asInt(stats['group_bookings']) ?? 0;

    final tripData = TripData(
      userName: userName,
      tripName: 'SafarSync Travel Summary',
      destinations: const [],
      routes: const [],
      hotels: const [],
      restaurants: const [],
      stats: TripStats(
        placesVisited: placesVisited,
        badgesEarned: groupTrips,
        tripsPlanned: tripsPlanned,
      ),
    );

    exportTripToPDF(
      tripData,
      options: PdfExportOptions(
        reportType: 'Travel Report',
        filePrefix: 'Travel_Report',
        userInfo: PdfExportUserInfo(
          fullName: userName,
          email: user?.email ?? '',
          userId: appUserId != null
              ? 'ID-$appUserId'
              : (user?.uid ?? 'unknown'),
          profileImageUrl: user?.photoURL,
        ),
        bookingDetails: {
          'Total Bookings': '${stats['total_bookings'] ?? 0}',
          'Group Bookings': '${stats['group_bookings'] ?? 0}',
          'Active Tracking': '${stats['active_tracking'] ?? 0}',
        },
        travelHistory: [],
        emergencyEvents: const [],
        groupMembers: const [],
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
                    onEditProfile,
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
                    Icons.receipt_long,
                    'Transaction History',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryPage(),
                      ),
                    ),
                  ),
                  settingsButton(
                    context,
                    LucideIcons.heart,
                    'My Wishlist',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WishlistPage()),
                    ),
                  ),
                  settingsButton(
                    context,
                    LucideIcons.heartPulse,
                    'Wellness Center',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WellnessPage()),
                    ),
                  ),
                  settingsButton(
                    context,
                    LucideIcons.fileDown,
                    'Export Trip Data (PDF)',
                    handleExportPDF,
                  ),
                  settingsButton(
                    context,
                    LucideIcons.logOut,
                    'Log Out',
                    () async {
                      await SessionManager.clearAuthState(
                        clearRememberMe: true,
                      );
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
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
        image: (photoUrl != null && photoUrl!.isNotEmpty)
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: (photoUrl != null && photoUrl!.isNotEmpty)
          ? null
          : const Icon(LucideIcons.userRound, color: Colors.white, size: 30),
    );
  }

  Widget _profileMeta() {
    final user = AppAuth.currentUser;
    final name = (profileName?.isNotEmpty == true)
        ? profileName!
        : (user?.displayName?.isNotEmpty == true)
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
        if (city != null && city!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 12, color: _mutedText),
              const SizedBox(width: 4),
              Text(
                city!,
                style: const TextStyle(fontSize: 11, color: _mutedText),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _editButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onEditProfile,
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
    if (mounted) {
      setState(() => _unread = NotificationService.instance.unreadCount);
    }
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
