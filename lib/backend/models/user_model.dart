// models/user_model.dart
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePic;
  final String? coverPic;
  final String? bio;
  final String? dob;
  final String? address;
  final String? phoneNumber;
  final bool googleUser;
  final bool isEmailVerified;
  final bool isBlocked;
  final String role;
  final bool isOnline;
  final String? lastSeen;
  final String? socketId;
  final double withdrawableAmount;
  final String? subscriptionPlanId;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePic,
    this.coverPic,
    this.bio,
    this.dob,
    this.address,
    this.phoneNumber,
    required this.googleUser,
    required this.isEmailVerified,
    required this.isBlocked,
    required this.role,
    required this.isOnline,
    this.lastSeen,
    this.socketId,
    required this.withdrawableAmount,
    this.subscriptionPlanId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profilePic: json['profilePic'] as String?,
      coverPic: json['coverPic'] as String?,
      bio: json['bio'] as String?,
      dob: json['dob'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      googleUser: json['googleUser'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
      isBlocked: json['isBlocked'] as bool,
      role: json['role'] as String,
      isOnline: json['isOnline'] as bool,
      lastSeen: json['lastSeen'] as String?,
      socketId: json['socketId'] as String?,
      withdrawableAmount:
          (json['withdrawableAmount'] as num?)?.toDouble() ?? 0.0,
      subscriptionPlanId: json['subscriptionPlanId'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profilePic': profilePic,
      'coverPic': coverPic,
      'bio': bio,
      'dob': dob,
      'address': address,
      'phoneNumber': phoneNumber,
      'googleUser': googleUser,
      'isEmailVerified': isEmailVerified,
      'isBlocked': isBlocked,
      'role': role,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'socketId': socketId,
      'withdrawableAmount': withdrawableAmount,
      'subscriptionPlanId': subscriptionPlanId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get fullName => '$firstName $lastName';
}
