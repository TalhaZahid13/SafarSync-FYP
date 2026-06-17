import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

// Static — allocated once for the lifetime of the app
const _kNavItems = [
  _NavItem(id: 'home',    icon: Icons.home,      label: 'Home'),
  _NavItem(id: 'explore', icon: Icons.explore,   label: 'Explore'),
  _NavItem(id: 'trips',   icon: Icons.bookmark,  label: 'Trips'),
  _NavItem(id: 'routes',  icon: Icons.alt_route, label: 'Routes'),
  _NavItem(id: 'profile', icon: Icons.person,    label: 'Profile'),
];

class _NavItem {
  final String id;
  final IconData icon;
  final String label;
  const _NavItem({required this.id, required this.icon, required this.label});
}

class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const BottomNavigation({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final padding = ResponsiveUtil.getResponsivePadding(context);

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: padding * 0.5,
          horizontal: padding,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: theme.cardColor.withValues(alpha: 0.95),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding * 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _kNavItems.map((item) {
                final isActive = activeTab == item.id;
                return _NavButton(
                  item: item,
                  isActive: isActive,
                  isMobile: isMobile,
                  padding: padding,
                  onTap: () => onTabChange(item.id),
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}

// Extracted to minimize what rebuilds when active tab changes
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isMobile;
  final double padding;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.isMobile,
    required this.padding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.textTheme.bodySmall?.color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: padding * 0.5,
          horizontal: isMobile ? 6 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary,
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isActive ? theme.colorScheme.onPrimary : inactiveColor,
              size: isMobile ? 20 : 24,
            ),
            SizedBox(height: padding * 0.25),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? theme.colorScheme.onPrimary : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
