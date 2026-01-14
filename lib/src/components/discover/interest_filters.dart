import 'package:flutter/material.dart';

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
      'colorStart': Colors.green.shade400,
      'colorEnd': Colors.green.shade600,
      'icon': Icons.park,
    },
    {
      'name': 'History',
      'colorStart': Colors.amber.shade400,
      'colorEnd': Colors.orange.shade500,
      'icon': Icons.account_balance, // landmark icon
    },
    {
      'name': 'Food',
      'colorStart': Colors.pink.shade400,
      'colorEnd': Colors.red.shade400,
      'icon': Icons.restaurant, // utensils icon
    },
    {
      'name': 'Adventure',
      'colorStart': Colors.blue.shade400,
      'colorEnd': Colors.indigo.shade500,
      'icon': Icons.confirmation_number_sharp, // tent icon
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
              gradient: isActive
                  ? LinearGradient(
                      colors: [filter['colorStart'], filter['colorEnd']],
                    )
                  : null,
              color: isActive ? null : Colors.white.withOpacity(0.1),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter['icon'],
                  size: 16,
                  color: isActive ? Colors.white : Colors.grey[300],
                ),
                const SizedBox(width: 6),
                Text(
                  filter['name'],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[300],
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
