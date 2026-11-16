import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';
import '../utils/user_profile_provider.dart';
import 'payment_page.dart';

/// Hotel stay booking: dates + guests → live availability and a server-side
/// quote per room type → contact details → booking (rooms held) → checkout.
/// The app never computes or sends a price; every amount shown comes from
/// the API.
class HotelBookingPage extends StatefulWidget {
  final int hotelId;
  final String hotelName;

  const HotelBookingPage({
    super.key,
    required this.hotelId,
    required this.hotelName,
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _money = NumberFormat('#,##0');
  final _dateFmt = DateFormat('yyyy-MM-dd');

  Map<String, dynamic>? _hotel;
  String? _hotelError;
  DateTimeRange? _stay;
  int _guests = 2;
  int _rooms = 1;

  List<Map<String, dynamic>> _roomTypes = [];
  bool _checking = false;
  String? _availabilityError;
  int? _selectedRoomTypeId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>();
    _nameCtrl.text = profile.fullName ?? '';
    _phoneCtrl.text = '${profile.profile?['phone_number'] ?? ''}';
    _loadHotel();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHotel() async {
    final r = await ApiService.getRequest(
      '/hotels/${widget.hotelId}',
      auth: false,
    );
    if (!mounted) return;
    setState(() {
      if (r['success'] == true && r['hotel'] is Map) {
        _hotel = Map<String, dynamic>.from(r['hotel'] as Map);
      } else {
        _hotelError = '${r['message'] ?? r['error'] ?? 'Hotel not found'}';
      }
    });
  }

  Future<void> _pickDates() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange:
          _stay ??
          DateTimeRange(
            start: now.add(const Duration(days: 1)),
            end: now.add(const Duration(days: 2)),
          ),
      helpText: 'Select check-in and check-out',
    );
    if (picked == null || !mounted) return;
    if (picked.end.difference(picked.start).inDays < 1) {
      _snack('Check-out must be at least one night after check-in');
      return;
    }
    setState(() => _stay = picked);
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final stay = _stay;
    if (stay == null) return;
    setState(() {
      _checking = true;
      _availabilityError = null;
      _selectedRoomTypeId = null;
    });
    final r = await ApiService.getRequest(
      '/hotels/${widget.hotelId}/availability'
      '?check_in=${_dateFmt.format(stay.start)}'
      '&check_out=${_dateFmt.format(stay.end)}'
      '&guests=$_guests&rooms=$_rooms',
      auth: false,
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (r['success'] == true) {
        _roomTypes = [
          for (final x in (r['room_types'] as List? ?? const []))
            if (x is Map) Map<String, dynamic>.from(x),
        ];
        final firstFree = _roomTypes.where((x) => x['available'] == true);
        _selectedRoomTypeId = firstFree.isEmpty
            ? null
            : asInt(firstFree.first['room_type_id']);
      } else {
        _roomTypes = [];
        _availabilityError =
            '${r['message'] ?? r['error'] ?? 'Could not check availability'}';
      }
    });
  }

  Map<String, dynamic>? get _selectedRoom {
    for (final x in _roomTypes) {
      if (asInt(x['room_type_id']) == _selectedRoomTypeId) return x;
    }
    return null;
  }

  Future<void> _book() async {
    final room = _selectedRoom;
    final stay = _stay;
    if (room == null || stay == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final r = await ApiService.postRequest('/hotels/bookings', {
      'hotel_id': widget.hotelId,
      'room_type_id': _selectedRoomTypeId,
      'check_in': _dateFmt.format(stay.start),
      'check_out': _dateFmt.format(stay.end),
      'guests': _guests,
      'rooms': _rooms,
      'contact_name': _nameCtrl.text.trim(),
      'contact_phone': _phoneCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r['success'] != true) {
      _snack('${r['message'] ?? r['error'] ?? 'Booking failed'}');
      if (r['status'] == 409) _checkAvailability();
      return;
    }
    final bookingId = asInt(r['booking_id'])!;
    final reference = '${r['booking_reference'] ?? '#$bookingId'}';
    final quote = (r['quote'] as Map?) ?? const {};
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          bookingId: bookingId,
          destinationName: '${widget.hotelName} — ${room['name']}',
          durationDays: asInt(quote['nights']) ?? 1,
          numTravelers: _guests,
          pricePerDay: 0,
          totalAmount: asDouble(r['total_amount']) ?? 0,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paid == true
              ? 'Booking $reference confirmed!'
              : 'Booking $reference is reserved for 30 minutes — pay from My Bookings to confirm.',
        ),
        backgroundColor: paid == true ? Colors.green : null,
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final hotel = _hotel;
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(title: Text(widget.hotelName)),
      body: hotel == null
          ? Center(
              child: _hotelError != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_hotelError!, textAlign: TextAlign.center),
                    )
                  : const CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _hotelInfo(hotel),
                  const SizedBox(height: 16),
                  _staySelector(),
                  const SizedBox(height: 16),
                  if (_checking)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_availabilityError != null)
                    _notice(_availabilityError!, Colors.red)
                  else if (_stay != null)
                    ..._roomTypes.map(_roomCard),
                  if (_selectedRoom != null) ...[
                    const SizedBox(height: 8),
                    _summary(_selectedRoom!),
                    const SizedBox(height: 16),
                    _contactFields(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitting ? null : _book,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reserve & continue to payment'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _hotelInfo(Map<String, dynamic> h) {
    final amenities = (h['amenities'] as List? ?? const []).map((e) => '$e');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${h['address'] ?? h['city'] ?? ''}',
              style: const TextStyle(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: 8),
            Text(
              'Check-in from ${h['check_in_time'] ?? '14:00'} · '
              'Check-out by ${h['check_out_time'] ?? '12:00'}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Free cancellation until ${h['free_cancel_hours'] ?? 48} hours '
              'before check-in.',
              style: const TextStyle(fontSize: 13),
            ),
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: amenities
                    .map(
                      (a) => Chip(
                        label: Text(a, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (h['inventory_source'] == 'internal') ...[
              const SizedBox(height: 8),
              const Text(
                'Rates and room availability are managed by SafarSync '
                '(not live hotel-supplier data).',
                style: TextStyle(fontSize: 11, color: AppTheme.mediumGray),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _staySelector() {
    final stay = _stay;
    final nights = stay == null ? 0 : stay.end.difference(stay.start).inDays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDates,
              icon: const Icon(Icons.date_range),
              label: Text(
                stay == null
                    ? 'Select check-in & check-out'
                    : '${DateFormat('d MMM').format(stay.start)} → '
                          '${DateFormat('d MMM yyyy').format(stay.end)} · '
                          '$nights night${nights == 1 ? '' : 's'}',
              ),
            ),
            const SizedBox(height: 12),
            _stepper('Guests', _guests, 1, 20, (v) {
              setState(() => _guests = v);
              _checkAvailability();
            }),
            _stepper('Rooms', _rooms, 1, 10, (v) {
              setState(() => _rooms = v);
              _checkAvailability();
            }),
          ],
        ),
      ),
    );
  }

  Widget _stepper(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Fewer $label',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'More $label',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _roomCard(Map<String, dynamic> rt) {
    final id = asInt(rt['room_type_id']);
    final available = rt['available'] == true;
    final quote = (rt['quote'] as Map?) ?? const {};
    final nights = asInt(quote['nights']) ?? 1;
    final total = asDouble(quote['total']) ?? 0;
    final selected = id == _selectedRoomTypeId;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.turquoise : AppTheme.veryLightGray,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: available
            ? () => setState(() => _selectedRoomTypeId = id)
            : null,
        child: Opacity(
          opacity: available ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: available ? AppTheme.turquoise : AppTheme.mediumGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rt['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Up to ${rt['max_guests']} guests per room',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        available
                            ? '${rt['rooms_available']} room(s) left'
                            : '${rt['unavailable_reason'] ?? 'Unavailable'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: available ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PKR ${_money.format(total)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.turquoise,
                      ),
                    ),
                    Text(
                      '$nights night${nights == 1 ? '' : 's'} · incl. taxes',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(Map<String, dynamic> rt) {
    final q = (rt['quote'] as Map?) ?? const {};
    final taxRate = ((asDouble(q['tax_rate']) ?? 0) * 100).toStringAsFixed(0);
    final fee = asDouble(q['service_fee']) ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _line(
              'Room × ${q['rooms']} × ${q['nights']} night(s)',
              asDouble(q['room_subtotal']),
            ),
            if (fee > 0) _line('Service fee', fee),
            _line('Tax ($taxRate%)', asDouble(q['tax'])),
            const Divider(),
            _line('Total', asDouble(q['total']), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, double? value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('PKR ${_money.format(value ?? 0)}', style: style),
        ],
      ),
    );
  }

  Widget _contactFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Guest name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? 'Enter the guest name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  RegExp(r'^[+\d][\d\s-]{6,19}$').hasMatch((v ?? '').trim())
                  ? null
                  : 'Enter a valid phone number',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Special requests (optional)',
              ),
              maxLines: 2,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice(String text, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: TextStyle(color: color)),
  );
}
