// models/course_model.dart
class CourseModel {
  final String courseId;
  final String title;
  final String mode;
  final String courseDuration;
  final List<String> classDays;
  final String classDuration;
  final double courseFee;
  final String description;
  final String authorEmail;
  final bool isFeatured;
  final String createdAt;
  final String updatedAt;
  final List<String> images;
  final CourseUser user;
  final CourseParentCategory courseParentCategory;
  final List<CourseSubCategory> subCategories;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.mode,
    required this.courseDuration,
    required this.classDays,
    required this.classDuration,
    required this.courseFee,
    required this.description,
    required this.authorEmail,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    required this.user,
    required this.courseParentCategory,
    required this.subCategories,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      mode: json['mode'] as String,
      courseDuration: json['courseDuration'] as String,
      classDays: List<String>.from(json['classDays'] as List),
      classDuration: json['classDuration'] as String,
      courseFee: (json['courseFee'] as num).toDouble(),
      description: json['description'] as String,
      authorEmail: json['authorEmail'] as String,
      isFeatured: json['isFeatured'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      images: List<String>.from(json['images'] as List),
      user: CourseUser.fromJson(json['user'] as Map<String, dynamic>),
      courseParentCategory: CourseParentCategory.fromJson(
        json['courseParentCategory'] as Map<String, dynamic>,
      ),
      subCategories: (json['subCategories'] as List)
          .map((e) => CourseSubCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get imageUrl => images.isNotEmpty ? images[0] : '';
  String get authorName => '${user.firstName} ${user.lastName}';
  String get authorProfilePic => user.profilePic ?? '';
  String get categoryName => courseParentCategory.name;
  String get subCategoryName =>
      subCategories.isNotEmpty ? subCategories[0].name : '';

  // Format price with commas
  String get formattedPrice {
    return 'Rs. ${courseFee.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

class CourseUser {
  final String email;
  final String? profilePic;
  final String? coverPic;
  final String firstName;
  final String lastName;
  final String? bio;

  CourseUser({
    required this.email,
    this.profilePic,
    this.coverPic,
    required this.firstName,
    required this.lastName,
    this.bio,
  });

  factory CourseUser.fromJson(Map<String, dynamic> json) {
    return CourseUser(
      email: json['email'] as String,
      profilePic: json['profilePic'] as String?,
      coverPic: json['coverPic'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      bio: json['bio'] as String?,
    );
  }
}

class CourseParentCategory {
  final String courseParentCategoryId;
  final String name;

  CourseParentCategory({
    required this.courseParentCategoryId,
    required this.name,
  });

  factory CourseParentCategory.fromJson(Map<String, dynamic> json) {
    return CourseParentCategory(
      courseParentCategoryId: json['courseParentCategoryId'] as String,
      name: json['name'] as String,
    );
  }
}

class CourseSubCategory {
  final String courseSubCategoryId;
  final String name;
  final String parentCategoryId;
  final String icon;
  final String createdAt;
  final String updatedAt;

  CourseSubCategory({
    required this.courseSubCategoryId,
    required this.name,
    required this.parentCategoryId,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseSubCategory.fromJson(Map<String, dynamic> json) {
    return CourseSubCategory(
      courseSubCategoryId: json['courseSubCategoryId'] as String,
      name: json['name'] as String,
      parentCategoryId: json['parentCategoryId'] as String,
      icon: json['icon'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}
