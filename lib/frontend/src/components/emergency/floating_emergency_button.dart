import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../pages/emergency_sos_screen.dart';
import '../../pages/emergency_contacts_page.dart';

class FloatingEmergencyButton extends StatefulWidget {
  const FloatingEmergencyButton({super.key});

  @override
  State<FloatingEmergencyButton> createState() =>
      _FloatingEmergencyButtonState();
}

class _FloatingEmergencyButtonState extends State<FloatingEmergencyButton>
    with TickerProviderStateMixin {

  bool _isExpanded = false;

  // Pulse animation for the main button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;

  // Expand/collapse animation for the menu
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandCtrl.forward();
      } else {
        _expandCtrl.reverse();
      }
    });
  }

  void _closeMenu() {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
    _expandCtrl.reverse();
  }

  Future<String> _getLocationLabel() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'an unknown location';

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return 'an unknown location';
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = p.locality?.isNotEmpty == true
              ? p.locality!
              : p.subAdministrativeArea ?? '';
          final country = p.country ?? '';
          if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
          if (city.isNotEmpty) return city;
        }
      } catch (_) {}

      return '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    } catch (_) {
      return 'an unknown location';
    }
  }

  Future<void> _dial(String number) async {
    _closeMenu();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();

    final label = await _getLocationLabel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling $number — your location: $label'),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    final uri = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open dialer. Please call $number manually.')),
        );
      }
    }
  }

  void _openICEContacts() {
    _closeMenu();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencyContactsPage()),
    );
  }

  void _openSOSAlert() {
    _closeMenu();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencySOSScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        // ── Backdrop (closes menu on outside tap) ───────────────────────────
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),

        // ── Expandable options (bottom to top) ──────────────────────────────
        AnimatedBuilder(
          animation: _expandAnim,
          builder: (context2, child2) {
            return Opacity(
              opacity: _expandAnim.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _expandAnim.value.clamp(0.0, 1.0),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SOSOption(
                      label: 'SOS Alert',
                      icon: Icons.sos,
                      color: const Color(0xFFB71C1C),
                      onTap: _openSOSAlert,
                    ),
                    const SizedBox(height: 10),
                    _SOSOption(
                      label: 'ICE Contacts',
                      icon: Icons.contacts_rounded,
                      color: Colors.orange.shade700,
                      onTap: _openICEContacts,
                    ),
                    const SizedBox(height: 10),
                    _SOSOption(
                      label: 'Tourist Police 1422',
                      icon: Icons.shield_rounded,
                      color: Colors.blue.shade700,
                      onTap: () => _dial('1422'),
                    ),
                    const SizedBox(height: 10),
                    _SOSOption(
                      label: 'Police 15',
                      icon: Icons.local_police_rounded,
                      color: const Color(0xFF1A237E),
                      onTap: () => _dial('15'),
                    ),
                    const SizedBox(height: 10),
                    _SOSOption(
                      label: 'Ambulance 1122',
                      icon: Icons.medical_services_rounded,
                      color: Colors.green.shade700,
                      onTap: () => _dial('1122'),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Main SOS button ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 74, right: 8),
          child: AnimatedBuilder(
            animation: _pulseScale,
            builder: (_, child) {
              final scale = _isExpanded ? 1.0 : _pulseScale.value;
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: _toggleMenu,
              child: _MainSOSButton(isOpen: _isExpanded),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Main SOS Button ──────────────────────────────────────────────────────────
class _MainSOSButton extends StatelessWidget {
  final bool isOpen;
  const _MainSOSButton({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isOpen
              ? [Colors.grey.shade600, Colors.grey.shade800]
              : [const Color(0xFFF44336), const Color(0xFFB71C1C)],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? Colors.grey : Colors.red).withValues(alpha: 0.55),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isOpen ? Icons.close_rounded : Icons.warning_amber_rounded,
            key: ValueKey(isOpen),
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// ─── SOS Option Row ───────────────────────────────────────────────────────────
class _SOSOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SOSOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label chip
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Icon button
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}
