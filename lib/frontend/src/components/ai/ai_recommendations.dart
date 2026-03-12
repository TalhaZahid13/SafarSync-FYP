import 'package:flutter/material.dart';

class AIRecommendations extends StatelessWidget {
  const AIRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    final recommendations = [
      {
        'title': 'Mountain Trek Adventure',
        'tags': ['Nature', 'Adventure'],
        'icon': Icons.terrain,
        'colors': [Colors.green.shade400, Colors.green.shade700],
      },
      {
        'title': 'Historical Sites Tour',
        'tags': ['History', 'Culture'],
        'icon': Icons.account_balance,
        'colors': [Colors.amber.shade400, Colors.orange.shade500],
      },
      {
        'title': 'Culinary Experience',
        'tags': ['Food', 'Culture'],
        'icon': Icons.restaurant,
        'colors': [Colors.pink.shade400, Colors.red.shade400],
      },
      {
        'title': 'Camping Expedition',
        'tags': ['Nature', 'Adventure'],
        //'icon': Icons.camping,
        'colors': [Colors.blue.shade400, Colors.indigo.shade500],
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // glass-card effect
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF1B5A6E)),
              SizedBox(width: 8),
              Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI-curated trips based on your interests',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Grid of recommendations
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  2, // for mobile, adjust later for web responsiveness
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              final List<Color> colors = rec['colors'] as List<Color>;
              final List<String> tags = rec['tags'] as List<String>;
              return GestureDetector(
                onTap: () {
                  // TODO: handle card click
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with gradient
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          rec['icon'] as IconData? ?? Icons.help,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1B5A6E),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
