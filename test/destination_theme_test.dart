import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safarsync/frontend/src/ui/destination_theme.dart';

Map<String, dynamic> booking(
  String dest, {
  String status = 'Confirmed',
  String? travel,
  int days = 3,
  String type = 'single',
  String? category,
  String? city,
}) => {
  'destination_name': dest,
  'status': status,
  'travel_date': travel,
  'estimated_duration_days': days,
  'booking_type': type,
  'category': category,
  'city': city,
};

DestinationThemeType themeOf(Map<String, dynamic>? b) => b == null
    ? DestinationThemeType.defaultTheme
    : typeFromDestination(
        b['destination_name'] as String,
        b['category'] as String?,
        city: b['city'] as String?,
      );

void main() {
  final now = DateTime(2026, 11, 17);

  group('typeFromDestination — real SafarSync catalogue', () {
    final cases = {
      ('Skardu Valley', 'nature', 'Skardu'): DestinationThemeType.snow,
      ('K2 Base Camp', 'adventure', 'Skardu'): DestinationThemeType.snow,
      ('Mohenjo Daro', 'history', 'Larkana'): DestinationThemeType.desert,
      ('Rohtas Fort', 'history', 'Jhelum'): DestinationThemeType.desert,
      ('Fairy Meadows', 'nature', 'Gilgit-Baltistan'):
          DestinationThemeType.mountain,
      ('Chitral Valley Trek', 'adventure', 'Chitral'):
          DestinationThemeType.mountain,
      ('Food Street Lahore', 'food', 'Lahore'): DestinationThemeType.urban,
      ('Burns Road Karachi', 'food', 'Karachi'): DestinationThemeType.urban,
      ('Weekend Escape — Murree & Nathiagali', 'Nature', null):
          DestinationThemeType.snow,
      ('Adventure Week — Hunza Valley', 'Adventure', null):
          DestinationThemeType.mountain,
      ('Budget City Break — Lahore', 'Cultural', null):
          DestinationThemeType.urban,
    };
    cases.forEach((input, expected) {
      test('${input.$1} → ${expected.name}', () {
        expect(
          typeFromDestination(input.$1, input.$2, city: input.$3),
          expected,
        );
      });
    });

    test('unknown destination with unknown category → default', () {
      expect(
        typeFromDestination('Somewhere', 'misc'),
        DestinationThemeType.defaultTheme,
      );
    });
  });

  group('selectThemeBooking', () {
    test('no bookings → default theme', () {
      expect(
        themeOf(selectThemeBooking([], now: now)),
        DestinationThemeType.defaultTheme,
      );
    });

    test('User A with a confirmed snow trip → Snow', () {
      final b = selectThemeBooking([
        booking('Skardu Valley', travel: '2026-12-01', city: 'Skardu'),
      ], now: now);
      expect(themeOf(b), DestinationThemeType.snow);
    });

    test('User B with a confirmed desert trip → Desert', () {
      final b = selectThemeBooking([
        booking(
          'Mohenjo Daro',
          travel: '2026-12-05',
          category: 'history',
          city: 'Larkana',
        ),
      ], now: now);
      expect(themeOf(b), DestinationThemeType.desert);
    });

    test('cancelled, refunded, pending and awaiting-payment are ignored', () {
      final b = selectThemeBooking([
        booking('Skardu Valley', status: 'Cancelled', travel: '2026-12-01'),
        booking('Skardu Valley', status: 'Refunded', travel: '2026-12-01'),
        booking('Skardu Valley', status: 'Pending', travel: '2026-12-01'),
        booking(
          'Skardu Valley',
          status: 'Awaiting Payment',
          travel: '2026-12-01',
        ),
      ], now: now);
      expect(b, isNull);
    });

    test('trips that already ended are ignored', () {
      final b = selectThemeBooking([
        booking('Skardu Valley', travel: '2026-11-01', days: 3),
      ], now: now);
      expect(b, isNull);
    });

    test('a trip ongoing today still counts', () {
      final b = selectThemeBooking([
        booking('Skardu Valley', travel: '2026-11-15', days: 5),
      ], now: now);
      expect(themeOf(b), DestinationThemeType.snow);
    });

    test('several confirmed trips → the next upcoming one wins', () {
      final b = selectThemeBooking([
        booking('Food Street Lahore', travel: '2027-01-10', category: 'food'),
        booking('Mohenjo Daro', travel: '2026-11-25', category: 'history'),
        booking('Skardu Valley', travel: '2026-12-20'),
      ], now: now);
      expect(b!['destination_name'], 'Mohenjo Daro');
    });

    test('a trip in progress (Active) beats any upcoming confirmed trip', () {
      final b = selectThemeBooking([
        booking('Skardu Valley', travel: '2026-11-20'),
        booking(
          'Burns Road Karachi',
          status: 'Active',
          travel: '2026-11-16',
          category: 'food',
        ),
      ], now: now);
      expect(themeOf(b), DestinationThemeType.urban);
    });

    test('hotel and restaurant reservations never drive the theme', () {
      final b = selectThemeBooking([
        booking('Skardu Valley', travel: '2026-12-01', type: 'hotel'),
        booking('Skardu Valley', travel: '2026-12-01', type: 'restaurant'),
      ], now: now);
      expect(b, isNull);
    });

    test('bookings without a destination are ignored', () {
      final b = selectThemeBooking([
        booking('', travel: '2026-12-01'),
      ], now: now);
      expect(b, isNull);
    });
  });

  group('accessible accents', () {
    double contrast(Color c) => 1.05 / (c.computeLuminance() + 0.05);
    for (final t in DestinationTheme.all) {
      if (t.type == DestinationThemeType.defaultTheme) continue;
      test('${t.label} accent has ≥4.5:1 contrast with white', () {
        expect(contrast(t.uiAccent), greaterThanOrEqualTo(4.5));
      });
    }
    test('default theme keeps the exact brand color', () {
      expect(DestinationTheme.kDefault.uiAccent, const Color(0xFF2CAFBC));
    });
  });
}
