import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/api_service.dart';
import '../utils/safe_parse.dart';
import '../utils/notification_service.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const _kCountdownSeconds = 3;
const _kRedDark = Color(0xFF7B0000);
const _kRedMid = Color(0xFFB71C1C);
const _kRedBright = Color(0xFFE53935);

class EmergencySOSScreen extends StatefulWidget {
  /// When true the 3-second countdown begins automatically once the screen
  /// finishes loading. Used when the app is launched from the Quick Settings tile.
  final bool autoStart;

  const EmergencySOSScreen({super.key, this.autoStart = false});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _triggering = false;

  Map<String, dynamic>? _activeAlert;
  List<Map<String, dynamic>> _alertHistory = [];
  List<Map<String, dynamic>> _activeGroups = [];

  double? _lat;
  double? _lng;
  String _locationLabel = 'Fetching location…';

  int? _selectedTripId;
  String? _selectedTripType;
  final _messageCtrl = TextEditingController();

  // ── Countdown animation ────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _countdownCtrl;
  late final Animation<double> _pulseAnim;

  bool _isHolding = false;
  Timer? _countdownTimer;
  double _countdownProgress = 0.0; // 0.0 → 1.0
  int _countdownRemaining = _kCountdownSeconds;

  // ── User info ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _countdownCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _kCountdownSeconds),
    );

    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _fetchLocation(),
      _loadActiveAlert(),
      _loadAlertHistory(),
      _loadActiveGroups(),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);

    // Launched from Android Quick Settings tile — begin countdown automatically
    if (widget.autoStart && _activeAlert == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeAlert == null) _onHoldStart();
      });
    }
  }

  // ── GPS ────────────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _locationLabel = 'Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _locationLabel =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _locationLabel = 'Could not get location');
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadActiveAlert() async {
    try {
      final resp = await ApiService.getRequest('/emergency/active');
      if (mounted && resp['success'] == true) {
        setState(() => _activeAlert = resp['alert']);
      }
    } catch (_) {}
  }

  Future<void> _loadAlertHistory() async {
    try {
      final resp = await ApiService.getRequest('/emergency/my-alerts');
      if (mounted && resp['success'] == true) {
        final list = List<Map<String, dynamic>>.from(
          (resp['alerts'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
        );
        setState(() => _alertHistory = list);
      }
    } catch (_) {}
  }

  Future<void> _loadActiveGroups() async {
    try {
      final resp = await ApiService.getRequest('/group-bookings/list');
      if (mounted && resp['success'] == true) {
        final all = (resp['group_bookings'] as List?) ?? [];
        setState(() {
          _activeGroups = all
              .where((g) => g['status'] == 'Active')
              .map((g) => Map<String, dynamic>.from(g))
              .toList();
        });
      }
    } catch (_) {}
  }

  // ── Countdown logic ────────────────────────────────────────────────────────
  void _onHoldStart() {
    if (_activeAlert != null) return; // already active
    HapticFeedback.heavyImpact();
    setState(() {
      _isHolding = true;
      _countdownProgress = 0.0;
      _countdownRemaining = _kCountdownSeconds;
    });
    _countdownCtrl.forward(from: 0.0);

    int ticks = 0;
    const totalTicks = _kCountdownSeconds * 10; // 100 ms each
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      ticks++;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdownProgress = ticks / totalTicks;
        _countdownRemaining = _kCountdownSeconds - (ticks ~/ 10);
      });
      if (ticks >= totalTicks) {
        t.cancel();
        _triggerSOS();
      }
    });
  }

  void _onHoldEnd() {
    if (!_isHolding) return;
    _countdownTimer?.cancel();
    _countdownCtrl.stop();
    HapticFeedback.lightImpact();
    setState(() {
      _isHolding = false;
      _countdownProgress = 0.0;
      _countdownRemaining = _kCountdownSeconds;
    });
  }

  // ── Trigger ────────────────────────────────────────────────────────────────
  Future<void> _triggerSOS() async {
    if (!mounted) return;
    HapticFeedback.vibrate();
    setState(() {
      _isHolding = false;
      _triggering = true;
    });

    try {
      final body = <String, dynamic>{
        'latitude': _lat ?? 0,
        'longitude': _lng ?? 0,
      };
      if (_messageCtrl.text.trim().isNotEmpty) {
        body['message'] = _messageCtrl.text.trim();
      }
      if (_selectedTripId != null) {
        body['trip_id'] = _selectedTripId;
        body['trip_type'] = _selectedTripType ?? 'group';
      }

      final resp = await ApiService.postRequest('/emergency/trigger', body);
      if (!mounted) return;

      if (resp['success'] == true) {
        HapticFeedback.vibrate();
        _messageCtrl.clear();
        // Show system tray push notification immediately
        NotificationService.instance.showSOSSent();
        await Future.wait([_loadActiveAlert(), _loadAlertHistory()]);
        _showSOSTriggeredBanner();
      } else {
        _showError(resp['message'] ?? 'Failed to send SOS');
      }
    } catch (e) {
      if (mounted) _showError('Network error: $e');
    } finally {
      if (mounted) setState(() => _triggering = false);
    }
  }

  // ── Resolve ────────────────────────────────────────────────────────────────
  Future<void> _resolveAlert() async {
    if (_activeAlert == null) return;
    final alertId = _activeAlert!['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Resolved?'),
        content: const Text(
          'This confirms the emergency has been handled. '
          'Your alert will be marked resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Resolved',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final resp =
        await ApiService.putRequest('/emergency/$alertId/resolve', {});
    if (!mounted) return;
    if (resp['success'] == true) {
      NotificationService.instance.showSOSResolved();
      await Future.wait([_loadActiveAlert(), _loadAlertHistory()]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency marked as resolved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────
  Future<void> _cancelAlert() async {
    if (_activeAlert == null) return;
    final alertId = _activeAlert!['id'];
    final resp =
        await ApiService.putRequest('/emergency/$alertId/cancel', {});
    if (!mounted) return;
    if (resp['success'] == true) {
      await Future.wait([_loadActiveAlert(), _loadAlertHistory()]);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  void _showSOSTriggeredBanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _kRedMid,
        duration: const Duration(seconds: 4),
        content: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'SOS ACTIVATED — Emergency contacts notified',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Emergency SOS',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _kRedMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kRedMid))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                children: [
                  // ── Quick-Settings tile banner ─────────────────────────
                  if (widget.autoStart && _activeAlert == null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kRedMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.quick_contacts_dialer, color: Colors.white, size: 16),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Launched from Quick Settings — SOS countdown starting automatically. Tap anywhere to cancel.',
                              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Active alert banner ────────────────────────────────
                  if (_activeAlert != null) _ActiveAlertCard(
                    alert: _activeAlert!,
                    onResolve: _resolveAlert,
                    onCancel: _cancelAlert,
                  ),

                  if (_activeAlert != null) const SizedBox(height: 16),

                  // ── SOS button card ────────────────────────────────────
                  _SOSButtonCard(
                    isHolding: _isHolding,
                    isTriggering: _triggering,
                    hasActiveAlert: _activeAlert != null,
                    countdownProgress: _countdownProgress,
                    countdownRemaining: _countdownRemaining,
                    pulseAnim: _pulseAnim,
                    onHoldStart: _onHoldStart,
                    onHoldEnd: _onHoldEnd,
                    locationLabel: _locationLabel,
                    onRefreshLocation: _fetchLocation,
                  ),

                  const SizedBox(height: 16),

                  // ── Optional details ───────────────────────────────────
                  if (_activeAlert == null)
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Optional Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 12),

                            // Trip selector
                            if (_activeGroups.isNotEmpty) ...[
                              DropdownButtonFormField<int?>(
                                value: _selectedTripId,
                                decoration: InputDecoration(
                                  labelText: 'Attach to active trip',
                                  prefixIcon: const Icon(Icons.directions_bus),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('No trip'),
                                  ),
                                  ..._activeGroups.map((g) =>
                                      DropdownMenuItem<int?>(
                                        value: g['group_booking_id'] as int?,
                                        child: Text(
                                          g['trip_name'] as String? ??
                                              'Trip #${g['group_booking_id']}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                ],
                                onChanged: (v) => setState(() {
                                  _selectedTripId = v;
                                  _selectedTripType = v != null ? 'group' : null;
                                }),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Message
                            TextField(
                              controller: _messageCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Emergency message (optional)',
                                hintText: 'e.g. "Injured near waterfall"',
                                prefixIcon: const Icon(Icons.message),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── How to use ─────────────────────────────────────────
                  if (_activeAlert == null) _HowToUseCard(),

                  const SizedBox(height: 20),

                  // ── Alert history ──────────────────────────────────────
                  if (_alertHistory.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Alert History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._alertHistory.map((a) => _AlertHistoryTile(alert: a)),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    _countdownCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }
}

// ─── SOS Button Card ─────────────────────────────────────────────────────────
class _SOSButtonCard extends StatelessWidget {
  final bool isHolding;
  final bool isTriggering;
  final bool hasActiveAlert;
  final double countdownProgress;
  final int countdownRemaining;
  final Animation<double> pulseAnim;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final String locationLabel;
  final VoidCallback onRefreshLocation;

  const _SOSButtonCard({
    required this.isHolding,
    required this.isTriggering,
    required this.hasActiveAlert,
    required this.countdownProgress,
    required this.countdownRemaining,
    required this.pulseAnim,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.locationLabel,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            // ── Instruction text ────────────────────────────────────────
            Text(
              hasActiveAlert
                  ? 'You have an active emergency alert'
                  : isHolding
                      ? 'Hold for $countdownRemaining…'
                      : 'Hold the button for 3 seconds to activate SOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isHolding ? _kRedBright : Colors.grey.shade600,
                fontWeight:
                    isHolding ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 28),

            // ── The big button ──────────────────────────────────────────
            GestureDetector(
              onTapDown: hasActiveAlert || isTriggering
                  ? null
                  : (_) => onHoldStart(),
              onTapUp: (_) => onHoldEnd(),
              onTapCancel: onHoldEnd,
              child: AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, child) {
                  final scale =
                      hasActiveAlert ? 1.0 : (isHolding ? 1.0 : pulseAnim.value);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Countdown arc
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _CountdownArcPainter(
                          progress: countdownProgress,
                          isActive: hasActiveAlert,
                        ),
                      ),
                    ),
                    // Button body
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: hasActiveAlert
                              ? [Colors.orange.shade600, Colors.orange.shade900]
                              : [_kRedBright, _kRedDark],
                          center: const Alignment(-0.3, -0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: hasActiveAlert
                                ? Colors.orange.withValues(alpha: 0.5)
                                : _kRedMid.withValues(alpha: 0.5),
                            blurRadius: isHolding ? 30 : 16,
                            spreadRadius: isHolding ? 6 : 2,
                          ),
                        ],
                      ),
                      child: isTriggering
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  hasActiveAlert
                                      ? Icons.warning_amber_rounded
                                      : Icons.sos,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasActiveAlert ? 'ACTIVE' : 'SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Location row ────────────────────────────────────────────
            GestureDetector(
              onTap: onRefreshLocation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      locationLabel,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.refresh, size: 12, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Countdown arc painter ────────────────────────────────────────────────────
class _CountdownArcPainter extends CustomPainter {
  final double progress;
  final bool isActive;

  const _CountdownArcPainter({required this.progress, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    if (progress <= 0.0 && !isActive) return;

    final arcPaint = Paint()
      ..color = isActive ? Colors.orange : _kRedBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (isActive ? 1.0 : progress),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownArcPainter old) =>
      old.progress != progress || old.isActive != isActive;
}

// ─── Active alert card ────────────────────────────────────────────────────────
class _ActiveAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onResolve;
  final VoidCallback onCancel;

  const _ActiveAlertCard({
    required this.alert,
    required this.onResolve,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = _parseTime(alert['created_at']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kRedMid,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('ACTIVE EMERGENCY',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                      fontSize: 11, color: Colors.red.shade700),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (alert['message'] != null && alert['message'].toString().isNotEmpty)
            Text(
              alert['message'].toString(),
              style: const TextStyle(fontSize: 14),
            ),
          if (alert['trip_name'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(alert['trip_name'].toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onResolve,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime? _parseTime(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()).toLocal(); } catch (_) { return null; }
  }

  static String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

// ─── How-to-use card ──────────────────────────────────────────────────────────
class _HowToUseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Text('How to use SOS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800)),
              ],
            ),
            const SizedBox(height: 10),
            ..._steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_steps.indexOf(s) + 1}. ',
                          style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Expanded(
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  static const _steps = [
    'Hold the red SOS button for 3 seconds.',
    'Your GPS location is automatically captured.',
    'Optionally attach a trip and message before activating.',
    'An alert is broadcast to emergency monitors instantly.',
    'Tap "Resolved" once the emergency is handled.',
  ];
}

// ─── Alert history tile ───────────────────────────────────────────────────────
class _AlertHistoryTile extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertHistoryTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final status = alert['status'] as String? ?? 'Unknown';
    final statusColor = status == 'Active'
        ? Colors.red
        : status == 'Resolved'
            ? Colors.green
            : Colors.grey;

    DateTime? created;
    try {
      created = DateTime.parse(alert['created_at'].toString()).toLocal();
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            status == 'Active'
                ? Icons.sos
                : status == 'Resolved'
                    ? Icons.check_circle
                    : Icons.cancel,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (alert['trip_name'] != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alert['trip_name'].toString(),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alert['message'] != null &&
                alert['message'].toString().isNotEmpty)
              Text(
                alert['message'].toString(),
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              created != null
                  ? '${created.day}/${created.month}/${created.year}  '
                      '${created.hour.toString().padLeft(2, '0')}:'
                      '${created.minute.toString().padLeft(2, '0')}'
                  : '—',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Text(
          '${asNum(alert['latitude'])?.toStringAsFixed(3) ?? '?'}, '
          '${asNum(alert['longitude'])?.toStringAsFixed(3) ?? '?'}',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}
