import '../../utils/app_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/local_database_service.dart';
import '../../utils/responsive.dart';
import '../../utils/notification_service.dart';
import '../../utils/api_service.dart';
import '../../pages/notifications_page.dart';

class TopNavigation extends StatefulWidget {
  const TopNavigation({super.key});

  @override
  State<TopNavigation> createState() => _TopNavigationState();
}

class _TopNavigationState extends State<TopNavigation> {
  String _firstName = '';
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _unread = NotificationService.instance.unreadCount;
    NotificationService.instance.addUnreadListener(_onUnreadChanged);
    _fetchUnreadCount();
  }

  @override
  void dispose() {
    NotificationService.instance.removeUnreadListener(_onUnreadChanged);
    super.dispose();
  }

  void _onUnreadChanged() {
    if (mounted) {
      setState(() => _unread = NotificationService.instance.unreadCount);
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final resp = await ApiService.getRequest('/notifications/unread-count');
      if (!mounted) return;
      final count = resp['count'] as int? ?? 0;
      NotificationService.instance.setUnreadCount(count);
      setState(() => _unread = count);
    } catch (_) {}
  }

  Future<void> _loadUserName() async {
    final user = AppAuth.currentUser;
    if (user == null) return;

    // 1. Auth profile name (Google / Apple / signup metadata)
    final authName = user.displayName?.trim() ?? '';
    if (authName.isNotEmpty) {
      _setName(authName);
      return;
    }

    // 2. Local SQLite — full_name saved during signup / social login
    final profile = await LocalDatabaseService.getUserProfile(user.uid);
    final dbName = (profile?['full_name'] as String?)?.trim() ?? '';
    if (dbName.isNotEmpty) {
      _setName(dbName);
      return;
    }

    // 3. Email prefix as last fallback
    final email = user.email ?? '';
    _setName(email.split('@').first);
  }

  void _setName(String fullName) {
    if (!mounted) return;
    // Show only the first word (first name)
    setState(() => _firstName = fullName.split(' ').first);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleFontSize = ResponsiveUtil.getResponsiveFontSize(
      context,
      mobileSize: 18,
      tabletSize: 20,
      laptopSize: 24,
    );
    final subtitleFontSize = ResponsiveUtil.getResponsiveFontSize(
      context,
      mobileSize: 12,
      tabletSize: 14,
      laptopSize: 16,
    );
    final padding = ResponsiveUtil.getResponsivePadding(context);

    final greeting = _firstName.isNotEmpty ? _firstName : 'Traveler';

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFARSYNC',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: padding * 0.35),
                Text(
                  'Assalam-o-Alaikum, $greeting 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: padding * 0.25),
                Text(
                  'Ready for your next adventure?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: subtitleFontSize,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: padding * 0.5),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ).then((_) => _fetchUnreadCount());
                  },
                ),
              ),
              if (_unread > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
