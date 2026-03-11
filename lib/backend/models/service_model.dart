import 'package:intl/intl.dart';

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final String formattedPrice;
  final String providerName;
  final String providerEmail;
  final String providerProfilePic;
  final String categoryName;

  ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.formattedPrice,
    required this.providerName,
    required this.providerEmail,
    required this.providerProfilePic,
    required this.categoryName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // ✅ Extract image if present in list
    String image = '';
    if (json['images'] != null &&
        json['images'] is List &&
        json['images'].isNotEmpty) {
      image = json['images'][0];
    }

    // ✅ Combine first + last name if available
    String providerFullName = '';
    if (json['user'] != null) {
      final firstName = json['user']['firstName'] ?? '';
      final lastName = json['user']['lastName'] ?? '';
      providerFullName = '$firstName $lastName'.trim();
    }

    // ✅ Parse price safely
    final double parsedPrice = (json['serviceFee'] is String)
        ? double.tryParse(json['serviceFee']) ?? 0.0
        : (json['serviceFee'] ?? json['price'] ?? 0.0).toDouble();

    // ✅ Format price as "Rs. 30,000"
    final formatted =
        "Rs. ${NumberFormat('#,##0', 'en_US').format(parsedPrice)}";

    return ServiceModel(
      id: json['serviceId']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: image,
      price: parsedPrice,
      formattedPrice: formatted,
      providerName: providerFullName,
      providerEmail: json['user']?['email'] ?? '',
      providerProfilePic: json['user']?['profilePic'] ?? '',
      categoryName: json['serviceParentCategory']?['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'formattedPrice': formattedPrice,
      'providerName': providerName,
      'providerEmail': providerEmail,
      'providerProfilePic': providerProfilePic,
      'categoryName': categoryName,
    };
  }
}
