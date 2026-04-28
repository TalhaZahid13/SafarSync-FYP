import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/api_service.dart';

class EmergencyICE extends StatefulWidget {
  const EmergencyICE({super.key});

  @override
  State<EmergencyICE> createState() => _EmergencyICEState();
}

class _EmergencyICEState extends State<EmergencyICE> {
  String _locationCoordinates = 'Fetching location...';
  String _locationCityCountry = 'Please wait';

  @override
  void initState() {
    super.initState();
    _loadLatestLocationFromBackend();
  }

  Future<void> _loadLatestLocationFromBackend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _locationCoordinates = 'Location unavailable';
        _locationCityCountry = 'Login required';
      });
      return;
    }

    final result = await ApiService.getLatestLocation(userIdentifier: uid);
    if (!mounted) return;

    if (result['success'] != true || result['location'] == null) {
      setState(() {
        _locationCoordinates = 'Location unavailable';
        _locationCityCountry = 'No backend location yet';
      });
      return;
    }

    final location = result['location'] as Map<String, dynamic>;
    final lat = double.tryParse('${location['latitude'] ?? ''}');
    final lng = double.tryParse('${location['longitude'] ?? ''}');
    final city = '${location['city'] ?? ''}'.trim();
    final country = '${location['country'] ?? ''}'.trim();

    final coordText = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
        : 'Coordinates unavailable';
    final cityCountryText = city.isNotEmpty && country.isNotEmpty
        ? '$city, $country'
        : (city.isNotEmpty ? city : 'Unknown city');

    setState(() {
      _locationCoordinates = coordText;
      _locationCityCountry = cityCountryText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // glass-card
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Emergency ICE Panel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Quick access to emergency services',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: implement emergency call
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
                    // TODO: implement share location
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
