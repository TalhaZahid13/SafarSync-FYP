import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../ui/app_theme.dart';

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
      color: const Color(0xFF4A90E2), // weather blue
      title: 'Weather Update',
      message: 'Rain expected in 2 hours near Murree - pack your rain gear!',
    ),
    AlertItem(
      id: 2,
      icon: LucideIcons.tag,
      color: const Color(0xFFFF8F00), // deal amber
      title: 'Nearby Deal',
      message:
          '30% off at The Golden Fork Restaurant, Islamabad - limited time!',
    ),
    AlertItem(
      id: 3,
      icon: LucideIcons.sparkles,
      color: const Color(0xFF7B61FF), // AI purple
      title: 'AI Travel Tip',
      message:
          'Best time to visit Hunza Valley: May-October. Book now for the season!',
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
            color: alert.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alert.color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: alert.color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
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
                    color: alert.color.withValues(alpha: 0.3),
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
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                GestureDetector(
                  onTap: () => dismissAlert(alert.id),
                  child: const Icon(
                    LucideIcons.x,
                    color: AppTheme.mediumGray,
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
