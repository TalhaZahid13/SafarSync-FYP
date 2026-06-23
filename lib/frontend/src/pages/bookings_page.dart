import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';
import '../utils/payment_service.dart';
import 'payment_page.dart';

// ─── Booking Status Helpers ───────────────────────────────────────────────────

Color _statusColor(String? s) {
  switch (s) {
    case 'Confirmed': return Colors.green;
    case 'Active': return Colors.teal;
    case 'Completed': return Colors.grey;
    case 'Awaiting Payment': return Colors.orange;
    case 'Cancelled': return Colors.red;
    case 'Refunded': return Colors.purple;
    default: return Colors.blue;
  }
}

IconData _statusIcon(String? s) {
  switch (s) {
    case 'Confirmed': return Icons.check_circle;
    case 'Active': return Icons.flight_takeoff;
    case 'Completed': return Icons.done_all;
    case 'Awaiting Payment': return Icons.payment;
    case 'Cancelled': return Icons.cancel;
    case 'Refunded': return Icons.currency_exchange;
    default: return Icons.bookmark;
  }
}

// ─── BookingsPage ─────────────────────────────────────────────────────────────

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _bookings = [];
  bool _loading = true;
  late TabController _tabController;

  static const _tabs = ['All', 'Active', 'Upcoming', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.getRequest('/bookings/list');
      if (mounted) {
        setState(() {
          _bookings = r['bookings'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _filtered(int tabIdx) {
    if (tabIdx == 0) return _bookings;
    final label = _tabs[tabIdx];
    return _bookings.where((b) {
      final s = b['status'] as String? ?? '';
      if (label == 'Active') return s == 'Active' || s == 'Confirmed';
      if (label == 'Upcoming') return s == 'Pending' || s == 'Awaiting Payment';
      if (label == 'Completed') return s == 'Completed';
      if (label == 'Cancelled') return s == 'Cancelled' || s == 'Refunded';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Booking',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
            ).then((_) => _load()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (i) {
                final list = _filtered(i);
                if (list.isEmpty) {
                  return _emptyState(i == 0
                      ? 'No bookings yet'
                      : 'No ${_tabs[i].toLowerCase()} bookings');
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, idx) => _BookingCard(
                      booking: list[idx],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailsScreen(
                            bookingId: list[idx]['booking_id'] as int,
                          ),
                        ),
                      ).then((_) => _load()),
                    ),
                  ),
                );
              }),
            ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateBookingScreen()),
            ).then((_) => _load()),
            child: const Text('Create Booking'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'Pending';
    final color = _statusColor(status);
    final travelDate = booking['travel_date'] as String?;
    final travelers = booking['num_travelers'] as int? ?? 1;
    final amount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking['destination_name'] as String? ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(status,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(Icons.people_outline, '$travelers traveler${travelers > 1 ? 's' : ''}'),
                  const SizedBox(width: 8),
                  if (travelDate != null)
                    _infoChip(Icons.calendar_today, travelDate),
                  const Spacer(),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ─── CreateBookingScreen ──────────────────────────────────────────────────────

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _destId;
  DateTime? _bookingDate;
  DateTime? _travelDate;
  int _duration = 1;
  int _travelers = 1;
  String _notes = '';
  List<dynamic> _destinations = [];
  bool _loading = false;
  bool _submitting = false;

  double _pricePerDay = 50.0;
  double get _total => _pricePerDay * _duration * _travelers;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getDestinations();
      if (mounted && r['success'] == true) {
        setState(() {
          _destinations = r['destinations'] as List? ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDestinationChange(int? id) {
    if (id == null) return;
    setState(() => _destId = id);
    final dest = _destinations.firstWhere(
      (d) => ((d['destination_id'] ?? d['id']) as num?)?.toInt() == id,
      orElse: () => <String, dynamic>{},
    );
    final cost = (dest['average_cost'] as num?)?.toDouble();
    if (cost != null && cost > 0) setState(() => _pricePerDay = cost);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bookingDate == null) {
      _snack('Please select a booking date');
      return;
    }
    _formKey.currentState!.save();

    setState(() => _submitting = true);
    try {
      final r = await ApiService.postRequest('/bookings/create', {
        'destination_id': _destId,
        'booking_date': _fmt(_bookingDate!),
        'travel_date': _travelDate != null ? _fmt(_travelDate!) : null,
        'num_travelers': _travelers,
        'duration_days': _duration,
        'notes': _notes,
      });

      if (!mounted) return;
      if (r['success'] == true) {
        _snack('Booking created! Total: \$${_total.toStringAsFixed(2)}',
            success: true);
        Navigator.pop(context);
      } else {
        _snack(r['error'] as String? ?? 'Failed to create booking');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Booking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                value: _destId,
                decoration: _dec('Destination', Icons.place),
                items: _destinations
                    .where((d) => (d['destination_id'] ?? d['id']) != null)
                    .map((d) => DropdownMenuItem<int>(
                          value: ((d['destination_id'] ?? d['id']) as num).toInt(),
                          child: Text(d['name'] as String? ?? ''),
                        ))
                    .toList(),
                onChanged: _onDestinationChange,
                validator: (v) => v == null ? 'Select a destination' : null,
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Booking Date',
                value: _bookingDate,
                firstDate: DateTime.now(),
                onPicked: (d) => setState(() => _bookingDate = d),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Travel Date (optional)',
                value: _travelDate,
                firstDate: _bookingDate ?? DateTime.now(),
                onPicked: (d) => setState(() => _travelDate = d),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: _dec('Duration (days)', Icons.schedule),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Min 1 day';
                        return null;
                      },
                      onChanged: (v) =>
                          setState(() => _duration = int.tryParse(v) ?? 1),
                      onSaved: (v) => _duration = int.tryParse(v ?? '1') ?? 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: _dec('Travelers', Icons.people),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Min 1';
                        return null;
                      },
                      onChanged: (v) =>
                          setState(() => _travelers = int.tryParse(v) ?? 1),
                      onSaved: (v) =>
                          _travelers = int.tryParse(v ?? '1') ?? 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _dec('Notes (optional)', Icons.note),
                maxLines: 3,
                onSaved: (v) => _notes = v ?? '',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _summaryRow('Rate per day', '\$$_pricePerDay'),
                    _summaryRow('Duration', '$_duration day${_duration > 1 ? 's' : ''}'),
                    _summaryRow('Travelers', '$_travelers'),
                    const Divider(),
                    _summaryRow(
                      'Estimated Total',
                      '\$${_total.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Booking', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
}

// ─── BookingDetailsScreen ─────────────────────────────────────────────────────

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? _booking;
  bool _loading = true;
  bool _cancelling = false;
  bool _requestingRefund = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.getRequest('/bookings/${widget.bookingId}');
      if (mounted && r['success'] == true) {
        setState(() {
          _booking = r['booking'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final reason = await _askCancelReason();
    if (reason == null) return;

    setState(() => _cancelling = true);
    try {
      final r = await ApiService.postRequest(
        '/bookings/${widget.bookingId}/cancel',
        {'reason': reason},
      );
      if (!mounted) return;
      if (r['success'] == true) {
        _snack('Booking cancelled', success: true);
        _load();
      } else {
        _snack(r['error'] as String? ?? 'Failed to cancel');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<String?> _askCancelReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this booking?',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Cancel Booking',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRefund() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Refund'),
        content: const Text(
          'Submit a refund request for this booking?\n\n'
          'Our team will review it within 24-48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request Refund'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _requestingRefund = true);
    try {
      final ok = await PaymentService.requestRefund(widget.bookingId);
      if (!mounted) return;
      _snack(
        ok
            ? 'Refund request submitted — admin will review within 24-48 hours'
            : 'Failed to submit refund request',
        success: ok,
      );
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _requestingRefund = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final b = _booking!;
    final status = b['status'] as String? ?? 'Pending';
    final payStatus = b['payment_status'] as String? ?? 'Unpaid';
    final amount = (b['total_amount'] as num?)?.toDouble() ?? 0.0;
    final canPay = payStatus == 'Unpaid' &&
        (status == 'Pending' || status == 'Awaiting Payment');
    final canCancel = !['Completed', 'Cancelled', 'Refunded'].contains(status);
    final canRequestRefund = payStatus == 'Paid' &&
        ['Confirmed', 'Active', 'Cancelled', 'Completed'].contains(status);
    final color = _statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          if (canCancel)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel Booking',
              onPressed: _cancelling ? null : _cancel,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    b['image_url'] as String,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.image, size: 60),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                b['destination_name'] as String? ?? 'Unknown',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusBadge(status: status, color: color),
                  const SizedBox(width: 8),
                  _PayBadge(payStatus: payStatus),
                ],
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Booking Info',
                children: [
                  _InfoRow('Booking ID', '#${b['booking_id']}'),
                  _InfoRow('Booking Date', b['booking_date'] as String?),
                  _InfoRow('Travel Date', b['travel_date'] as String?),
                  _InfoRow(
                    'Duration',
                    '${b['estimated_duration_days'] ?? 1} day(s)',
                  ),
                  _InfoRow(
                    'Travelers',
                    '${b['num_travelers'] ?? 1} person(s)',
                  ),
                  if (b['notes'] != null &&
                      (b['notes'] as String).isNotEmpty)
                    _InfoRow('Notes', b['notes'] as String),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Payment',
                children: [
                  _InfoRow('Total Amount',
                      '\$${amount.toStringAsFixed(2)}'),
                  _InfoRow('Payment Status', payStatus),
                  if (b['payment_intent_id'] != null)
                    _InfoRow('Transaction',
                        b['payment_intent_id'] as String),
                ],
              ),
              const SizedBox(height: 24),
              if (canPay)
                ElevatedButton.icon(
                  onPressed: () async {
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          bookingId: b['booking_id'] as int,
                          destinationName:
                              b['destination_name'] as String? ?? 'Booking',
                          durationDays:
                              (b['estimated_duration_days'] as num?)
                                      ?.toInt() ??
                                  1,
                          numTravelers:
                              (b['num_travelers'] as num?)?.toInt() ?? 1,
                          pricePerDay:
                              (b['average_cost'] as num?)?.toDouble() ??
                                  50.0,
                          totalAmount: amount,
                        ),
                      ),
                    );
                    if (paid == true) _load();
                  },
                  icon: const Icon(Icons.payment),
                  label: Text('Pay Now — \$${amount.toStringAsFixed(2)}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (canCancel && !canPay) const SizedBox(height: 8),
              if (canCancel)
                OutlinedButton.icon(
                  onPressed: _cancelling ? null : _cancel,
                  icon: _cancelling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              if (canRequestRefund) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _requestingRefund ? null : _requestRefund,
                  icon: _requestingRefund
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.currency_exchange),
                  label: const Text('Request Refund'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(status), size: 14, color: color),
            const SizedBox(width: 4),
            Text(status,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PayBadge extends StatelessWidget {
  final String payStatus;
  const _PayBadge({required this.payStatus});

  @override
  Widget build(BuildContext context) {
    final color = payStatus == 'Paid'
        ? Colors.green
        : payStatus == 'Refunded'
            ? Colors.purple
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        payStatus,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: children),
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
            const Spacer(),
            Flexible(
              child: Text(
                value ?? 'N/A',
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime firstDate;
  final ValueChanged<DateTime> onPicked;

  const _DateField({
    required this.label,
    this.value,
    required this.firstDate,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: value != null ? DateFormat('yyyy-MM-dd').format(value!) : '',
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? firstDate,
          firstDate: firstDate,
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }
}
