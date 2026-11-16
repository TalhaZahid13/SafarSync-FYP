import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/api_service.dart';
import '../utils/safe_parse.dart';

// Admin management for the SafarSync-managed hotel & restaurant inventory:
// hotels, room types, nightly/weekend/seasonal prices, room inventory,
// cancellation policy, taxes; restaurants, opening hours, seat capacity;
// and every stay / reservation. All writes go through the /admin API.

final _money = NumberFormat('#,##0');

void _toast(BuildContext context, Map<String, dynamic> r, String ok) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        r['success'] == true
            ? ok
            : '${r['error'] ?? r['message'] ?? 'Request failed'}',
      ),
      backgroundColor: r['success'] == true ? Colors.green : Colors.red,
    ),
  );
}

// ── Generic edit form ─────────────────────────────────────────────────────────
enum _Kind { text, number, toggle }

class _Field {
  final String key;
  final String label;
  final _Kind kind;
  final Object? initial;
  final String? hint;
  const _Field(this.key, this.label, this.kind, this.initial, {this.hint});
}

/// Shows a form; returns only the fields the admin changed (null = cancelled).
Future<Map<String, dynamic>?> _editForm(
  BuildContext context,
  String title,
  List<_Field> fields,
) {
  final ctrls = {
    for (final f in fields)
      if (f.kind != _Kind.toggle)
        f.key: TextEditingController(text: f.initial?.toString() ?? ''),
  };
  final toggles = {
    for (final f in fields)
      if (f.kind == _Kind.toggle) f.key: f.initial == true,
  };
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in fields)
                  f.kind == _Kind.toggle
                      ? SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(f.label),
                          value: toggles[f.key]!,
                          onChanged: (v) => setD(() => toggles[f.key] = v),
                        )
                      : TextField(
                          controller: ctrls[f.key],
                          keyboardType: f.kind == _Kind.number
                              ? const TextInputType.numberWithOptions(
                                  decimal: true,
                                )
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: f.label,
                            helperText: f.hint,
                          ),
                        ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final out = <String, dynamic>{};
              for (final f in fields) {
                if (f.kind == _Kind.toggle) {
                  if (toggles[f.key] != (f.initial == true)) {
                    out[f.key] = toggles[f.key];
                  }
                  continue;
                }
                final t = ctrls[f.key]!.text.trim();
                if (t == (f.initial?.toString() ?? '')) continue;
                out[f.key] = f.kind == _Kind.number
                    ? (t.isEmpty ? null : num.tryParse(t))
                    : (t.isEmpty ? null : t);
              }
              Navigator.pop(ctx, out);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════ HOTELS ═══════════════════════════════════════
class AdminHotelsTab extends StatelessWidget {
  const AdminHotelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Hotels & rooms'),
              Tab(text: 'Stays'),
            ],
          ),
          Expanded(
            child: TabBarView(children: [_HotelInventory(), _HotelStays()]),
          ),
        ],
      ),
    );
  }
}

class _HotelInventory extends StatefulWidget {
  const _HotelInventory();
  @override
  State<_HotelInventory> createState() => _HotelInventoryState();
}

class _HotelInventoryState extends State<_HotelInventory> {
  List<Map<String, dynamic>> _hotels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.getRequest('/admin/hotels');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hotels = [
        for (final h in (r['hotels'] as List? ?? const []))
          if (h is Map) Map<String, dynamic>.from(h),
      ];
    });
  }

  List<_Field> _hotelFields(Map<String, dynamic> h) => [
    _Field('name', 'Name', _Kind.text, h['name']),
    _Field('address', 'Address', _Kind.text, h['address']),
    _Field('city', 'City', _Kind.text, h['city']),
    _Field(
      'category',
      'Category',
      _Kind.text,
      h['category'],
      hint: 'Luxury / Boutique / Budget',
    ),
    _Field('image_url', 'Image URL', _Kind.text, h['image_url']),
    _Field('rating', 'Rating (0–5)', _Kind.number, h['rating']),
    _Field(
      'check_in_time',
      'Check-in time',
      _Kind.text,
      h['check_in_time'],
      hint: 'HH:MM',
    ),
    _Field(
      'check_out_time',
      'Check-out time',
      _Kind.text,
      h['check_out_time'],
      hint: 'HH:MM',
    ),
    _Field(
      'free_cancel_hours',
      'Free cancellation (hours before check-in)',
      _Kind.number,
      h['free_cancel_hours'],
    ),
    _Field(
      'tax_rate',
      'Tax rate',
      _Kind.number,
      h['tax_rate'],
      hint: '0.10 = 10%',
    ),
    _Field(
      'service_fee_rate',
      'Service fee rate',
      _Kind.number,
      h['service_fee_rate'],
      hint: '0.05 = 5%',
    ),
    _Field('is_active', 'Visible to users', _Kind.toggle, h['is_active']),
  ];

  List<_Field> _roomFields(Map<String, dynamic> rt) => [
    _Field('name', 'Room type name', _Kind.text, rt['name']),
    _Field('description', 'Description', _Kind.text, rt['description']),
    _Field('max_guests', 'Max guests per room', _Kind.number, rt['max_guests']),
    _Field(
      'base_price_per_night',
      'Price per night (PKR)',
      _Kind.number,
      rt['base_price_per_night'],
    ),
    _Field(
      'weekend_price_per_night',
      'Fri/Sat night price (PKR, optional)',
      _Kind.number,
      rt['weekend_price_per_night'],
    ),
    _Field(
      'total_rooms',
      'Rooms in inventory',
      _Kind.number,
      rt['total_rooms'],
    ),
    _Field('is_active', 'Bookable', _Kind.toggle, rt['is_active'] ?? true),
  ];

  Future<void> _addHotel() async {
    final v = await _editForm(
      context,
      'Add hotel',
      _hotelFields({'is_active': true}),
    );
    if (v == null || !mounted) return;
    final r = await ApiService.postRequest('/admin/hotels', v);
    if (!mounted) return;
    _toast(context, r, 'Hotel added — now add its room types');
    _load();
  }

  Future<void> _editHotel(Map<String, dynamic> h) async {
    final v = await _editForm(context, 'Edit ${h['name']}', _hotelFields(h));
    if (v == null || v.isEmpty || !mounted) return;
    final r = await ApiService.putRequest('/admin/hotels/${h['hotel_id']}', v);
    if (!mounted) return;
    _toast(context, r, 'Hotel updated');
    _load();
  }

  Future<void> _addRoom(Map<String, dynamic> h) async {
    final v = await _editForm(
      context,
      'Add room type',
      _roomFields({'max_guests': 2}),
    );
    if (v == null || !mounted) return;
    final r = await ApiService.postRequest(
      '/admin/hotels/${h['hotel_id']}/rooms',
      v,
    );
    if (!mounted) return;
    _toast(context, r, 'Room type added');
    _load();
  }

  Future<void> _editRoom(Map<String, dynamic> rt) async {
    final v = await _editForm(context, 'Edit ${rt['name']}', _roomFields(rt));
    if (v == null || v.isEmpty || !mounted) return;
    final r = await ApiService.putRequest(
      '/admin/rooms/${rt['room_type_id']}',
      v,
    );
    if (!mounted) return;
    _toast(context, r, 'Room type updated');
    _load();
  }

  Future<void> _addRate(Map<String, dynamic> rt) async {
    final v = await _editForm(context, 'Seasonal price', [
      const _Field('label', 'Label', _Kind.text, null, hint: 'e.g. Eid peak'),
      const _Field('starts_on', 'From', _Kind.text, null, hint: 'YYYY-MM-DD'),
      const _Field(
        'ends_on',
        'To (inclusive)',
        _Kind.text,
        null,
        hint: 'YYYY-MM-DD',
      ),
      const _Field(
        'price_per_night',
        'Price per night (PKR)',
        _Kind.number,
        null,
      ),
    ]);
    if (v == null || !mounted) return;
    final r = await ApiService.postRequest(
      '/admin/rooms/${rt['room_type_id']}/rates',
      v,
    );
    if (!mounted) return;
    _toast(context, r, 'Seasonal price added');
    _load();
  }

  Future<void> _deleteRate(Map<String, dynamic> rate) async {
    final r = await ApiService.deleteRequest('/admin/rates/${rate['rate_id']}');
    if (!mounted) return;
    _toast(context, r, 'Seasonal price removed');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SafarSync-managed inventory: prices and room counts '
                  'are what users can book.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addHotel,
                icon: const Icon(Icons.add),
                label: const Text('Hotel'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final h in _hotels)
            Card(
              child: ExpansionTile(
                title: Text(
                  '${h['name']}${h['is_active'] == true ? '' : ' (hidden)'}',
                ),
                subtitle: Text(
                  '${h['city'] ?? ''} · ${h['category'] ?? ''} · tax '
                  '${((asDouble(h['tax_rate']) ?? 0) * 100).toStringAsFixed(0)}% · '
                  'free cancel ${h['free_cancel_hours']}h',
                ),
                trailing: IconButton(
                  tooltip: 'Edit hotel',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editHotel(h),
                ),
                children: [
                  for (final rt in (h['room_types'] as List? ?? const []))
                    if (rt is Map) _roomTile(Map<String, dynamic>.from(rt)),
                  TextButton.icon(
                    onPressed: () => _addRoom(h),
                    icon: const Icon(Icons.add),
                    label: const Text('Add room type'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _roomTile(Map<String, dynamic> rt) {
    final rates = (rt['seasonal_rates'] as List? ?? const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
    final weekend = asDouble(rt['weekend_price_per_night']);
    return ListTile(
      title: Text(
        '${rt['name']}${rt['is_active'] == true ? '' : ' (not bookable)'}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PKR ${_money.format(asDouble(rt['base_price_per_night']) ?? 0)}/night'
            '${weekend != null ? ' · Fri/Sat ${_money.format(weekend)}' : ''}'
            ' · ${rt['total_rooms']} rooms · max ${rt['max_guests']} guests',
          ),
          for (final rate in rates)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${rate['label'] ?? 'Season'}: ${rate['starts_on']} → '
                    '${rate['ends_on']} · PKR '
                    '${_money.format(asDouble(rate['price_per_night']) ?? 0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove seasonal price',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _deleteRate(rate),
                ),
              ],
            ),
        ],
      ),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: 'Add seasonal price',
            icon: const Icon(Icons.event_note),
            onPressed: () => _addRate(rt),
          ),
          IconButton(
            tooltip: 'Edit room type',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editRoom(rt),
          ),
        ],
      ),
    );
  }
}

class _HotelStays extends StatefulWidget {
  const _HotelStays();
  @override
  State<_HotelStays> createState() => _HotelStaysState();
}

class _HotelStaysState extends State<_HotelStays> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.getRequest(
      '/admin/hotel-bookings${_status != null ? '?status=${Uri.encodeQueryComponent(_status!)}' : ''}',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rows = [
        for (final b in (r['bookings'] as List? ?? const []))
          if (b is Map) Map<String, dynamic>.from(b),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['Confirmed', 'Awaiting Payment', 'Pending', 'Cancelled'];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _status == null,
                onSelected: (_) {
                  setState(() => _status = null);
                  _load();
                },
              ),
              for (final s in statuses)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: _status == s,
                    onSelected: (_) {
                      setState(() => _status = s);
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
              ? const Center(child: Text('No stays yet.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final b = _rows[i];
                      return ListTile(
                        title: Text(
                          '${b['hotel_name']} · ${b['room_name']} '
                          '(${b['booking_reference']})',
                        ),
                        subtitle: Text(
                          '${b['check_in']} → ${b['check_out']} · '
                          '${b['rooms']} room(s), ${b['guests']} guest(s)\n'
                          '${b['contact_name'] ?? b['full_name']} · '
                          '${b['contact_phone'] ?? b['email']}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${b['status']}'),
                            Text(
                              'PKR ${_money.format(asDouble(b['total_amount']) ?? 0)} · ${b['payment_status']}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════ RESTAURANTS ══════════════════════════════════
class AdminRestaurantsTab extends StatelessWidget {
  const AdminRestaurantsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Restaurants'),
              Tab(text: 'Reservations'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_RestaurantInventory(), _Reservations()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantInventory extends StatefulWidget {
  const _RestaurantInventory();
  @override
  State<_RestaurantInventory> createState() => _RestaurantInventoryState();
}

class _RestaurantInventoryState extends State<_RestaurantInventory> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.getRequest('/admin/restaurants');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rows = [
        for (final x in (r['restaurants'] as List? ?? const []))
          if (x is Map) Map<String, dynamic>.from(x),
      ];
    });
  }

  /// "12:00-23:00" for every open day; closed days listed separately.
  (String, String) _hoursSummary(Map<String, dynamic> x) {
    final hours = (x['opening_hours'] as Map?) ?? const {};
    String range = '';
    final closed = <String>[];
    for (final d in _days) {
      final list = hours[d] as List?;
      if (list == null || list.isEmpty) {
        closed.add(d);
      } else if (range.isEmpty) {
        final first = list.first as Map;
        range = '${first['open']}-${first['close']}';
      }
    }
    return (range, closed.join(','));
  }

  List<_Field> _fields(Map<String, dynamic> x) {
    final (range, closed) = _hoursSummary(x);
    return [
      _Field('name', 'Name', _Kind.text, x['name']),
      _Field('address', 'Address', _Kind.text, x['address']),
      _Field('city', 'City', _Kind.text, x['city']),
      _Field('phone', 'Phone', _Kind.text, x['phone']),
      _Field('cuisine', 'Cuisine', _Kind.text, x['cuisine']),
      _Field(
        'cuisine_tag',
        'Cuisine filter tag',
        _Kind.text,
        x['cuisine_tag'],
        hint: 'Pakistani / BBQ / Continental / Fast Food',
      ),
      _Field('image_url', 'Image URL', _Kind.text, x['image_url']),
      _Field(
        'avg_price_per_person',
        'Average price per person (PKR)',
        _Kind.number,
        x['avg_price_per_person'],
      ),
      _Field(
        '_hours',
        'Opening hours (daily)',
        _Kind.text,
        range,
        hint: 'HH:MM-HH:MM, e.g. 12:00-23:00',
      ),
      _Field(
        '_closed',
        'Closed days',
        _Kind.text,
        closed,
        hint: 'comma list: mon,tue,… (blank = open daily)',
      ),
      _Field(
        'seats_per_slot',
        'Seats per time slot',
        _Kind.number,
        x['seats_per_slot'],
      ),
      _Field(
        'slot_minutes',
        'Slot length (15/30/60 min)',
        _Kind.number,
        x['slot_minutes'] ?? 30,
      ),
      _Field(
        'max_party_size',
        'Max party size',
        _Kind.number,
        x['max_party_size'] ?? 10,
      ),
      _Field(
        'reservation_policy',
        'Reservation policy',
        _Kind.text,
        x['reservation_policy'],
      ),
      _Field(
        'accepts_reservations',
        'Takes reservations',
        _Kind.toggle,
        x['accepts_reservations'] ?? true,
      ),
      _Field(
        'is_active',
        'Visible to users',
        _Kind.toggle,
        x['is_active'] ?? true,
      ),
    ];
  }

  /// Turns the simple hours/closed-days fields into opening_hours JSON.
  Map<String, dynamic>? _withHours(
    Map<String, dynamic> v,
    Map<String, dynamic> current,
  ) {
    if (!v.containsKey('_hours') && !v.containsKey('_closed')) return v;
    final (curRange, curClosed) = _hoursSummary(current);
    final range = (v.remove('_hours') ?? curRange)?.toString() ?? '';
    final closed = ((v.remove('_closed') ?? curClosed)?.toString() ?? '')
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final m = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)-([01]\d|2[0-3]):([0-5]\d)$',
    ).firstMatch(range);
    if (m == null) return null;
    final open = range.split('-')[0], close = range.split('-')[1];
    v['opening_hours'] = {
      for (final d in _days)
        d: closed.contains(d)
            ? []
            : [
                {'open': open, 'close': close},
              ],
    };
    return v;
  }

  Future<void> _save(Map<String, dynamic>? current) async {
    final base = current ?? {'is_active': true, 'accepts_reservations': true};
    final raw = await _editForm(
      context,
      current == null ? 'Add restaurant' : 'Edit ${current['name']}',
      _fields(base),
    );
    if (raw == null || raw.isEmpty || !mounted) return;
    final v = _withHours(raw, base);
    if (v == null) {
      _toast(context, {
        'success': false,
        'error': 'Opening hours must look like 12:00-23:00',
      }, '');
      return;
    }
    final r = current == null
        ? await ApiService.postRequest('/admin/restaurants', v)
        : await ApiService.putRequest(
            '/admin/restaurants/${current['restaurant_id']}',
            v,
          );
    if (!mounted) return;
    _toast(context, r, 'Restaurant saved');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _save(null),
              icon: const Icon(Icons.add),
              label: const Text('Restaurant'),
            ),
          ),
          for (final x in _rows)
            Card(
              child: ListTile(
                title: Text(
                  '${x['name']}${x['is_active'] == true ? '' : ' (hidden)'}',
                ),
                subtitle: Text(
                  '${x['city'] ?? ''} · ${x['cuisine'] ?? ''}\n'
                  '${x['accepts_reservations'] == true ? 'Hours ${_hoursSummary(x).$1}'
                            '${_hoursSummary(x).$2.isNotEmpty ? ' (closed ${_hoursSummary(x).$2})' : ''}'
                            ' · ${x['seats_per_slot']} seats / ${x['slot_minutes']} min' : 'Walk-in only'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Edit restaurant',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _save(x),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Reservations extends StatefulWidget {
  const _Reservations();
  @override
  State<_Reservations> createState() => _ReservationsState();
}

class _ReservationsState extends State<_Reservations> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = _date == null
        ? ''
        : '?date=${DateFormat('yyyy-MM-dd').format(_date!)}';
    final r = await ApiService.getRequest('/admin/reservations$q');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _rows = [
        for (final x in (r['reservations'] as List? ?? const []))
          if (x is Map) Map<String, dynamic>.from(x),
      ];
    });
  }

  Future<void> _setStatus(Map<String, dynamic> x, String status) async {
    final r = await ApiService.putRequest(
      '/admin/reservations/${x['booking_id']}/status',
      {'status': status},
    );
    if (!mounted) return;
    _toast(context, r, 'Reservation $status');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (d == null) return;
                  setState(() => _date = d);
                  _load();
                },
                icon: const Icon(Icons.event),
                label: Text(
                  _date == null
                      ? 'All dates'
                      : DateFormat('EEE d MMM').format(_date!),
                ),
              ),
              if (_date != null)
                TextButton(
                  onPressed: () {
                    setState(() => _date = null);
                    _load();
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
              ? const Center(child: Text('No reservations.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (_, i) {
                      final x = _rows[i];
                      final status = '${x['status']}';
                      return ListTile(
                        title: Text(
                          '${x['restaurant_name']} · ${x['local_time']} '
                          '(${x['booking_reference']})',
                        ),
                        subtitle: Text(
                          'Party of ${x['party_size']}'
                          '${x['seating_preference'] != null ? ' · ${x['seating_preference']}' : ''}'
                          '\n${x['contact_name'] ?? x['full_name']} · ${x['contact_phone'] ?? x['email']}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Change status',
                          onSelected: (s) => _setStatus(x, s),
                          itemBuilder: (_) => [
                            for (final s in [
                              'Confirmed',
                              'Completed',
                              'Cancelled',
                            ])
                              if (s != status)
                                PopupMenuItem(value: s, child: Text(s)),
                          ],
                          child: Chip(label: Text(status)),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
