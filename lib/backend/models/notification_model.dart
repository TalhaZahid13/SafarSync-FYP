class NotificationModel {
  // Class name NotificationModel hi rakhte hain
  final int id;
  final String title;
  final String description;
  final String time;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
  });

  // --- NAYA: fromJson Named Constructor ---
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      time: json['time'] as String,
    );
  }

  // Optional: toJson method for sending data to API
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'description': description, 'time': time};
  }
}
