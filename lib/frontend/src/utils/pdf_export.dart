import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class PdfExportUserInfo {
  final String fullName;
  final String email;
  final String userId;
  final String? profileImageUrl;

  const PdfExportUserInfo({
    required this.fullName,
    required this.email,
    required this.userId,
    this.profileImageUrl,
  });
}

class PdfExportOptions {
  final String reportType;
  final String filePrefix;
  final PdfExportUserInfo userInfo;
  final String? generatedByRole;
  final String? generatedByName;
  final String? generatedByEmail;
  final DateTime? generatedAt;
  final List<String> groupMembers;
  final List<String> travelHistory;
  final List<String> emergencyEvents;
  final Map<String, String> bookingDetails;
  final Map<String, String> routeDetails;

  const PdfExportOptions({
    required this.reportType,
    required this.filePrefix,
    required this.userInfo,
    this.generatedByRole,
    this.generatedByName,
    this.generatedByEmail,
    this.generatedAt,
    this.groupMembers = const [],
    this.travelHistory = const [],
    this.emergencyEvents = const [],
    this.bookingDetails = const {},
    this.routeDetails = const {},
  });
}

Future<void> exportTripToPDF(
  TripData tripData, {
  PdfExportOptions? options,
}) async {
  final pdf = pw.Document();
  final exportTime = options?.generatedAt ?? DateTime.now();
  final dateStr = DateFormat('MMMM d, yyyy').format(exportTime);
  final dateTimeStr = DateFormat('dd MMMM yyyy - hh:mm a').format(exportTime);
  final userInfo = options?.userInfo ?? _currentUserInfo();
  final reportType = options?.reportType ?? 'Trip Report';
  final fileName = _buildFileName(
    options?.filePrefix ?? 'Trip_Report',
    userInfo.fullName,
    exportTime,
  );
  final profileImage = userInfo.profileImageUrl?.trim().isNotEmpty == true
      ? await networkImage(userInfo.profileImageUrl!.trim())
      : null;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (context) {
        return [
          // Header
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: PdfColor.fromInt(0xFF14B8A6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (profileImage != null)
                  pw.Container(
                    width: 42,
                    height: 42,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(
                        color: PdfColors.white,
                        width: 1.5,
                      ),
                    ),
                    child: pw.ClipOval(
                      child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                if (profileImage != null) pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
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
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // User Info
          pw.Text(
            'Generated For: ${userInfo.fullName}',
            style: pw.TextStyle(fontSize: 12),
          ),
          if (userInfo.email.isNotEmpty)
            pw.Text(
              'Email: ${userInfo.email}',
              style: pw.TextStyle(fontSize: 12),
            ),
          pw.Text(
            'User ID: ${userInfo.userId}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Generated On: $dateTimeStr',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Report Type: $reportType',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Trip Name: ${tripData.tripName}',
            style: pw.TextStyle(fontSize: 12),
          ),
          if (options?.generatedByName != null) ...[
            pw.Text(
              'Generated By: ${options!.generatedByName}',
              style: pw.TextStyle(fontSize: 12),
            ),
            if ((options.generatedByEmail ?? '').isNotEmpty)
              pw.Text(
                'Admin Email: ${options.generatedByEmail}',
                style: pw.TextStyle(fontSize: 12),
              ),
            if ((options.generatedByRole ?? '').isNotEmpty)
              pw.Text(
                'Role: ${options.generatedByRole}',
                style: pw.TextStyle(fontSize: 12),
              ),
          ],
          if ((options?.bookingDetails ?? {}).isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Booking Details', style: pw.TextStyle(fontSize: 14)),
            ...options!.bookingDetails.entries.map(
              (entry) => pw.Text(
                '${entry.key}: ${entry.value}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
          if (options?.groupMembers.isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text('Group Members', style: pw.TextStyle(fontSize: 14)),
            ...options!.groupMembers.map(
              (member) =>
                  pw.Text('• $member', style: pw.TextStyle(fontSize: 10)),
            ),
          ],
          if (options?.travelHistory.isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text('Travel History', style: pw.TextStyle(fontSize: 14)),
            ...options!.travelHistory.map(
              (item) => pw.Text('• $item', style: pw.TextStyle(fontSize: 10)),
            ),
          ],
          if (options?.routeDetails.isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text('Route Details', style: pw.TextStyle(fontSize: 14)),
            ...options!.routeDetails.entries.map(
              (entry) => pw.Text(
                '${entry.key}: ${entry.value}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
          if (options?.emergencyEvents.isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text('Emergency Events', style: pw.TextStyle(fontSize: 14)),
            ...options!.emergencyEvents.map(
              (item) => pw.Text('• $item', style: pw.TextStyle(fontSize: 10)),
            ),
          ],
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
    name: fileName,
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

PdfExportUserInfo _currentUserInfo() {
  final user = FirebaseAuth.instance.currentUser;
  return PdfExportUserInfo(
    fullName: user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Traveller',
    email: user?.email ?? '',
    userId: user?.uid ?? 'unknown-user',
    profileImageUrl: user?.photoURL,
  );
}

String _buildFileName(String prefix, String fullName, DateTime timestamp) {
  final sanitizedName = fullName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '');
  final datePart = DateFormat('yyyy-MM-dd').format(timestamp);
  return '${prefix}_${sanitizedName.isEmpty ? 'Traveller' : sanitizedName}_$datePart.pdf';
}
