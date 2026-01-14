import 'package:flutter/material.dart';

class QuickAccessCards extends StatelessWidget {
  const QuickAccessCards({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'icon': Icons.map,
        'title': 'Smart Route',
        'subtitle': 'Planning',
        'gradient': [Colors.blue.shade400, Colors.cyan.shade400],
      },
      {
        'icon': Icons.hotel,
        'title': 'Hotel',
        'subtitle': 'Finder',
        'gradient': [Color(0xFFFDB913), Color(0xFF1B5A6E)],
      },
      {
        'icon': Icons.restaurant,
        'title': 'Food',
        'subtitle': 'Spots',
        'gradient': [Colors.orange.shade400, Colors.yellow.shade400],
      },
      {
        'icon': Icons.error,
        'title': 'Emergency',
        'subtitle': 'ICE',
        'gradient': [Colors.red.shade500, Colors.red.shade600],
        'isEmergency': true,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final bool isEmergency = (card['isEmergency'] as bool?) ?? false;
        return AnimatedPulseCard(
          isEmergency: isEmergency,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: card['gradient'] as List<Color>,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(card['icon'] as IconData, size: 32, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  card['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  card['subtitle'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget to animate pulse glow for emergency cards
class AnimatedPulseCard extends StatefulWidget {
  final Widget child;
  final bool isEmergency;

  const AnimatedPulseCard({
    super.key,
    required this.child,
    this.isEmergency = false,
  });

  @override
  State<AnimatedPulseCard> createState() => _AnimatedPulseCardState();
}

class _AnimatedPulseCardState extends State<AnimatedPulseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isEmergency) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEmergency) return widget.child;

    return ScaleTransition(scale: _animation, child: widget.child);
  }
}
