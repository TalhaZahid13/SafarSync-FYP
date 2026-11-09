import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../ui/app_theme.dart';
import '../utils/route_session.dart';
import '../utils/vehicle_type.dart';
import 'live_map_page.dart';

class NewRoutePage extends StatefulWidget {
  const NewRoutePage({super.key});

  @override
  State<NewRoutePage> createState() => _NewRoutePageState();
}

class _NewRoutePageState extends State<NewRoutePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  DateTime? _travelDate;
  bool _loading = false;
  bool _locatingMe = false;

  // Exact GPS coords stored when using "current location".
  // Cleared when user manually edits the From field.
  LatLng? _fromCoords;
  bool _settingFrom = false;

  @override
  void initState() {
    super.initState();
    _fromCtrl.addListener(() {
      if (!_settingFrom) _fromCoords = null;
    });
  }

  void _setFrom(String label, LatLng coords) {
    _settingFrom = true;
    _fromCtrl.text = label;
    _fromCoords = coords;
    _settingFrom = false;
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.turquoise),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _travelDate = picked);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locatingMe = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final exactCoords = LatLng(position.latitude, position.longitude);
      String label =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = (p.locality?.isNotEmpty ?? false)
            ? p.locality!
            : (p.subAdministrativeArea ?? '');
        final country = p.country ?? '';
        final readable = [city, country].where((s) => s.isNotEmpty).join(', ');
        if (readable.isNotEmpty) label = readable;
      }
      // Store exact GPS coords — _activateRoute() will use these directly
      _setFrom(label, exactCoords);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not get current location'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locatingMe = false);
    }
  }

  bool get _canActivate =>
      _fromCtrl.text.trim().isNotEmpty &&
      _toCtrl.text.trim().isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty &&
      _travelDate != null;

  Future<void> _activateRoute() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a travel date'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final from = _fromCtrl.text.trim();
      final to = _toCtrl.text.trim();

      // Use exact stored GPS coords when available; geocode only typed text.
      LatLng origin;
      if (_fromCoords != null) {
        origin = _fromCoords!;
      } else {
        final q = from.contains(',') ? from : '$from, Pakistan';
        final locs = await locationFromAddress(q);
        origin = LatLng(locs.first.latitude, locs.first.longitude);
      }

      final toQuery = to.contains(',') ? to : '$to, Pakistan';
      final toLocs = await locationFromAddress(toQuery);
      final dest = LatLng(toLocs.first.latitude, toLocs.first.longitude);

      if (!mounted) return;

      final vehicle = await showVehiclePickerSheet(context);
      if (vehicle == null || !mounted) return;

      await RouteSession.activate(
        routeName: _nameCtrl.text.trim(),
        fromName: from,
        toName: to,
        startLat: origin.latitude,
        startLng: origin.longitude,
        endLat: dest.latitude,
        endLng: dest.longitude,
        travelDate: _travelDate,
        vehicleType: vehicle,
      );

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveMapPage(
            routeOrigin: origin,
            routeDestination: dest,
            destinationName: to,
            vehicleType: vehicle,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not find location — check spelling and try again',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppTheme.darkSlate,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Route',
          style: TextStyle(
            color: AppTheme.darkSlate,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B3A5C), Color(0xFF2CAFBC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan Your Journey',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enter details to activate navigation',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Route Name
            _sectionLabel('Route Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'e.g. Northern Pakistan Tour',
                icon: Icons.bookmark_outline,
              ),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Enter a route name' : null,
            ),
            const SizedBox(height: 20),

            // Route path card
            _sectionLabel('Route'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.veryLightGray),
              ),
              child: Column(
                children: [
                  // From field
                  Row(
                    children: [
                      _dotIndicator(const Color(0xFF22C55E)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fromCtrl,
                          decoration: _inlineInputDecoration(
                            'Starting location — city or address',
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Enter starting location'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _locatingMe
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.turquoise,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                size: 20,
                                color: AppTheme.turquoise,
                              ),
                              tooltip: 'Use current location',
                              onPressed: _useCurrentLocation,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                    ],
                  ),

                  // Dotted connector
                  Padding(
                    padding: const EdgeInsets.only(left: 9),
                    child: Row(children: [_dottedLine(), const Spacer()]),
                  ),

                  // To field
                  Row(
                    children: [
                      _dotIndicator(Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _toCtrl,
                          decoration: _inlineInputDecoration(
                            'Destination — city or address',
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Enter destination'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date of Travel
            _sectionLabel('Date of Travel'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _travelDate != null
                        ? AppTheme.turquoise
                        : AppTheme.veryLightGray,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: _travelDate != null
                          ? AppTheme.turquoise
                          : AppTheme.mediumGray,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _travelDate != null
                          ? DateFormat('EEEE, d MMMM yyyy').format(_travelDate!)
                          : 'Select travel date',
                      style: TextStyle(
                        color: _travelDate != null
                            ? AppTheme.darkSlate
                            : AppTheme.mediumGray,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.mediumGray,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Route preview (shown when from + to are filled)
            if (_fromCtrl.text.trim().isNotEmpty &&
                _toCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionLabel('Route Preview'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.turquoise.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.turquoise.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fromCtrl.text.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppTheme.turquoise,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _toCtrl.text.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),

      // Activate Route button pinned to bottom
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _canActivate && !_loading ? _activateRoute : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canActivate
                  ? AppTheme.turquoise
                  : AppTheme.mediumGray.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              elevation: _canActivate ? 4 : 0,
              shadowColor: AppTheme.turquoise.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.navigation, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Activate Route',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.mediumGray,
        letterSpacing: 0.6,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.mediumGray, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.turquoise),
      filled: true,
      fillColor: AppTheme.offWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.veryLightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.veryLightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.turquoise, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  InputDecoration _inlineInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.mediumGray, fontSize: 13),
      isDense: true,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  Widget _dotIndicator(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _dottedLine() {
    return SizedBox(
      width: 2,
      height: 28,
      child: CustomPaint(painter: _DottedLinePainter()),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.mediumGray.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dotHeight = 4.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dotHeight), paint);
      y += dotHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
