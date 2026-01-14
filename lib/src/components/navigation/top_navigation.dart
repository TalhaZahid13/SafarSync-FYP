import 'package:flutter/material.dart';

class TopNavigation extends StatelessWidget {
  const TopNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0), // mb-6
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Assalam-o-Alaikum, Talha 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4), // mb-1
              Text(
                'Ready for your next adventure?',
                style: TextStyle(
                  color: Colors.white70, // text-white/80
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Action Buttons
          Row(
            children: [
              // Bell button
              Stack(
                children: [
                  Container(
                    width: 44, // w-11 (~44px)
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white12, // approximate glass effect
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none, // substitute for Bell
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  // Red dot notification
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8, // w-2 (~8px)
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12), // gap-3
              // User button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5A6E), Color(0xFF2B7A8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.person, // substitute for User
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
