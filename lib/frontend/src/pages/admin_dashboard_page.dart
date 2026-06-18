import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/api_service.dart';

// ─── Colour constants ─────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF1A237E); // deep indigo
const _kAccent = Color(0xFF3949AB);

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  // ── Tab controller ──────────────────────────────────────────────────────────
  late final TabController _tabs;

  // ── Admin identity ───────────────────────────────────────────────────────────
  String _adminName = 'Admin';
  bool _isSuperAdmin = false;

  // ── Data ────────────────────────────────────────────────────────────────────
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _alerts = [];

  bool _loadingStats = true;
  bool _loadingUsers = true;
  bool _loadingTrips = true;
  bool _loadingAlerts = true;

  String? _userSearch;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) _loadTabIfNeeded(_tabs.index);
      });
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    // Support both pure admin JWT (AdminLoginPage) and user-admin JWT (is_admin=1).
    final isAdmin = await ApiService.getIsAdmin();
    if (!mounted) return;
    if (!isAdmin) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied: Admin privileges required')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('admin_role') ?? 'moderator';
    final name = prefs.getString('admin_full_name')
        ?? prefs.getString('user_full_name')
        ?? 'Admin';

    if (mounted) {
      setState(() {
        _adminName = name;
        _isSuperAdmin = role == 'super_admin';
      });
    }
    _loadAll();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([
      _loadStats(),
      _loadUsers(),
      _loadTrips(),
      _loadAlerts(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final r = await ApiService.adminGetRequest('/admin/dashboard');
      if (mounted && r['success'] == true) {
        setState(() {
          _stats = Map<String, dynamic>.from(r['stats'] ?? {});
          _loadingStats = false;
        });
      } else {
        if (mounted) setState(() => _loadingStats = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final r = await ApiService.adminGetRequest('/admin/users');
      if (mounted && r['success'] == true) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(
            (r['users'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
          );
          _loadingUsers = false;
        });
      } else {
        if (mounted) setState(() => _loadingUsers = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadTrips() async {
    setState(() => _loadingTrips = true);
    try {
      final r = await ApiService.adminGetRequest('/admin/trips');
      if (mounted && r['success'] == true) {
        setState(() {
          _trips = List<Map<String, dynamic>>.from(
            (r['trips'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
          );
          _loadingTrips = false;
        });
      } else {
        if (mounted) setState(() => _loadingTrips = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTrips = false);
    }
  }

  Future<void> _loadAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final r = await ApiService.adminGetRequest('/admin/emergency-alerts');
      if (mounted && r['success'] == true) {
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(
            (r['alerts'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
          );
          _loadingAlerts = false;
        });
      } else {
        if (mounted) setState(() => _loadingAlerts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  void _loadTabIfNeeded(int index) {
    switch (index) {
      case 1: if (_users.isEmpty) _loadUsers(); break;
      case 2: if (_trips.isEmpty) _loadTrips(); break;
      case 3: if (_alerts.isEmpty) _loadAlerts(); break;
    }
  }

  // ── User moderation actions ───────────────────────────────────────────────
  Future<void> _blockUser(int userId) async {
    final r = await ApiService.adminPutRequest('/admin/users/$userId/block', {});
    if (!mounted) return;
    _snack(r['success'] == true ? 'User blocked' : (r['message'] ?? 'Failed'));
    if (r['success'] == true) _loadUsers();
  }

  Future<void> _unblockUser(int userId) async {
    final r = await ApiService.adminPutRequest('/admin/users/$userId/unblock', {});
    if (!mounted) return;
    _snack(r['success'] == true ? 'User unblocked' : (r['message'] ?? 'Failed'));
    if (r['success'] == true) _loadUsers();
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('This will permanently delete the user and all their data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await ApiService.adminDeleteRequest('/admin/users/$userId');
    if (!mounted) return;
    _snack(r['success'] == true ? 'User deleted' : (r['message'] ?? 'Failed'));
    if (r['success'] == true) _loadUsers();
  }

  Future<void> _makeAdmin(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: const Text('Grant this user admin privileges in the users table?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await ApiService.adminPutRequest('/admin/users/$userId/make-admin', {});
    if (!mounted) return;
    _snack(r['success'] == true ? 'User promoted to admin' : (r['message'] ?? 'Failed'));
    if (r['success'] == true) _loadUsers();
  }

  Future<void> _broadcastNotification(String title, String message) async {
    final r = await ApiService.adminPostRequest(
        '/admin/broadcast-notification', {'title': title, 'message': message});
    if (!mounted) return;
    _snack(r['success'] == true
        ? 'Broadcast sent to ${r['sent_to'] ?? 0} users'
        : (r['message'] ?? 'Broadcast failed'));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Resolve alert from admin panel ────────────────────────────────────────
  Future<void> _resolveAlert(int alertId) async {
    final r = await ApiService.adminPutRequest(
        '/admin/emergency-alerts/$alertId/resolve', {});
    if (!mounted) return;
    if (r['success'] == true) {
      _loadAlerts();
      _loadStats();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert resolved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                Text(_adminName,
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _isSuperAdmin ? Colors.amber : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isSuperAdmin ? 'SUPER ADMIN' : 'MODERATOR',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _isSuperAdmin ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all',
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: (_stats['active_sos'] ?? 0) > 0,
                label: Text((_stats['active_sos'] ?? 0).toString()),
                child: const Icon(Icons.dashboard),
              ),
              text: 'Overview',
            ),
            const Tab(icon: Icon(Icons.people), text: 'Users'),
            const Tab(icon: Icon(Icons.map), text: 'Trips'),
            Tab(
              icon: Badge(
                isLabelVisible: _alerts
                    .where((a) => a['status'] == 'Active')
                    .isNotEmpty,
                label: Text(
                  _alerts.where((a) => a['status'] == 'Active').length.toString(),
                ),
                child: const Icon(Icons.emergency),
              ),
              text: 'Alerts',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: (_stats['active_sos'] ?? 0) > 0,
                label: Text((_stats['active_sos'] ?? 0).toString()),
                backgroundColor: Colors.red,
                child: const Icon(Icons.location_on),
              ),
              text: 'Live Map',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(
            stats: _stats,
            loading: _loadingStats,
            isSuperAdmin: _isSuperAdmin,
            onBroadcast: _broadcastNotification,
          ),
          _UsersTab(
            users: _users,
            loading: _loadingUsers,
            searchCtrl: _searchCtrl,
            search: _userSearch,
            onSearch: (v) => setState(() => _userSearch = v.isEmpty ? null : v),
            onRefresh: _loadUsers,
            isSuperAdmin: _isSuperAdmin,
            onBlock: _blockUser,
            onUnblock: _unblockUser,
            onDelete: _deleteUser,
            onMakeAdmin: _makeAdmin,
          ),
          _TripsTab(trips: _trips, loading: _loadingTrips, onRefresh: _loadTrips),
          _AlertsTab(
            alerts: _alerts,
            loading: _loadingAlerts,
            onResolve: _resolveAlert,
            onRefresh: _loadAlerts,
          ),
          const _EmergencyMapTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;
  final bool isSuperAdmin;
  final Future<void> Function(String title, String message) onBroadcast;

  const _OverviewTab({
    required this.stats,
    required this.loading,
    required this.isSuperAdmin,
    required this.onBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    final cards = [
      _StatDef('Total Users',         stats['total_users'],              Icons.people,          Colors.teal),
      _StatDef('Group Bookings',       stats['total_group_bookings'],     Icons.groups,          Colors.purple),
      _StatDef('Active Trips',         stats['active_trips'],             Icons.map,             Colors.green),
      _StatDef('Emergency Alerts',     stats['active_sos'],               Icons.emergency,       Colors.red),
      _StatDef('Single Bookings',      stats['total_bookings'],           Icons.bookmark,        Colors.blue),
      _StatDef('Live Sessions',        stats['active_tracking_sessions'], Icons.location_on,     Colors.orange),
      _StatDef('AI Chats',             stats['ai_chats'],                 Icons.chat_bubble,     Colors.indigo),
      _StatDef('System Health',        stats['system_health'],            Icons.health_and_safety, Colors.cyan),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Platform Overview'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (_, i) => _BigStatCard(def: cards[i]),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Status Breakdown'),
          const SizedBox(height: 12),
          _StatusBreakdown(stats: stats),
          if (isSuperAdmin) ...[
            const SizedBox(height: 24),
            _sectionTitle('Broadcast Notification'),
            const SizedBox(height: 12),
            _BroadcastCard(onBroadcast: onBroadcast),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Broadcast card (super_admin only) ─────────────────────────────────────────
class _BroadcastCard extends StatefulWidget {
  final Future<void> Function(String, String) onBroadcast;
  const _BroadcastCard({required this.onBroadcast});

  @override
  State<_BroadcastCard> createState() => _BroadcastCardState();
}

class _BroadcastCardState extends State<_BroadcastCard> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _titleCtrl.text.trim();
    final m = _msgCtrl.text.trim();
    if (t.isEmpty || m.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title and message required')));
      return;
    }
    setState(() => _sending = true);
    await widget.onBroadcast(t, m);
    if (mounted) {
      _titleCtrl.clear();
      _msgCtrl.clear();
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.indigo.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                Text('Send to All Users',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Notification Title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _msgCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Message',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Broadcast'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatDef {
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;
  const _StatDef(this.label, this.value, this.icon, this.color);
}

class _BigStatCard extends StatelessWidget {
  final _StatDef def;
  const _BigStatCard({required this.def});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: def.color.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(def.icon, color: def.color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: def.color.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    def.value?.toString() ?? '—',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: def.color,
                    ),
                  ),
                ),
                Text(
                  def.label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status breakdown (horizontal bar) ─────────────────────────────────────────
class _StatusBreakdown extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatusBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = _num(stats['total_group_bookings']);
    final active = _num(stats['active_trips']);
    final sos = _num(stats['active_sos']);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BarRow('Active Trips',     active, total == 0 ? 0 : active / total,    Colors.green),
            const SizedBox(height: 10),
            _BarRow('Emergency Alerts', sos,    sos == 0   ? 0 : (sos / 20).clamp(0, 1.0), Colors.red),
            const SizedBox(height: 10),
            _BarRow('Total Users',     _num(stats['total_users']),
                    _num(stats['total_users']) == 0 ? 0 :
                    (_num(stats['total_users']) / 100).clamp(0, 1.0), Colors.teal),
          ],
        ),
      ),
    );
  }

  int _num(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final double fraction;
  final Color color;
  const _BarRow(this.label, this.value, this.fraction, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(value.toString(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─── Users tab ────────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final bool loading;
  final TextEditingController searchCtrl;
  final String? search;
  final void Function(String) onSearch;
  final VoidCallback onRefresh;
  final bool isSuperAdmin;
  final Future<void> Function(int) onBlock;
  final Future<void> Function(int) onUnblock;
  final Future<void> Function(int) onDelete;
  final Future<void> Function(int) onMakeAdmin;

  const _UsersTab({
    required this.users,
    required this.loading,
    required this.searchCtrl,
    required this.search,
    required this.onSearch,
    required this.onRefresh,
    required this.isSuperAdmin,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
    required this.onMakeAdmin,
  });

  List<Map<String, dynamic>> get _filtered {
    if (search == null || search!.isEmpty) return users;
    final q = search!.toLowerCase();
    return users
        .where((u) =>
            (u['full_name'] as String? ?? '').toLowerCase().contains(q) ||
            (u['email'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    final list = _filtered;

    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchCtrl.clear();
                        onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // ── Count + refresh ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text('${list.length} users',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh'),
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                    foregroundColor: _kAccent,
                    padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: list.isEmpty
              ? _emptyState(Icons.people_outline, 'No users found')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _UserTile(
                    user: list[i],
                    isSuperAdmin: isSuperAdmin,
                    onBlock: onBlock,
                    onUnblock: onUnblock,
                    onDelete: onDelete,
                    onMakeAdmin: onMakeAdmin,
                  ),
                ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSuperAdmin;
  final Future<void> Function(int) onBlock;
  final Future<void> Function(int) onUnblock;
  final Future<void> Function(int) onDelete;
  final Future<void> Function(int) onMakeAdmin;

  const _UserTile({
    required this.user,
    required this.isSuperAdmin,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
    required this.onMakeAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['full_name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final single = user['single_bookings'] ?? 0;
    final groups = user['group_trips'] ?? 0;
    final userId = user['user_id'] as int? ?? 0;
    final isBlocked = user['is_blocked'] == true || user['is_blocked'] == 1;
    final isAdmin = user['is_admin'] == true || user['is_admin'] == 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isBlocked ? Colors.red.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: isBlocked
                  ? Colors.red.withValues(alpha: 0.15)
                  : _kAccent.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: isBlocked ? Colors.red : _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('admin',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (isBlocked) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('blocked',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(Icons.bookmark, '$single', Colors.blue),
                      const SizedBox(width: 6),
                      _chip(Icons.groups, '$groups', Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            // Actions popup
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              onSelected: (action) {
                switch (action) {
                  case 'block': onBlock(userId); break;
                  case 'unblock': onUnblock(userId); break;
                  case 'delete': onDelete(userId); break;
                  case 'make_admin': onMakeAdmin(userId); break;
                }
              },
              itemBuilder: (_) => [
                if (!isBlocked)
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(children: [
                      Icon(Icons.block, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Block User'),
                    ]),
                  )
                else
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Unblock User'),
                    ]),
                  ),
                if (isSuperAdmin && !isAdmin)
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Row(children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Make Admin'),
                    ]),
                  ),
                if (isSuperAdmin)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete User',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Trips tab ────────────────────────────────────────────────────────────────
class _TripsTab extends StatelessWidget {
  final List<Map<String, dynamic>> trips;
  final bool loading;
  final VoidCallback onRefresh;

  const _TripsTab(
      {required this.trips, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (trips.isEmpty) {
      return _emptyState(Icons.map_outlined, 'No trips yet');
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _TripTile(trip: trips[i]),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripTile({required this.trip});

  static const _statusColors = {
    'Active': Colors.green,
    'Planning': Colors.orange,
    'Completed': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final name = trip['trip_name'] as String? ?? 'Unnamed Trip';
    final status = trip['status'] as String? ?? 'Unknown';
    final organizer = trip['organizer'] as String? ?? '—';
    final members = trip['member_count'] ?? 0;
    final start = _fmtDate(trip['start_date']);
    final end = _fmtDate(trip['end_date']);
    final created = _fmtDate(trip['created_at']);
    final color = _statusColors[status] ?? Colors.grey;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _StatusChip(status: status, color: color),
              ],
            ),
            const SizedBox(height: 8),
            // ── Organizer ────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.person, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(organizer,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.people, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$members member${members == 1 ? '' : 's'}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            // ── Dates ────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  start == '—' ? 'Created $created' : '$start → $end',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      final d = DateTime.parse(v.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '—';
    }
  }
}

// ─── Alerts tab ───────────────────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final bool loading;
  final Future<void> Function(int) onResolve;
  final VoidCallback onRefresh;

  const _AlertsTab({
    required this.alerts,
    required this.loading,
    required this.onResolve,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    final active = alerts.where((a) => a['status'] == 'Active').toList();
    final rest = alerts.where((a) => a['status'] != 'Active').toList();

    if (alerts.isEmpty) {
      return _emptyState(Icons.check_circle_outline, 'No emergency alerts');
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isNotEmpty) ...[
            _sectionTitle('Active Alerts (${active.length})'),
            const SizedBox(height: 8),
            ...active.map((a) => _AlertTile(
                  alert: a,
                  onResolve: onResolve,
                )),
            const SizedBox(height: 20),
          ],
          if (rest.isNotEmpty) ...[
            _sectionTitle('Past Alerts'),
            const SizedBox(height: 8),
            ...rest.map((a) => _AlertTile(alert: a, onResolve: onResolve)),
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Future<void> Function(int) onResolve;

  const _AlertTile({required this.alert, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final status = alert['status'] as String? ?? 'Unknown';
    final isActive = status == 'Active';
    final name = alert['full_name'] as String? ?? 'Unknown';
    final email = alert['email'] as String? ?? '';
    final message = alert['message'] as String?;
    final tripName = alert['trip_name'] as String?;
    final lat = (alert['latitude'] as num?)?.toStringAsFixed(4) ?? '—';
    final lng = (alert['longitude'] as num?)?.toStringAsFixed(4) ?? '—';
    final created = _timeAgo(alert['created_at']);
    final id = alert['id'] as int? ?? 0;

    return Card(
      elevation: 0,
      color: isActive ? Colors.red.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.red.shade300 : Colors.transparent,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isActive
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  child: Icon(
                    isActive ? Icons.sos : Icons.check_circle,
                    color: isActive ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(email,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _StatusChip(
                  status: status,
                  color: isActive
                      ? Colors.red
                      : status == 'Resolved'
                          ? Colors.green
                          : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Message ──────────────────────────────────────────────────
            if (message != null && message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(message,
                    style: const TextStyle(fontSize: 13)),
              ),
            const SizedBox(height: 6),
            // ── Meta ──────────────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _metaItem(Icons.location_on, '$lat, $lng'),
                if (tripName != null)
                  _metaItem(Icons.directions_bus, tripName),
                _metaItem(Icons.access_time, created),
              ],
            ),
            // ── Resolve button ────────────────────────────────────────────
            if (isActive) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Mark Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => onResolve(id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 3),
        Text(text,
            style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  static String _timeAgo(dynamic v) {
    if (v == null) return '—';
    try {
      final t = DateTime.parse(v.toString()).toLocal();
      final diff = DateTime.now().difference(t);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${t.day}/${t.month}/${t.year}';
    } catch (_) {
      return '—';
    }
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Emergency Map tab data models ───────────────────────────────────────────
const _kMemberColors = [
  Color(0xFF1565C0), // blue
  Color(0xFF2E7D32), // green
  Color(0xFFF57C00), // orange
  Color(0xFF6A1B9A), // purple
  Color(0xFF00695C), // teal
  Color(0xFF880E4F), // pink
  Color(0xFF37474F), // blue-grey
  Color(0xFF4E342E), // brown
];

class _MapMember {
  final int userId;
  final String name;
  LatLng? position;
  DateTime? lastSeen;
  final int colorIndex;

  _MapMember({
    required this.userId,
    required this.name,
    this.position,
    this.lastSeen,
    required this.colorIndex,
  });
}

class _SosAlert {
  final int alertId;
  final int userId;
  final String userName;
  final String? userPhone;
  LatLng position;
  final String? tripName;
  final int? tripId;
  final String? tripType;
  final List<_MapMember> groupMembers;

  _SosAlert({
    required this.alertId,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.position,
    this.tripName,
    this.tripId,
    this.tripType,
    required this.groupMembers,
  });
}

// ─── Emergency Map tab ────────────────────────────────────────────────────────
class _EmergencyMapTab extends StatefulWidget {
  const _EmergencyMapTab();

  @override
  State<_EmergencyMapTab> createState() => _EmergencyMapTabState();
}

class _EmergencyMapTabState extends State<_EmergencyMapTab>
    with AutomaticKeepAliveClientMixin {
  final _mapCtrl = MapController();
  io.Socket? _socket;
  Timer? _pollTimer;

  List<_SosAlert> _alerts = [];
  bool _loading = true;
  _SosAlert? _focused;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _connectSocket();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final resp = await ApiService.getRequest('/admin/emergency-map');
      if (!mounted) return;
      final rawList = resp['alerts'] as List? ?? [];
      final alerts = rawList.asMap().entries.map((entry) {
        final a = Map<String, dynamic>.from(entry.value as Map);
        final rawMembers = a['group_members'] as List? ?? [];
        final members = rawMembers.asMap().entries.map((me) {
          final m = Map<String, dynamic>.from(me.value as Map);
          final mLat = (m['latitude'] as num?)?.toDouble();
          final mLng = (m['longitude'] as num?)?.toDouble();
          return _MapMember(
            userId: (m['user_id'] as num?)?.toInt() ?? 0,
            name: m['user_name'] as String? ?? 'Member',
            position: (mLat != null && mLng != null && mLat != 0 && mLng != 0)
                ? LatLng(mLat, mLng)
                : null,
            lastSeen: _parseDate(m['last_seen']),
            colorIndex: me.key % _kMemberColors.length,
          );
        }).toList();

        final lat = (a['latitude'] as num?)?.toDouble() ?? 30.3753;
        final lng = (a['longitude'] as num?)?.toDouble() ?? 69.3451;

        return _SosAlert(
          alertId: (a['id'] as num?)?.toInt() ?? 0,
          userId: (a['user_id'] as num?)?.toInt() ?? 0,
          userName: a['user_name'] as String? ?? 'Unknown',
          userPhone: a['user_phone'] as String?,
          position: LatLng(lat, lng),
          tripName: a['trip_name'] as String?,
          tripId: (a['trip_id'] as num?)?.toInt(),
          tripType: a['trip_type'] as String?,
          groupMembers: members,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _loading = false;
        if (_focused == null && alerts.isNotEmpty) {
          _focused = alerts.first;
          WidgetsBinding.instance.addPostFrameCallback((_) => _centerOn(alerts.first.position, 13.0));
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Socket ─────────────────────────────────────────────────────────────────
  void _connectSocket() {
    _socket = io.io(
      ApiService.socketUrl,
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join:emergency-admin');
    });

    // Live group member position update
    _socket!.on('location:group-updated', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      final rawUserId = d['user_id'];
      final rawGroupId = d['group_booking_id'];
      final lat = (d['latitude'] as num?)?.toDouble();
      final lng = (d['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final newPos = LatLng(lat, lng);

      setState(() {
        for (final alert in _alerts) {
          // Update group members in matching group
          if (_idMatch(alert.tripId, rawGroupId)) {
            for (final member in alert.groupMembers) {
              if (_idMatch(member.userId, rawUserId)) {
                member.position = newPos;
                member.lastSeen = DateTime.now();
              }
            }
          }
          // Also update the SOS user's own marker if they broadcast location
          if (_idMatch(alert.userId, rawUserId)) {
            alert.position = newPos;
          }
        }
      });
    });

    // New SOS — reload to pick up new alert + group members
    _socket!.on('emergency:sos', (_) { if (mounted) _load(); });

    // Alert resolved — remove from map
    _socket!.on('emergency:resolved', (data) {
      if (!mounted) return;
      final d = Map<String, dynamic>.from(data as Map);
      final resolvedId = d['alert_id'];
      setState(() {
        _alerts.removeWhere((a) => _idMatch(a.alertId, resolvedId));
        if (_focused != null && _idMatch(_focused!.alertId, resolvedId)) {
          _focused = _alerts.isNotEmpty ? _alerts.first : null;
        }
      });
    });
  }

  // ── Map helpers ────────────────────────────────────────────────────────────
  void _centerOn(LatLng pos, double zoom) {
    try { _mapCtrl.move(pos, zoom); } catch (_) {}
  }

  void _fitAll() {
    final pts = <LatLng>[];
    for (final a in _alerts) {
      pts.add(a.position);
      for (final m in a.groupMembers) {
        if (m.position != null) pts.add(m.position!);
      }
    }
    if (pts.isEmpty) return;
    if (pts.length == 1) { _centerOn(pts.first, 13.0); return; }
    try {
      final bounds = LatLngBounds.fromPoints(pts);
      _mapCtrl.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ));
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (_alerts.isEmpty) {
      return _emptyState(Icons.crisis_alert, 'No active SOS alerts\nMap will update automatically');
    }

    return Column(
      children: [
        // ── Map ─────────────────────────────────────────────────────────────
        Expanded(
          flex: 68,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _focused?.position ?? const LatLng(30.3753, 69.3451),
                  initialZoom: 12.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.safarsync.app',
                  ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),

              // Map controls
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    _mapBtn(Icons.fit_screen, 'fit_all', 'Fit all', _fitAll),
                    const SizedBox(height: 6),
                    _mapBtn(Icons.refresh, 'refresh_map', 'Refresh', _load),
                  ],
                ),
              ),

              // Live indicator
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.93),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),

              // Legend
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.93),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendRow(Icons.sos, Colors.red, 'SOS User'),
                      const SizedBox(height: 4),
                      _legendRow(Icons.circle, _kMemberColors[0], 'Group Member'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Active alerts panel ──────────────────────────────────────────────
        Container(
          color: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.emergency, color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Active Alerts (${_alerts.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 13),
                      label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                      onPressed: _load,
                      style: TextButton.styleFrom(
                        foregroundColor: _kAccent,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _AlertMapCard(
                    alert: _alerts[i],
                    isSelected: _focused?.alertId == _alerts[i].alertId,
                    onTap: () {
                      setState(() => _focused = _alerts[i]);
                      _centerOn(_alerts[i].position, 14.0);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Marker builders ────────────────────────────────────────────────────────
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final alert in _alerts) {
      final isFocused = _focused?.alertId == alert.alertId;

      // SOS user marker (red, larger when focused)
      markers.add(Marker(
        point: alert.position,
        width: isFocused ? 64 : 52,
        height: isFocused ? 64 : 52,
        child: GestureDetector(
          onTap: () {
            setState(() => _focused = alert);
            _centerOn(alert.position, 14.0);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isFocused)
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: isFocused ? 4 : 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));

      // Group member markers
      for (final member in alert.groupMembers) {
        if (member.position == null) continue;
        final color = _kMemberColors[member.colorIndex];
        final initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

        markers.add(Marker(
          point: member.position!,
          width: 46,
          height: 46,
          child: Tooltip(
            message: member.name,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }
    return markers;
  }

  Widget _mapBtn(IconData icon, String tag, String tip, VoidCallback onTap) =>
      FloatingActionButton.small(
        heroTag: tag,
        onPressed: onTap,
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        tooltip: tip,
        child: Icon(icon, size: 18),
      );

  Widget _legendRow(IconData icon, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  static bool _idMatch(dynamic a, dynamic b) =>
      a != null && b != null && a.toString() == b.toString();

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }
}

// ── Alert card in bottom panel ────────────────────────────────────────────────
class _AlertMapCard extends StatelessWidget {
  final _SosAlert alert;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlertMapCard({
    required this.alert,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final liveMemberCount =
        alert.groupMembers.where((m) => m.position != null).length;
    final totalMembers = alert.groupMembers.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.red.shade400 : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.red.withValues(alpha: 0.15), blurRadius: 6)]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.sos, color: Colors.red, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    alert.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (alert.tripName != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.directions_bus, size: 11, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.tripName!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (alert.tripType == 'group') ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 11,
                    color: liveMemberCount > 0 ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$liveMemberCount/$totalMembers on map',
                    style: TextStyle(
                      fontSize: 11,
                      color: liveMemberCount > 0 ? Colors.green.shade700 : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 11, color: Colors.grey),
                const SizedBox(width: 3),
                Text(
                  '${alert.position.latitude.toStringAsFixed(4)}, ${alert.position.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
Widget _sectionTitle(String title) => Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

Widget _emptyState(IconData icon, String msg) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
