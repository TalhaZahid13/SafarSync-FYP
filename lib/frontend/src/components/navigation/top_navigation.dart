import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/user_profile_provider.dart';
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
  int _unread = 0;

  @override
  void initState() {
    super.initState();
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

    // Name + photo come from the signed-in user's database profile and
    // update as soon as the profile is saved (see UserProfileProvider).
    final profile = context.watch<UserProfileProvider>();
    final greeting = profile.firstName;

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
          _ProfileAvatar(
            photoUrl: profile.photoUrl,
            initials: profile.initials,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
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

/// Signed-in user's photo, or their initials when there is none / it fails.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.initials,
    required this.color,
  });

  final String? photoUrl;
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
    return Semantics(
      label: 'Your profile',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: (photoUrl == null)
            ? fallback
            : Image.network(
                photoUrl!,
                key: ValueKey(photoUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
