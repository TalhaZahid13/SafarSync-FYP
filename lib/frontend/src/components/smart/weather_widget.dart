import 'package:flutter/material.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Location',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Islamabad, Pakistan',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '28°',
                    style: TextStyle(
                      fontSize: 48,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.cloud, size: 48, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Partly Cloudy',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Right Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    'Humidity',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.water_drop, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '65%',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Wind',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.air, size: 16, color: colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '12 mph',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
