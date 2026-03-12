import 'package:flutter/material.dart';

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
    // Navigation items
    final navItems = [
      {'id': 'home', 'icon': Icons.home, 'label': 'Home'},
      {'id': 'explore', 'icon': Icons.explore, 'label': 'Explore'},
      {'id': 'routes', 'icon': Icons.alt_route, 'label': 'Routes'},
      {'id': 'wishlist', 'icon': Icons.favorite, 'label': 'Wishlist'},
      {'id': 'profile', 'icon': Icons.person, 'label': 'Profile'},
    ];

    return SafeArea(
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.1), // Glass effect base
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              bool isActive = activeTab == item['id'];
              return GestureDetector(
                onTap: () {
                  onTabChange(item['id'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isActive ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
