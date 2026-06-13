import 'package:flutter/material.dart';
import '../../pages/safar_ai_chat_page.dart';
import '../../pages/hotel_finder_page.dart';
import '../../pages/food_spots_page.dart';
import '../../pages/smart_route_page.dart';

class QuickAccessCards extends StatelessWidget {
  const QuickAccessCards({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
        icon: Icons.map,
        title: 'Smart Route',
        subtitle: 'Planning',
        gradient: [Colors.blue.shade400, Colors.cyan.shade400],
        destination: const SmartRoutePage(),
      ),
      _CardData(
        icon: Icons.hotel,
        title: 'Hotel',
        subtitle: 'Finder',
        gradient: [const Color(0xFFFDB913), const Color(0xFF1B5A6E)],
        destination: const HotelFinderPage(),
      ),
      _CardData(
        icon: Icons.restaurant,
        title: 'Food',
        subtitle: 'Spots',
        gradient: [Colors.orange.shade400, Colors.yellow.shade400],
        destination: const FoodSpotsPage(),
      ),
      _CardData(
        icon: Icons.computer,
        title: 'Safar AI',
        subtitle: 'Digital Assistant',
        gradient: [const Color(0xFF13E8D0), const Color(0xFF72AEBC)],
        destination: const SafarAiChatPage(),
        isPulse: false,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return AnimatedPulseCard(
          isPulse: card.isPulse,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => card.destination),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: card.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: card.gradient.first.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(card.icon, size: 32, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    card.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Widget destination;
  final bool isPulse;

  const _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.destination,
    this.isPulse = false,
  });
}

class AnimatedPulseCard extends StatefulWidget {
  final Widget child;
  final bool isPulse;

  const AnimatedPulseCard({
    super.key,
    required this.child,
    this.isPulse = false,
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

    if (widget.isPulse) {
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
    if (!widget.isPulse) return widget.child;
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}
