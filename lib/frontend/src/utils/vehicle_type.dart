import 'package:flutter/material.dart';

enum VehicleType { car, bike }

extension VehicleTypeX on VehicleType {
  String get label => this == VehicleType.car ? 'Car' : 'Bike / Motorbike';

  String get osrmProfile =>
      this == VehicleType.car ? 'driving' : 'cycling';

  String get routeTag => this == VehicleType.car
      ? 'Motorway route  ·  M-1, M-2…'
      : 'Highway route  ·  N-5, N-55…';

  IconData get icon =>
      this == VehicleType.car ? Icons.directions_car : Icons.two_wheeler;

  String get name => this == VehicleType.car ? 'car' : 'bike';

  static VehicleType fromName(String? name) =>
      name == 'bike' ? VehicleType.bike : VehicleType.car;
}

/// Shows a bottom sheet for selecting the vehicle type.
/// Returns the chosen [VehicleType], or `null` if dismissed.
Future<VehicleType?> showVehiclePickerSheet(BuildContext context) {
  return showModalBottomSheet<VehicleType>(
    context: context,
    backgroundColor: const Color(0xFF1B3A5C),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _VehiclePickerSheet(),
  );
}

class _VehiclePickerSheet extends StatefulWidget {
  const _VehiclePickerSheet();

  @override
  State<_VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<_VehiclePickerSheet> {
  VehicleType _selected = VehicleType.car;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'How are you travelling?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Route type is optimised based on your vehicle',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

          _VehicleCard(
            type: VehicleType.car,
            selected: _selected == VehicleType.car,
            onTap: () => setState(() => _selected = VehicleType.car),
          ),
          const SizedBox(height: 12),
          _VehicleCard(
            type: VehicleType.bike,
            selected: _selected == VehicleType.bike,
            onTap: () => setState(() => _selected = VehicleType.bike),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2CAFBC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Start Navigation',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleType type;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        type == VehicleType.car ? const Color(0xFF3B82F6) : const Color(0xFF10B981);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(type.icon,
                  color: selected ? accent : Colors.white54, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    type.routeTag,
                    style: TextStyle(
                      color: selected ? accent : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected ? accent : Colors.white30,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
