import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class OfflineRegion {
  final String name;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final int minZoom;
  final int maxZoom;

  const OfflineRegion({
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    this.minZoom = 10,
    this.maxZoom = 14,
  });

  int get tileCount {
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final (x0, y0) = _latLonToTile(maxLat, minLon, z);
      final (x1, y1) = _latLonToTile(minLat, maxLon, z);
      total += (x1 - x0 + 1) * (y1 - y0 + 1);
    }
    return total;
  }

  int get estimatedMb => (tileCount * 20) ~/ 1024;
}

(int, int) _latLonToTile(double lat, double lon, int zoom) {
  final n = math.pow(2, zoom).toInt();
  final x = ((lon + 180.0) / 360.0 * n).floor();
  final latRad = lat * math.pi / 180.0;
  final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
  return (x.clamp(0, n - 1), y.clamp(0, n - 1));
}

const _kTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

const kAvailableRegions = [
  OfflineRegion(
    name: 'Islamabad',
    minLat: 33.55, maxLat: 33.80, minLon: 72.85, maxLon: 73.15,
    minZoom: 10, maxZoom: 14,
  ),
  OfflineRegion(
    name: 'Lahore',
    minLat: 31.40, maxLat: 31.65, minLon: 74.20, maxLon: 74.50,
    minZoom: 10, maxZoom: 14,
  ),
  OfflineRegion(
    name: 'Hunza Valley',
    minLat: 36.20, maxLat: 36.55, minLon: 74.50, maxLon: 74.90,
    minZoom: 9, maxZoom: 13,
  ),
  OfflineRegion(
    name: 'Karachi',
    minLat: 24.75, maxLat: 25.05, minLon: 66.90, maxLon: 67.20,
    minZoom: 10, maxZoom: 14,
  ),
  OfflineRegion(
    name: 'Murree',
    minLat: 33.85, maxLat: 34.00, minLon: 73.35, maxLon: 73.50,
    minZoom: 10, maxZoom: 15,
  ),
];

class OfflineMapService {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'offline_maps.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE downloaded_regions (
            name TEXT PRIMARY KEY,
            downloaded_at INTEGER,
            tile_count INTEGER,
            size_mb INTEGER
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<List<String>> getDownloadedRegionNames() async {
    final db = await _database;
    final rows = await db.query('downloaded_regions');
    return rows.map((r) => r['name'] as String).toList();
  }

  static Future<bool> isDownloaded(String name) async {
    final db = await _database;
    final rows = await db.query(
      'downloaded_regions',
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.isNotEmpty;
  }

  static Future<void> deleteRegion(String name) async {
    final region = kAvailableRegions.firstWhere(
      (r) => r.name == name,
      orElse: () => throw Exception('Region not found: $name'),
    );
    final db = await _database;
    await db.delete('downloaded_regions', where: 'name = ?', whereArgs: [name]);
    final cache = DefaultCacheManager();
    for (final url in OfflineMapService.regionTileUrls(region)) {
      await cache.removeFile(url);
    }
  }

  /// Download all tiles for a region. Calls [onProgress] with 0.0–1.0.
  static Future<void> downloadRegion(
    OfflineRegion region, {
    required void Function(double progress, int done, int total) onProgress,
    bool Function()? isCancelled,
  }) async {
    final cache = DefaultCacheManager();
    int done = 0;
    int total = 0;

    // Count total tiles first
    for (int z = region.minZoom; z <= region.maxZoom; z++) {
      final (x0, y0) = _latLonToTile(region.maxLat, region.minLon, z);
      final (x1, y1) = _latLonToTile(region.minLat, region.maxLon, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          total++;
        }
      }
    }

    for (int z = region.minZoom; z <= region.maxZoom; z++) {
      final (x0, y0) = _latLonToTile(region.maxLat, region.minLon, z);
      final (x1, y1) = _latLonToTile(region.minLat, region.maxLon, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          if (isCancelled?.call() == true) return;
          final url = _kTileUrl
              .replaceAll('{z}', '$z')
              .replaceAll('{x}', '$x')
              .replaceAll('{y}', '$y');
          try {
            await cache.downloadFile(url, authHeaders: {
              'User-Agent': 'SafarSync/1.0 (educational FYP project)',
            });
          } catch (_) {
            // Ignore individual tile failures — partial download still useful
          }
          done++;
          onProgress(done / total, done, total);
        }
      }
    }

    final db = await _database;
    await db.insert(
      'downloaded_regions',
      {
        'name': region.name,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
        'tile_count': total,
        'size_mb': (total * 20) ~/ 1024,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static String tileUrl(int z, int x, int y) =>
      _kTileUrl.replaceAll('{z}', '$z').replaceAll('{x}', '$x').replaceAll('{y}', '$y');

  static List<String> regionTileUrls(OfflineRegion region) {
    final urls = <String>[];
    for (int z = region.minZoom; z <= region.maxZoom; z++) {
      final (x0, y0) = _latLonToTile(region.maxLat, region.minLon, z);
      final (x1, y1) = _latLonToTile(region.minLat, region.maxLon, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          urls.add(tileUrl(z, x, y));
        }
      }
    }
    return urls;
  }
}

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
    );
  }
}
