import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';
import '../utils/user_profile_provider.dart';

/// Free table reservation. Opening hours, time slots and seat capacity come
/// from the API; the server re-checks capacity atomically when confirming.
class RestaurantReservationPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantReservationPage({super.key, required this.restaurant});

  @override
  State<RestaurantReservationPage> createState() =>
      _RestaurantReservationPageState();
}

class _RestaurantReservationPageState extends State<RestaurantReservationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateFmt = DateFormat('yyyy-MM-dd');

  late DateTime _date;
  int _party = 2;
  String? _seating;
  String? _time;
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  String? _slotError;
  bool _submitting = false;

  int get _restaurantId => asInt(widget.restaurant['restaurant_id'])!;
  int get _maxParty => asInt(widget.restaurant['max_party_size']) ?? 10;
  List<String> get _seatingOptions => [
    for (final s in (widget.restaurant['seating_options'] as List? ?? const []))
      '$s',
  ];

  @override
  void initState() {
    super.initState();
    _date = DateUtils.dateOnly(DateTime.now());
    final profile = context.read<UserProfileProvider>();
    _nameCtrl.text = profile.fullName ?? '';
    _phoneCtrl.text = '${profile.profile?['phone_number'] ?? ''}';
    if (_seatingOptions.isNotEmpty) _seating = _seatingOptions.first;
    _loadSlots();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _slotError = null;
      _time = null;
    });
    final r = await ApiService.getRequest(
      '/restaurants/$_restaurantId/availability'
      '?date=${_dateFmt.format(_date)}&party_size=$_party',
      auth: false,
    );
    if (!mounted) return;
    setState(() {
      _loadingSlots = false;
      if (r['success'] == true) {
        _slots = [
          for (final s in (r['slots'] as List? ?? const []))
            if (s is Map) Map<String, dynamic>.from(s),
        ];
        if (r['open'] != true) _slotError = 'Closed on this day.';
      } else {
        _slots = [];
        _slotError = '${r['message'] ?? r['error'] ?? 'Could not load times'}';
      }
    });
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Reservation date',
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    _loadSlots();
  }

  Future<void> _confirm() async {
    if (_time == null) {
      _snack('Please choose a time');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final r = await ApiService.postRequest('/restaurants/reservations', {
      'restaurant_id': _restaurantId,
      'date': _dateFmt.format(_date),
      'time': _time,
      'party_size': _party,
      if (_seating != null) 'seating_preference': _seating,
      'contact_name': _nameCtrl.text.trim(),
      'contact_phone': _phoneCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r['success'] != true) {
      _snack('${r['message'] ?? r['error'] ?? 'Reservation failed'}');
      if (r['status'] == 409) _loadSlots();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Table reserved'),
        content: Text(
          '${widget.restaurant['name']}\n'
          '${DateFormat('EEE d MMM yyyy').format(_date)} at $_time\n'
          'Party of $_party${_seating != null ? ' · $_seating' : ''}\n\n'
          'Reference: ${r['booking_reference'] ?? '#${r['booking_id']}'}\n'
          'You can view or cancel it in My Bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final rest = widget.restaurant;
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(title: Text('Reserve · ${rest['name']}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rest['location'] ?? ''}',
                      style: const TextStyle(color: AppTheme.mediumGray),
                    ),
                    if ((rest['reservation_policy'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${rest['reservation_policy']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (rest['inventory_source'] == 'internal') ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Opening hours and table availability are managed by '
                        'SafarSync (not live restaurant-system data).',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event),
                      label: Text(DateFormat('EEE d MMM yyyy').format(_date)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('Party size')),
                        IconButton(
                          tooltip: 'Fewer guests',
                          onPressed: _party > 1
                              ? () {
                                  setState(() => _party--);
                                  _loadSlots();
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$_party',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'More guests',
                          onPressed: _party < _maxParty
                              ? () {
                                  setState(() => _party++);
                                  _loadSlots();
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    if (_seatingOptions.length > 1)
                      DropdownButtonFormField<String>(
                        initialValue: _seating,
                        decoration: const InputDecoration(
                          labelText: 'Seating preference',
                        ),
                        items: _seatingOptions
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _seating = v),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Available times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_loadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_slotError != null)
              Text(_slotError!, style: const TextStyle(color: Colors.red))
            else if (!_slots.any((s) => s['available'] == true))
              const Text('No tables left for this party size on this day.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slots.map((s) {
                  final t = '${s['time']}';
                  final ok = s['available'] == true;
                  return ChoiceChip(
                    label: Text(t),
                    selected: _time == t,
                    onSelected: ok ? (_) => setState(() => _time = t) : null,
                    tooltip: ok
                        ? '${s['remaining']} seats left'
                        : 'Unavailable',
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v ?? '').trim().length < 2 ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          RegExp(
                            r'^[+\d][\d\s-]{6,19}$',
                          ).hasMatch((v ?? '').trim())
                          ? null
                          : 'Enter a valid phone number',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 2,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting || _time == null ? null : _confirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _time == null
                          ? 'Choose a time'
                          : 'Confirm table for $_party at $_time',
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
