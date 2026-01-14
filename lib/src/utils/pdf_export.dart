import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class TripData {
  final String userName;
  final String tripName;
  final List<Destination> destinations;
  final List<RouteData> routes;
  final List<Hotel> hotels;
  final List<Restaurant> restaurants;
  final TripStats stats;

  TripData({
    required this.userName,
    required this.tripName,
    required this.destinations,
    required this.routes,
    required this.hotels,
    required this.restaurants,
    required this.stats,
  });
}

class Destination {
  final String name;
  final String location;
  final double rating;
  final String price;

  Destination({
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
  });
}

class RouteData {
  final String name;
  final String from;
  final String to;
  final String distance;
  final String duration;
  final String fuelCost;

  RouteData({
    required this.name,
    required this.from,
    required this.to,
    required this.distance,
    required this.duration,
    required this.fuelCost,
  });
}

class Hotel {
  final String name;
  final String location;
  final double rating;
  final String price;

  Hotel({
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
  });
}

class Restaurant {
  final String name;
  final String cuisine;
  final double rating;
  final String price;

  Restaurant({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.price,
  });
}

class TripStats {
  final int placesVisited;
  final int badgesEarned;
  final int tripsPlanned;

  TripStats({
    required this.placesVisited,
    required this.badgesEarned,
    required this.tripsPlanned,
  });
}

Future<void> exportTripToPDF(TripData tripData) async {
  final pdf = pw.Document();
  final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) {
        return [
          // Header
          pw.Container(
            width: double.infinity,
            height: 40,
            color: PdfColor.fromInt(0xFF14B8A6),
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Travel Companion',
                  style: pw.TextStyle(fontSize: 24, color: PdfColors.white),
                ),
                pw.Text(
                  'Trip Summary & Itinerary',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // User Info
          pw.Text(
            'Traveler: ${tripData.userName}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Trip Name: ${tripData.tripName}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text('Generated: $dateStr', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 10),

          // Stats
          pw.Container(
            color: PdfColor.fromInt(0xFF8B5CF6),
            padding: pw.EdgeInsets.all(5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text(
                  'Places Visited: ${tripData.stats.placesVisited}',
                  style: pw.TextStyle(color: PdfColors.white),
                ),
                pw.Text(
                  'Badges Earned: ${tripData.stats.badgesEarned}',
                  style: pw.TextStyle(color: PdfColors.white),
                ),
                pw.Text(
                  'Trips Planned: ${tripData.stats.tripsPlanned}',
                  style: pw.TextStyle(color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Destinations
          if (tripData.destinations.isNotEmpty) ...[
            pw.Text('📍 Destinations', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 5),
            ...tripData.destinations.map(
              (dest) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ${dest.name}, ${dest.location}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Rating: ${dest.rating} ⭐ | Price: ${dest.price}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                ],
              ),
            ),
          ],

          // Routes
          if (tripData.routes.isNotEmpty) ...[
            pw.Text('🗺️ Planned Routes', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 5),
            ...tripData.routes.map(
              (route) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ${route.name}: ${route.from} → ${route.to}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Distance: ${route.distance} | Duration: ${route.duration} | Fuel: ${route.fuelCost}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                ],
              ),
            ),
          ],

          // Hotels
          if (tripData.hotels.isNotEmpty) ...[
            pw.Text('🏨 Hotels', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 5),
            ...tripData.hotels.map(
              (hotel) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ${hotel.name}, ${hotel.location}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Rating: ${hotel.rating} ⭐ | Price: ${hotel.price}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                ],
              ),
            ),
          ],

          // Restaurants
          if (tripData.restaurants.isNotEmpty) ...[
            pw.Text('🍽️ Restaurants', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 5),
            ...tripData.restaurants.map(
              (rest) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ${rest.name} - ${rest.cuisine}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Rating: ${rest.rating} ⭐ | Price: ${rest.price}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                ],
              ),
            ),
          ],
        ];
      },
      footer: (context) {
        return pw.Center(
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount} | Travel Companion App | Generated on $dateStr',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        );
      },
    ),
  );

  // Save or share
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}