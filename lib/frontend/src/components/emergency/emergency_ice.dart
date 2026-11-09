import 'package:flutter/material.dart';
import '../../utils/app_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/api_service.dart';

class EmergencyICE extends StatefulWidget {
  const EmergencyICE({super.key});

  @override
  State<EmergencyICE> createState() => _EmergencyICEState();
}

class _EmergencyICEState extends State<EmergencyICE> {
  String _locationCoordinates = 'Fetching location...';
  String _locationCityCountry = 'Please wait';
  double? _rawLat;
  double? _rawLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLocation();
    });
  }

  Future<void> _loadLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          );

          String city = '';
          String country = '';
          try {
            final placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              city = (place.locality?.isNotEmpty ?? false)
                  ? place.locality!
                  : (place.subAdministrativeArea ?? '');
              country = place.country ?? '';
            }
          } catch (_) {}

          if (!mounted) return;
          setState(() {
            _rawLat = position.latitude;
            _rawLng = position.longitude;
            _locationCoordinates =
                '${position.latitude.toStringAsFixed(4)}° N, '
                '${position.longitude.toStringAsFixed(4)}° E';
            _locationCityCountry = city.isNotEmpty && country.isNotEmpty
                ? '$city, $country'
                : (city.isNotEmpty ? city : 'Unknown city');
          });
          return;
        }
      }
    } catch (_) {}

    await _loadLocationFromBackend();
  }

  Future<void> _loadLocationFromBackend() async {
    final uid = AppAuth.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _locationCoordinates = 'Location unavailable';
        _locationCityCountry = 'Login required';
      });
      return;
    }

    final result = await ApiService.getLatestLocation();
    if (!mounted) return;

    if (result['success'] != true || result['location'] == null) {
      setState(() {
        _locationCoordinates = 'Location unavailable';
        _locationCityCountry = 'Enable GPS for location';
      });
      return;
    }

    final location = result['location'] as Map<String, dynamic>;
    final lat = double.tryParse('${location['latitude'] ?? ''}');
    final lng = double.tryParse('${location['longitude'] ?? ''}');
    final city = '${location['city'] ?? ''}'.trim();
    final country = '${location['country'] ?? ''}'.trim();

    setState(() {
      _rawLat = lat;
      _rawLng = lng;
      _locationCoordinates = (lat != null && lng != null)
          ? '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
          : 'Coordinates unavailable';
      _locationCityCountry = city.isNotEmpty && country.isNotEmpty
          ? '$city, $country'
          : (city.isNotEmpty ? city : 'Unknown city');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pulse alert icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded, // AlertCircle
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Emergency ICE Panel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quick access to emergency services',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: '15');
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      await launchUrl(uri);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.phone, color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Call Emergency',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '15',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final lat = _rawLat;
                    final lng = _rawLng;

                    final mapsUrl = (lat != null && lng != null)
                        ? 'https://maps.google.com/?q=$lat,$lng'
                        : null;

                    final message = [
                      '🚨 Emergency! I need help!',
                      '',
                      '📍 $_locationCityCountry',
                      '📌 $_locationCoordinates',
                      if (mapsUrl != null) '🗺️ $mapsUrl',
                    ].join('\n');

                    Share.share(message, subject: 'Emergency Location');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.share, color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Share Location',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        'Real-time GPS',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current location box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_pin, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locationCoordinates,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _locationCityCountry,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
