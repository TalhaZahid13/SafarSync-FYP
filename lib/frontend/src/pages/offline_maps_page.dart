import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/offline_map_service.dart';

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  State<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends State<OfflineMapsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Set<String> _downloaded = {};
  bool _loadingState = true;

  // Per-region download state
  final Map<String, double> _progress = {};
  final Map<String, String> _statusMsg = {};
  final Map<String, bool> _downloading = {};
  final Map<String, bool> _cancelled = {};

  // Viewed map state
  OfflineRegion? _viewedRegion;
  static const _baseColor = Color(0xFF2CAFBC);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadDownloadedList();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadedList() async {
    setState(() => _loadingState = true);
    final names = await OfflineMapService.getDownloadedRegionNames();
    if (mounted) {
      setState(() {
        _downloaded = names.toSet();
        _loadingState = false;
      });
    }
  }

  Future<void> _startDownload(OfflineRegion region) async {
    if (_downloading[region.name] == true) return;
    setState(() {
      _downloading[region.name] = true;
      _progress[region.name] = 0.0;
      _statusMsg[region.name] = 'Starting…';
      _cancelled[region.name] = false;
    });

    await OfflineMapService.downloadRegion(
      region,
      onProgress: (p, done, total) {
        if (mounted) {
          setState(() {
            _progress[region.name] = p;
            _statusMsg[region.name] = '$done / $total tiles';
          });
        }
      },
      isCancelled: () => _cancelled[region.name] == true,
    );

    if (_cancelled[region.name] == true) {
      if (mounted) {
        setState(() {
          _downloading[region.name] = false;
          _statusMsg[region.name] = 'Cancelled';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _downloading[region.name] = false;
        _downloaded.add(region.name);
        _statusMsg[region.name] = 'Done';
      });
    }
  }

  Future<void> _deleteRegion(OfflineRegion region) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Offline Map'),
        content: Text('Remove the downloaded map for ${region.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await OfflineMapService.deleteRegion(region.name);
      if (mounted) setState(() => _downloaded.remove(region.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Offline Maps'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _baseColor,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          indicatorColor: _baseColor,
          tabs: const [
            Tab(text: 'Download Regions'),
            Tab(text: 'View Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildDownloadTab(theme), _buildMapTab(theme)],
      ),
    );
  }

  Widget _buildDownloadTab(ThemeData theme) {
    if (_loadingState) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadDownloadedList,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _baseColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _baseColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _baseColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Download a region to browse its map without internet.\n'
                    'Tiles are cached automatically when you view an area online.',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...kAvailableRegions.map(
            (r) => _RegionCard(
              region: r,
              isDownloaded: _downloaded.contains(r.name),
              isDownloading: _downloading[r.name] == true,
              progress: _progress[r.name] ?? 0,
              statusMsg: _statusMsg[r.name],
              onDownload: () => _startDownload(r),
              onCancel: () => setState(() => _cancelled[r.name] = true),
              onDelete: () => _deleteRegion(r),
              onView: () {
                setState(() => _viewedRegion = r);
                _tabs.animateTo(1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(ThemeData theme) {
    final region = _viewedRegion ?? kAvailableRegions.first;
    final center = LatLng(
      (region.minLat + region.maxLat) / 2,
      (region.minLon + region.maxLon) / 2,
    );
    final isOnline = _downloaded.contains(region.name)
        ? 'Offline — tiles cached'
        : 'Online (tap Download to cache)';

    return Column(
      children: [
        // Region switcher
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: kAvailableRegions.length,
            separatorBuilder: (context2, i) => const SizedBox(width: 8),
            itemBuilder: (context2, i) {
              final r = kAvailableRegions[i];
              final sel = r.name == region.name;
              return ChoiceChip(
                label: Text(r.name, style: const TextStyle(fontSize: 12)),
                selected: sel,
                selectedColor: _baseColor,
                labelStyle: TextStyle(color: sel ? Colors.white : null),
                onSelected: (_) => setState(() => _viewedRegion = r),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(
                _downloaded.contains(region.name)
                    ? Icons.download_done_rounded
                    : Icons.cloud_outlined,
                size: 14,
                color: _downloaded.contains(region.name)
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                isOnline,
                style: TextStyle(
                  fontSize: 12,
                  color: _downloaded.contains(region.name)
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: (region.minZoom + region.maxZoom) / 2.0 - 1,
              minZoom: region.minZoom.toDouble(),
              maxZoom: region.maxZoom.toDouble(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safarsync.safarsync',
                maxZoom: region.maxZoom.toDouble(),
                tileProvider: CachedTileProvider(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Region Download Card ─────────────────────────────────────────────────────

class _RegionCard extends StatelessWidget {
  final OfflineRegion region;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final String? statusMsg;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _RegionCard({
    required this.region,
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.statusMsg,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onView,
  });

  static const _base = Color(0xFF2CAFBC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDownloaded
            ? Border.all(color: Colors.green.withValues(alpha: 0.4))
            : Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDownloaded
                      ? Colors.green.withValues(alpha: 0.15)
                      : _base.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.map_outlined,
                  color: isDownloaded ? Colors.green : _base,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '~${region.estimatedMb} MB  •  '
                      'Zoom ${region.minZoom}–${region.maxZoom}  •  '
                      '${region.tileCount} tiles',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDownloaded)
                Chip(
                  label: const Text('Cached', style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                  labelStyle: const TextStyle(color: Colors.green),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: _base.withValues(alpha: 0.15),
              color: _base,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              statusMsg ?? '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isDownloaded && !isDownloading)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _base,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (isDownloading)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (isDownloaded) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('View Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _base,
                      side: const BorderSide(color: _base),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
