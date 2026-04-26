import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'safarsync_local.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_profiles (
            uid TEXT PRIMARY KEY,
            full_name TEXT,
            email TEXT,
            phone_number TEXT,
            blood_group TEXT,
            city TEXT,
            updated_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE destinations (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            location TEXT NOT NULL,
            image TEXT,
            rating REAL,
            reviews INTEGER,
            price TEXT,
            description TEXT,
            category TEXT
          )
        ''');

        await _seedDestinations(db);
      },
    );
  }

  static Future<void> ensureInitialized() async {
    await database;
  }

  static Future<void> upsertUserProfile({
    required String uid,
    required String email,
    String? fullName,
    String? phoneNumber,
    String? bloodGroup,
    String? city,
  }) async {
    final db = await database;
    await db.insert('user_profiles', {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'blood_group': bloodGroup,
      'city': city,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final db = await database;
    final rows = await db.query(
      'user_profiles',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<List<Map<String, dynamic>>> getDestinations({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    final db = await database;
    final offset = (page - 1) * limit;

    return db.query(
      'destinations',
      where: category != null && category.isNotEmpty ? 'category = ?' : null,
      whereArgs: category != null && category.isNotEmpty ? [category] : null,
      limit: limit,
      offset: offset,
      orderBy: 'rating DESC, name ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> searchDestinations(
    String query,
  ) async {
    final db = await database;
    return db.query(
      'destinations',
      where: 'name LIKE ? OR location LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'rating DESC, name ASC',
    );
  }

  static Future<void> _seedDestinations(Database db) async {
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM destinations',
    );
    final count = (countResult.first['count'] as int?) ?? 0;
    if (count > 0) return;

    final batch = db.batch();
    final seedRows = <Map<String, dynamic>>[
      {
        'id': 1,
        'name': 'Fairy Meadows',
        'location': 'Gilgit-Baltistan',
        'image': 'assets/explore_images/fairy_meadows.jpg',
        'rating': 4.9,
        'reviews': 320,
        'price': 'Rs 45,000',
        'description': 'Lush alpine meadow with views of Nanga Parbat.',
        'category': 'nature',
      },
      {
        'id': 2,
        'name': 'Skardu Valley',
        'location': 'Gilgit-Baltistan',
        'image': 'assets/explore_images/skardu_valley.jpg',
        'rating': 4.8,
        'reviews': 280,
        'price': 'Rs 38,000',
        'description': 'Mountain valley with lakes, forts, and scenic roads.',
        'category': 'nature',
      },
      {
        'id': 3,
        'name': 'Mohenjo Daro',
        'location': 'Sindh',
        'image': 'assets/explore_images/mohenjo_daro.jpg',
        'rating': 4.7,
        'reviews': 150,
        'price': 'Rs 8,000',
        'description': 'Ancient Indus Valley civilization archaeological site.',
        'category': 'history',
      },
      {
        'id': 4,
        'name': 'Rohtas Fort',
        'location': 'Punjab',
        'image': 'assets/explore_images/rohtas_fort.jpg',
        'rating': 4.6,
        'reviews': 200,
        'price': 'Rs 6,000',
        'description': 'UNESCO heritage military fort from the 16th century.',
        'category': 'history',
      },
      {
        'id': 5,
        'name': 'Food Street Lahore',
        'location': 'Lahore',
        'image': 'assets/explore_images/food_street_lahore.jpg',
        'rating': 4.7,
        'reviews': 500,
        'price': 'Rs 2,500',
        'description': 'Traditional street food and cultural vibes.',
        'category': 'food',
      },
      {
        'id': 6,
        'name': 'Burns Road Karachi',
        'location': 'Karachi',
        'image': 'assets/explore_images/burns_road_karachi.jpg',
        'rating': 4.5,
        'reviews': 410,
        'price': 'Rs 2,000',
        'description': 'Iconic food hub with classic Karachi flavors.',
        'category': 'food',
      },
      {
        'id': 7,
        'name': 'K2 Base Camp',
        'location': 'Gilgit-Baltistan',
        'image': 'assets/explore_images/k2_base_camp.jpg',
        'rating': 4.9,
        'reviews': 95,
        'price': 'Rs 75,000',
        'description': 'High-altitude expedition route for adventurers.',
        'category': 'adventure',
      },
      {
        'id': 8,
        'name': 'Chitral Valley Trek',
        'location': 'Khyber Pakhtunkhwa',
        'image': 'assets/explore_images/chitral_valley_trek.jpg',
        'rating': 4.8,
        'reviews': 120,
        'price': 'Rs 52,000',
        'description': 'Scenic trekking trails through mountain valleys.',
        'category': 'adventure',
      },
    ];

    for (final row in seedRows) {
      batch.insert(
        'destinations',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
