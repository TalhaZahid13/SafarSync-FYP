class GigModel {
  // Class name GigModel hi rakhte hain, jaisa pehle define kiya tha
  final int id;
  final String title;
  final String status;
  final String? description;
  final String? imageUrl;

  GigModel({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.imageUrl,
  });

  // --- NAYA: fromJson Named Constructor ---
  factory GigModel.fromJson(Map<String, dynamic> json) {
    return GigModel(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      description: json['description'] as String?, // Nullable field
      imageUrl:
          json['image_url']
              as String?, // Nullable field, API ke key name ke mutabiq
    );
  }

  // Optional: toJson method for sending data to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
