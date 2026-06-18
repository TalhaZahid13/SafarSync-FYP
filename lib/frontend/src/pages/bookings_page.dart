import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import 'payment_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  List<dynamic> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final response = await ApiService.getRequest('/bookings/list');
      if (mounted) {
        setState(() {
          bookings = response['bookings'] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
              ).then((_) => _loadBookings());
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No bookings yet'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateBookingScreen(),
                            ),
                          ).then((_) => _loadBookings());
                        },
                        child: const Text('Create Booking'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsScreen(
                              bookingId: booking['booking_id'] as int,
                            ),
                          ),
                        ).then((_) => _loadBookings());
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['destination_name'] as String? ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(booking['status'] as String? ?? 'Planned'),
                                    backgroundColor: _getStatusColor(booking['status'] as String?),
                                  ),
                                  const Spacer(),
                                  Text(booking['booking_date'] as String? ?? ''),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Planned':
        return Colors.blue.withValues(alpha: 0.3);
      case 'Active':
        return Colors.green.withValues(alpha: 0.3);
      case 'Completed':
        return Colors.grey.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }
}

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  int? selectedDestinationId;
  DateTime? selectedDate;
  int duration = 1;
  String notes = '';
  List<dynamic> destinations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    try {
      final response = await ApiService.getDestinations();
      if (mounted && response['success'] == true) {
        setState(() {
          destinations = response['destinations'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading destinations: $e')),
        );
      }
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() => loading = true);
    try {
      final response = await ApiService.postRequest('/bookings/create', {
        'destination_id': selectedDestinationId,
        'booking_date': selectedDate?.toIso8601String().split('T')[0],
        'duration_days': duration,
        'notes': notes,
      });

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Booking')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedDestinationId,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: destinations
                    .map((d) => DropdownMenuItem<int>(
                          value: d['destination_id'] as int,
                          child: Text(d['name'] as String? ?? 'Unknown'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedDestinationId = value),
                validator: (value) =>
                    value == null ? 'Please select a destination' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Booking Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: selectedDate?.toLocal().toString().split(' ')[0] ?? '',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSaved: (value) => duration = int.parse(value ?? '1'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                onSaved: (value) => notes = value ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _createBooking,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? booking;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final response =
          await ApiService.getRequest('/bookings/${widget.bookingId}');
      if (mounted && response['success'] == true) {
        setState(() {
          booking = response['booking'] as Map<String, dynamic>?;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final response = await ApiService.putRequest(
        '/bookings/${widget.bookingId}/status',
        {'status': newStatus},
      );
      if (response['success'] == true && mounted) {
        setState(() => booking!['status'] = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final b = booking!;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                b['image_url'] as String? ?? '',
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image, size: 80),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              b['destination_name'] as String? ?? 'Unknown',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(b['status'] as String? ?? 'Planned'),
              backgroundColor: _getStatusColor(b['status'] as String?),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Booking Date', b['booking_date'] as String?),
            _buildInfoRow('Duration', '${b['estimated_duration_days']} days'),
            _buildInfoRow('User', b['full_name'] as String?),
            if (b['notes'] != null && (b['notes'] as String).isNotEmpty)
              _buildInfoRow('Notes', b['notes'] as String?),
            const SizedBox(height: 24),
            const Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Planned', 'Active', 'Completed']
                  .map((status) => OutlinedButton(
                        onPressed: () => _updateStatus(status),
                        child: Text(status),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            if (b['payment_status'] == 'Paid')
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Payment Completed',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  final paid = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(
                        bookingId: b['booking_id'] as int,
                        destinationName: b['destination_name'] as String? ?? 'Booking',
                        durationDays: (b['estimated_duration_days'] as num?)?.toInt() ?? 1,
                      ),
                    ),
                  );
                  if (paid == true) _loadBooking();
                },
                icon: const Icon(Icons.payment),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value ?? 'N/A', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Planned':
        return Colors.blue.withValues(alpha: 0.3);
      case 'Active':
        return Colors.green.withValues(alpha: 0.3);
      case 'Completed':
        return Colors.grey.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }
}
