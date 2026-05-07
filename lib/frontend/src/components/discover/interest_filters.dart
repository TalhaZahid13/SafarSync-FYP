import 'package:flutter/material.dart';
import '../../ui/app_theme.dart'; // 👈 IMPORTANT

class InterestFilters extends StatefulWidget {
  const InterestFilters({super.key});

  @override
  State<InterestFilters> createState() => _InterestFiltersState();
}

class _InterestFiltersState extends State<InterestFilters> {
  final List<String> activeFilters = ['Nature'];

  final List<Map<String, dynamic>> filters = [
    {
      'name': 'Nature',
      'gradient': LinearGradient(colors: [AppTheme.emerald, AppTheme.teal]),
      'borderColor': AppTheme.emerald,
      'icon': Icons.park,
    },
    {
      'name': 'History',
      'gradient': LinearGradient(colors: [AppTheme.violet, AppTheme.purple]),
      'borderColor': AppTheme.violet,
      'icon': Icons.account_balance,
    },
    {
      'name': 'Food',
      'gradient': LinearGradient(colors: [AppTheme.Rose, AppTheme.pink]),
      'borderColor': AppTheme.Rose,
      'icon': Icons.restaurant,
    },
    {
      'name': 'Adventure',
      'gradient': LinearGradient(colors: [AppTheme.sky, AppTheme.cyan]),
      'borderColor': AppTheme.cyan,
      'icon': Icons.confirmation_number_sharp,
    },
  ];

  void toggleFilter(String name) {
    setState(() {
      if (activeFilters.contains(name)) {
        activeFilters.remove(name);
      } else {
        activeFilters.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final bool isActive = activeFilters.contains(filter['name']);

        return GestureDetector(
          onTap: () => toggleFilter(filter['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              // ✅ Active = gradient
              gradient: isActive ? filter['gradient'] : null,

              // ✅ Inactive = glass
              color: isActive ? null : AppTheme.navyGlass,

              // ✅ Border FIX
              border: Border.all(
                color: isActive
                    ? filter['borderColor'].withOpacity(0.6)
                    : Colors.white,
                width: 1,
              ),

              // ✅ Glow FIX
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: filter['borderColor'].withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter['icon'],
                  size: 16,
                  color: isActive ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  filter['name'],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
