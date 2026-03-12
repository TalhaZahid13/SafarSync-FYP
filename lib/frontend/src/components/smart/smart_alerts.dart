import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AlertItem {
  final int id;
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  AlertItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

class SmartAlerts extends StatefulWidget {
  const SmartAlerts({super.key});

  @override
  State<SmartAlerts> createState() => _SmartAlertsState();
}

class _SmartAlertsState extends State<SmartAlerts> {
  List<AlertItem> alerts = [
    AlertItem(
      id: 1,
      icon: LucideIcons.cloud,
      color: Colors.blue,
      title: 'Weather Update',
      message: 'Rain expected in 2 hours at destination',
    ),
    AlertItem(
      id: 2,
      icon: LucideIcons.tag,
      color: Colors.green,
      title: 'Nearby Deal',
      message: '30% off at The Golden Fork restaurant',
    ),
  ];

  void dismissAlert(int id) {
    setState(() {
      alerts.removeWhere((alert) => alert.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: alerts.map((alert) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // glass effect
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: alert.color, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: alert.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(alert.icon, color: alert.color, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Title & message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                GestureDetector(
                  onTap: () => dismissAlert(alert.id),
                  child: Icon(
                    LucideIcons.x,
                    color: Colors.grey.shade400,
                    size: 18,
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
