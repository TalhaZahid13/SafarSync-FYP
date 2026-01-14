import 'package:flutter/material.dart';

class FloatingEmergencyButton extends StatefulWidget {
  const FloatingEmergencyButton({super.key});

  @override
  State<FloatingEmergencyButton> createState() =>
      _FloatingEmergencyButtonState();
}

class _FloatingEmergencyButtonState extends State<FloatingEmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEmergencyAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text(
          'Location and contact details shared with ICE and Emergency response teams.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 96, // bottom-24 (~96px)
      right: 24, // right-6 (~24px)
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: _showEmergencyAlert,
          child: Container(
            width: 64, // w-16
            height: 64, // h-16
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF44336),
                  Color(0xFFB71C1C),
                ], // red-500 to red-600
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.warning_amber_rounded, // substitute for AlertCircle
                color: Colors.white,
                size: 32, // w-8 h-8 (~32px)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
