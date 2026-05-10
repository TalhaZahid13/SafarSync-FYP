import 'package:safarsync/frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class FloatingEmergencyButton extends StatefulWidget {
  const FloatingEmergencyButton({super.key});

  @override
  State<FloatingEmergencyButton> createState() =>
      _FloatingEmergencyButtonState();
}

class _FloatingEmergencyButtonState extends State<FloatingEmergencyButton>
    with TickerProviderStateMixin {
  // Blink: opacity 1.0 ↔ 0.25 at 600 ms
  late AnimationController _blinkController;
  late Animation<double> _blinkOpacity;

  // Ring: expands from button edge outward and fades at 1.4 s
  late AnimationController _ringController;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _blinkOpacity = Tween<double>(begin: 1.0, end: 0.25).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _ringScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _ringOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<String> _fetchCurrentLocationLabel() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'an unknown location';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'an unknown location';
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = (place.locality?.isNotEmpty ?? false)
              ? place.locality!
              : (place.subAdministrativeArea?.isNotEmpty ?? false)
              ? place.subAdministrativeArea!
              : null;
          final country = place.country;

          if (city != null && country != null && country.isNotEmpty) {
            return '$city, $country';
          }
          if (city != null) {
            return city;
          }
        }
      } catch (_) {
        // Fall back to coordinates if reverse geocoding fails.
      }

      return '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    } catch (_) {
      return 'an unknown location';
    }
  }

  Future<void> _handleEmergencyTap() async {
    final locationLabel = await _fetchCurrentLocationLabel();
    await _showEmergencyNotification(locationLabel);
    await _callEmergency();
  }

  Future<void> _showEmergencyNotification(String locationLabel) async {
    if (!mounted) return;

    final message =
        'Your current location is $locationLabel and has been shared with your ICE and nearest police station.';

    // Configure the notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'emergency_channel_id',
          'Emergency Notifications',
          channelDescription:
              'This channel is used for emergency notifications.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Emergency Notice',
      body: message,
      notificationDetails: platformDetails,
      payload: locationLabel,
    );
  }

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '15');

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to open dialer. Please call 15 manually.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 74, right: 8),
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkController, _ringController]),
        builder: (context, child) {
          return SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radiating ring
                Opacity(
                  opacity: _ringOpacity.value,
                  child: Transform.scale(
                    scale: _ringScale.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Blinking button
                GestureDetector(
                  onTap: _handleEmergencyTap,
                  child: Opacity(
                    opacity: _blinkOpacity.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF44336), Color(0xFFB71C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
