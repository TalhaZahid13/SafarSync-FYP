import 'package:flutter/material.dart';
import '../../utils/api_service.dart';

class BookingStatsCard extends StatefulWidget {
  const BookingStatsCard({super.key});

  @override
  State<BookingStatsCard> createState() => _BookingStatsCardState();
}

class _BookingStatsCardState extends State<BookingStatsCard> {
  int singleBookings = 0;
  int groupBookings = 0;
  int activeTrips = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final bookingsResp = await ApiService.getRequest('/bookings/list');
      final groupResp = await ApiService.getRequest('/group-bookings/list');

      if (mounted) {
        setState(() {
          singleBookings = (bookingsResp['bookings'] as List<dynamic>?)?.length ?? 0;
          final groups = groupResp['group_bookings'] as List<dynamic>? ?? [];
          groupBookings = groups.length;
          activeTrips = groups
              .where((g) => (g as Map<String, dynamic>)['status'] == 'Active')
              .length;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Single Bookings',
                    value: singleBookings.toString(),
                    icon: Icons.bookmark,
                  ),
                  _StatItem(
                    label: 'Group Trips',
                    value: groupBookings.toString(),
                    icon: Icons.group,
                  ),
                  _StatItem(
                    label: 'Active',
                    value: activeTrips.toString(),
                    icon: Icons.play_circle,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
