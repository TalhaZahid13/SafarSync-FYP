import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/api_service.dart';
import 'bookings_page.dart';
import 'group_bookings_page.dart';
import 'group_invitations_page.dart';
import 'groups_page.dart';
import 'notifications_page.dart';
import 'sasta_tour_page.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
const _kPrimary  = Color(0xFF1B5A6E);
const _kPrimary2 = Color(0xFF0D3B4D);
const _kAccent   = Color(0xFF2CAFBC);

// ─────────────────────────────────────────────────────────────────────────────
class SmartDashboardPage extends StatefulWidget {
  final int? tripId;
  const SmartDashboardPage({super.key, this.tripId});

  @override
  State<SmartDashboardPage> createState() => _SmartDashboardPageState();
}

class _SmartDashboardPageState extends State<SmartDashboardPage> {
  // ── Stats ──────────────────────────────────────────────────────────────────
  int _singleBookings    = 0;
  int _groupBookings     = 0;
  int _activeTrips       = 0;
  int _activeTracking    = 0;
  int _pendingInvites    = 0;
  bool _loading          = true;

  // ── User ───────────────────────────────────────────────────────────────────
  String _userName    = 'Traveler';
  String _initial     = 'T';

  @override
  void initState() {
    super.initState();
    _initUser();
    _load();
  }

  void _initUser() {
    final u = FirebaseAuth.instance.currentUser;
    final name = u?.displayName ?? u?.email?.split('@').first ?? 'Traveler';
    _userName = name;
    _initial  = name.isNotEmpty ? name[0].toUpperCase() : 'T';
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    try {
      final res = await Future.wait([
        ApiService.getRequest('/bookings/list'),
        ApiService.getRequest('/group-bookings/list'),
        ApiService.getRequest('/invitations/pending-count'),
      ]);

      final bookings = res[0]['bookings'] as List? ?? [];
      final groups   = res[1]['group_bookings'] as List? ?? [];
      final invRaw   = res[2]['pending_count'];

      if (!mounted) return;
      setState(() {
        _singleBookings = bookings.length;
        _groupBookings  = groups.length;
        _activeTrips    = groups.where((g) => (g as Map)['status'] == 'Active').length;
        _activeTracking = bookings.where((b) => (b as Map)['status'] == 'Active').length + _activeTrips;
        _pendingInvites = (invRaw is int) ? invRaw : int.tryParse(invRaw?.toString() ?? '0') ?? 0;
        _loading        = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _push(Widget page) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  ).then((_) => _load());

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        color: _kAccent,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Gradient header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                userName: _userName,
                initial: _initial,
                pendingInvites: _pendingInvites,
                onRefresh: _load,
                onNotifications: () => _push(const NotificationsPage()),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate(_buildBody()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_loading) {
      return [
        const SizedBox(height: 80),
        const Center(child: CircularProgressIndicator(color: _kAccent)),
      ];
    }

    return [
      const SizedBox(height: 24),

      // ── Stats ─────────────────────────────────────────────────────────────
      _label('Travel Overview'),
      const SizedBox(height: 12),
      // KEY FIX: mainAxisExtent gives cells a fixed height independent of
      // screen width, so content never overflows regardless of device size.
      GridView.custom(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 104, // ← fixed pixels, NOT aspect ratio
        ),
        childrenDelegate: SliverChildListDelegate([
          _StatCard(
            label: 'Total Bookings',
            value: _singleBookings,
            icon: Icons.bookmark_rounded,
            color: const Color(0xFF1565C0),
            onTap: () => _push(const BookingsPage()),
          ),
          _StatCard(
            label: 'Group Trips',
            value: _groupBookings,
            icon: Icons.groups_rounded,
            color: const Color(0xFF6A1B9A),
            onTap: () => _push(const GroupBookingsPage()),
          ),
          _StatCard(
            label: 'Active Trips',
            value: _activeTrips,
            icon: Icons.route_rounded,
            color: const Color(0xFF2E7D32),
            onTap: () => _push(const GroupBookingsPage()),
          ),
          _StatCard(
            label: 'Locations Shared',
            value: _activeTracking,
            icon: Icons.share_location_rounded,
            color: const Color(0xFFF57C00),
            onTap: null,
          ),
        ]),
      ),
      const SizedBox(height: 24),

      // ── Invitation banner ─────────────────────────────────────────────────
      if (_pendingInvites > 0) ...[
        _InviteBanner(
          count: _pendingInvites,
          onTap: () => _push(const GroupInvitationsPage()),
        ),
        const SizedBox(height: 24),
      ],

      // ── Quick actions ──────────────────────────────────────────────────────
      _label('Quick Actions'),
      const SizedBox(height: 12),
      _QuickActions(
        onNewBooking:    () => _push(const CreateBookingScreen()),
        onNewGroup:      () => _push(const CreateGroupBookingScreen()),
        onAllBookings:   () => _push(const BookingsPage()),
        onGroupTrips:    () => _push(const GroupBookingsPage()),
        onInvitations:   () => _push(const GroupInvitationsPage()),
        onSastaTours:    () => _push(const SastaTourPage()),
        onBudgetPlanner: () => _push(const BudgetPlannerPage()),
        onGroups:        () => _push(const GroupsPage()),
        pendingInvites:  _pendingInvites,
      ),
      const SizedBox(height: 24),

      // ── Live tracking ─────────────────────────────────────────────────────
      _label('Live Tracking'),
      const SizedBox(height: 12),
      _TrackingCard(
        count: _activeTracking,
        onTap: _activeTracking > 0 ? () => _push(const GroupBookingsPage()) : null,
      ),
    ];
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
Widget _label(String t) => Text(
  t,
  style: const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1B2A35),
    letterSpacing: 0.2,
  ),
);

// ─── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String userName;
  final String initial;
  final int pendingInvites;
  final VoidCallback onRefresh;
  final VoidCallback onNotifications;

  const _Header({
    required this.userName,
    required this.initial,
    required this.pendingInvites,
    required this.onRefresh,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      // No extra top padding — SafeArea in App already handles status bar
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),

          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Assalam-o-Alaikum,',
                  style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.2),
                ),
                const SizedBox(height: 1),
                Text(
                  '$firstName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                const Text(
                  "Here's your trip overview",
                  style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.2),
                ),
              ],
            ),
          ),

          // Notification icon + badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                onPressed: onNotifications,
                tooltip: 'Notifications',
                padding: const EdgeInsets.all(8),
              ),
              if (pendingInvites > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5252),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        pendingInvites > 9 ? '9+' : '$pendingInvites',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 20),
            onPressed: onRefresh,
            tooltip: 'Refresh',
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ─────────────────────────────────────────────────────────────────
// mainAxisExtent: 104px  |  padding: horiz 14, vert 10  |  available: 84px
// Layout (top→bottom): Row(icon 32) + SizedBox(8) + FittedBox(26) + Text(12) = 78px < 84px ✓
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ← prevents the column from expanding
            children: [
              // Icon row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 8),
              // Number — FittedBox scales down on tiny screens
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    height: 1.0, // ← removes hidden extra line-height
                  ),
                ),
              ),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invitation banner ─────────────────────────────────────────────────────────
class _InviteBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _InviteBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8F0),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mail_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Pending Invitation${count == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Tap to view and respond',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.orange.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onNewBooking;
  final VoidCallback onNewGroup;
  final VoidCallback onAllBookings;
  final VoidCallback onGroupTrips;
  final VoidCallback onInvitations;
  final VoidCallback onSastaTours;
  final VoidCallback onBudgetPlanner;
  final VoidCallback onGroups;
  final int pendingInvites;

  const _QuickActions({
    required this.onNewBooking,
    required this.onNewGroup,
    required this.onAllBookings,
    required this.onGroupTrips,
    required this.onInvitations,
    required this.onSastaTours,
    required this.onBudgetPlanner,
    required this.onGroups,
    required this.pendingInvites,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Primary row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _PrimaryCard(
                icon: Icons.bookmark_add_rounded,
                label: 'New Booking',
                sub: 'Plan a solo trip',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: onNewBooking,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryCard(
                icon: Icons.group_add_rounded,
                label: 'New Group Trip',
                sub: 'Travel together',
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: onNewGroup,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Secondary row ────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SecondaryCard(
                icon: Icons.list_alt_rounded,
                label: 'All Bookings',
                color: const Color(0xFF00695C),
                onTap: onAllBookings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryCard(
                icon: Icons.people_rounded,
                label: 'Group Trips',
                color: const Color(0xFF283593),
                onTap: onGroupTrips,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Invitations full-width ───────────────────────────────────────────
        _SecondaryCard(
          icon: Icons.mail_rounded,
          label: pendingInvites > 0
              ? 'Trip Invitations ($pendingInvites pending)'
              : 'Trip Invitations',
          color: pendingInvites > 0 ? Colors.orange.shade700 : Colors.blueGrey,
          onTap: onInvitations,
          badge: pendingInvites > 0 ? pendingInvites : null,
        ),
        const SizedBox(height: 12),

        // ── Travel Groups full-width ─────────────────────────────────────────
        _SecondaryCard(
          icon: Icons.group_outlined,
          label: 'Travel Groups',
          color: const Color(0xFF00796B),
          onTap: onGroups,
        ),
        const SizedBox(height: 12),

        // ── Budget / Sasta Tours row ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SecondaryCard(
                icon: Icons.local_offer_rounded,
                label: 'Sasta Tours',
                color: const Color(0xFFF59E0B),
                onTap: onSastaTours,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Budget Planner',
                color: const Color(0xFF0D47A1),
                onTap: onBudgetPlanner,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Primary action card (gradient) ────────────────────────────────────────────
class _PrimaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PrimaryCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 24),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Secondary action card (white) ─────────────────────────────────────────────
class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _SecondaryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: badge != null ? Colors.orange.shade200 : const Color(0xFFEEEEEE),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Tracking card ────────────────────────────────────────────────────────
class _TrackingCard extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _TrackingCard({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = count > 0;

    return Material(
      color: on ? const Color(0xFFF0FFF4) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? Colors.green.shade200 : const Color(0xFFEEEEEE),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Dot indicator
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: on ? Colors.green : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_location_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      on ? 'Tracking Active' : 'No Active Tracking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: on ? Colors.green.shade800 : Colors.grey.shade700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      on
                          ? '$count active session${count > 1 ? 's' : ''} — tap to open'
                          : 'Start a group trip to enable live tracking',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (on) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
