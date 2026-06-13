import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import '../utils/notification_service.dart';

// ─── Type config: icon + colour per notification type ────────────────────────
const _kTypeConfig = <String, _TypeDef>{
  'emergency_sos_sent':  _TypeDef(Icons.sos,              Color(0xFFB71C1C), 'SOS Sent'),
  'emergency_sos_admin': _TypeDef(Icons.emergency,         Color(0xFFB71C1C), 'Emergency'),
  'emergency_resolved':  _TypeDef(Icons.check_circle,      Color(0xFF2E7D32), 'Resolved'),
  'group_invitation':    _TypeDef(Icons.group_add,          Color(0xFF6A1B9A), 'Invitation'),
  'invitation_accepted': _TypeDef(Icons.how_to_reg,         Color(0xFF1565C0), 'Accepted'),
  'invitation_declined': _TypeDef(Icons.person_off,         Color(0xFF616161), 'Declined'),
  'member_joined':       _TypeDef(Icons.person_add_alt,     Color(0xFF0277BD), 'Joined'),
};

class _TypeDef {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeDef(this.icon, this.color, this.label);
}

_TypeDef _defFor(String? type) =>
    _kTypeConfig[type] ??
    const _TypeDef(Icons.notifications, Color(0xFF1A237E), 'Notification');

// ─── Page ─────────────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiService.getRequest('/notifications?limit=50');
      if (!mounted) return;
      final raw = resp['notifications'] as List? ?? [];
      setState(() {
        _notifications = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
      // Reset badge
      NotificationService.instance.clearUnread();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int notificationId, int index) async {
    try {
      await ApiService.putRequest('/notifications/$notificationId/read', {});
      if (!mounted) return;
      setState(() {
        _notifications[index] = {
          ..._notifications[index],
          'is_read': true,
        };
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ApiService.putRequest('/notifications/read/all', {});
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'is_read': true})
            .toList();
        _markingAll = false;
      });
      NotificationService.instance.clearUnread();
    } catch (_) {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _delete(int notificationId, int index) async {
    try {
      await ApiService.deleteRequest('/notifications/$notificationId');
      if (!mounted) return;
      setState(() => _notifications.removeAt(index));
    } catch (_) {}
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] == false || n['is_read'] == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: const Text('Notifications'),
        ),
        actions: [
          if (unread > 0)
            _markingAll
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _markAllRead,
                    child: const Text('Mark all read'),
                  ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return _NotificationTile(
                        notification: n,
                        onTap: () {
                          final id = n['notification_id'] as int?;
                          final isRead = n['is_read'] == true || n['is_read'] == 1;
                          if (id != null && !isRead) _markRead(id, i);
                        },
                        onDismiss: () {
                          final id = n['notification_id'] as int?;
                          if (id != null) _delete(id, i);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String?;
    final def = _defFor(type);
    final isEmergency = type?.startsWith('emergency') ?? false;
    final isRead = notification['is_read'] == true || notification['is_read'] == 1;
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final createdAt = _timeAgo(notification['created_at']);

    return Dismissible(
      key: Key(notification['notification_id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red.shade700,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isRead
                ? Colors.transparent
                : isEmergency
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon circle ───────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: isEmergency ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(def.icon, color: def.color, size: 22),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: def.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Type chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: def.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            def.label,
                            style: TextStyle(
                              fontSize: 9,
                              color: def.color,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          createdAt,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        color: isEmergency && !isRead
                            ? Colors.red.shade800
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(dynamic v) {
    if (v == null) return '';
    try {
      final t = DateTime.parse(v.toString()).toLocal();
      final diff = DateTime.now().difference(t);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${t.day}/${t.month}/${t.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency alerts and trip updates will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
