import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';

class AIRecommendations extends StatelessWidget {
  const AIRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    final recommendations = [
      {
        'title': 'Mountain Trek Adventure',
        'subtitle': 'Fairy Meadows & K2 Base Camp',
        'tags': ['Nature', 'Adventure'],
        'icon': Icons.landscape,
        'gradient': AppTheme.natureGradient,
        'bgColor': AppTheme.natureCardBg,
        'borderColor': AppTheme.natureBorder,
      },
      {
        'title': 'Historical Sites Tour',
        'subtitle': 'Lahore Fort, Badshahi Mosque',
        'tags': ['History', 'Culture'],
        'icon': Icons.account_balance,
        'gradient': AppTheme.historyGradient,
        'bgColor': AppTheme.historyCardBg,
        'borderColor': AppTheme.historyBorder,
      },
      {
        'title': 'Culinary Experience',
        'subtitle': 'Monal, Bundu Khan & Food St.',
        'tags': ['Food', 'Culture'],
        'icon': Icons.restaurant,
        'gradient': AppTheme.foodGradient,
        'bgColor': AppTheme.foodCardBg,
        'borderColor': AppTheme.foodBorder,
      },
      {
        'title': 'Camping Expedition',
        'subtitle': 'Naran Kaghan & Skardu',
        'tags': ['Nature', 'Adventure'],
        'icon': Icons.cabin,
        'gradient': AppTheme.adventureGradient,
        'bgColor': AppTheme.adventureCardBg,
        'borderColor': AppTheme.adventureBorder,
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.navyGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cyan.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyan.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppTheme.gold),
              SizedBox(width: 8),
              Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI-curated trips based on your interests',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              final gradient = rec['gradient'] as LinearGradient;
              final accent = rec['borderColor'] as Color;
              final tags = rec['tags'] as List<String>;

              return GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.glassStrong,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: gradient,
                        ),
                        child: Icon(
                          rec['icon'] as IconData,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: tags.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accent.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
