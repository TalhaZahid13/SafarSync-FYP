import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/api_service.dart';

// ─── Virtual Tour Player ──────────────────────────────────────────────────────
// Full-screen 360° panorama viewer powered by Pannellum JS via WebView.
// Receives tour data from backend, renders scenes with hotspots,
// supports AI narration via Groq, and navigates between scenes.

class VirtualTourPlayerPage extends StatefulWidget {
  final int tourId;
  final String tourTitle;
  final int? destinationId;

  const VirtualTourPlayerPage({
    super.key,
    required this.tourId,
    required this.tourTitle,
    this.destinationId,
  });

  @override
  State<VirtualTourPlayerPage> createState() => _VirtualTourPlayerPageState();
}

class _VirtualTourPlayerPageState extends State<VirtualTourPlayerPage> {
  late final WebViewController _webCtrl;

  Map<String, dynamic>? _tour;
  bool _loading = true;
  String? _error;

  // Current scene state (updated via JS messages)
  String _currentSceneName = '';
  int? _currentSceneId;

  // AI guide state
  bool _aiLoading = false;
  String? _aiNarration;

  // Scene list drawer
  bool _sceneListOpen = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadTourData();
  }

  void _initWebView() {
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1B2A))
      ..addJavaScriptChannel(
        'VirtualTourChannel',
        onMessageReceived: _onJsMessage,
      );
  }

  Future<void> _loadTourData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.getRequest(
        '/virtual-tours/${widget.tourId}',
      );
      if (resp['success'] == true) {
        _tour = resp['tour'] as Map<String, dynamic>;
        _currentSceneName = (_tour!['scenes'] as List?)?.isNotEmpty == true
            ? (_tour!['scenes'][0]['scene_name'] ?? '')
            : '';
        await _loadHtmlAndInjectTour();
      } else {
        setState(() => _error = 'Tour not found');
      }
    } catch (e) {
      setState(() => _error = _sanitizeErrorText('Could not load tour: $e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHtmlAndInjectTour() async {
    String html = await rootBundle.loadString(
      'assets/virtual_tour_player.html',
    );
    // Inline Pannellum assets so the viewer works without internet
    final pannellumCss = await rootBundle.loadString('assets/pannellum.css');
    final pannellumJs = await rootBundle.loadString('assets/pannellum.js');
    html = html
        .replaceFirst(
          '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css">',
          '<style>$pannellumCss</style>',
        )
        .replaceFirst(
          '<script src="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js"></script>',
          '<script>$pannellumJs</script>',
        );
    _webCtrl.loadHtmlString(html, baseUrl: 'https://localhost');
  }

  void _onJsMessage(JavaScriptMessage message) {
    try {
      final payload = json.decode(message.message) as Map<String, dynamic>;
      final type = payload['type'] as String;
      final data = payload['data'] as Map<String, dynamic>? ?? {};

      switch (type) {
        case 'page_ready':
          _injectTourData();
          break;

        case 'tour_loaded':
          if (mounted) setState(() {});
          break;

        case 'scene_changed':
          if (mounted) {
            setState(() {
              _currentSceneName = data['sceneName'] ?? _currentSceneName;
              _currentSceneId = data['sceneId'] as int?;
              _aiNarration = null;
            });
          }
          break;

        case 'hotspot_info':
          // Info hotspots show native Flutter dialog for better UX
          if (mounted && (data['title'] ?? '').isNotEmpty) {
            _showInfoDialog(
              data['title'] as String,
              data['text'] as String? ?? '',
            );
          }
          break;

        case 'error':
          if (mounted) {
            setState(
              () => _error = _sanitizeErrorText(data['message']?.toString()),
            );
          }
          break;
      }
    } catch (_) {}
  }

  Future<void> _injectTourData() async {
    if (_tour == null) return;

    // Build the tour JSON for Pannellum
    final scenes = (_tour!['scenes'] as List? ?? []).map((s) {
      final hotspots = (s['hotspots'] as List? ?? [])
          .map(
            (h) => {
              'id': h['id'],
              'type': h['type'],
              'pitch': h['pitch'],
              'yaw': h['yaw'],
              'title': h['title'] ?? '',
              'text': h['text'] ?? '',
              'targetSceneKey': h['targetSceneKey'],
            },
          )
          .toList();

      return {
        'id': s['id'],
        'sceneKey': s['sceneKey'],
        'name': s['scene_name'],
        'panoramaUrl': s['panorama_url'],
        'description': s['description'] ?? '',
        'hotspots': hotspots,
      };
    }).toList();

    final tourJson = json.encode({
      'title': _tour!['title'],
      'defaultSceneKey': scenes.isNotEmpty ? scenes[0]['sceneKey'] : null,
      'scenes': scenes,
    });

    final escaped = tourJson.replaceAll("'", "\\'");
    await _webCtrl.runJavaScript("loadTour('$escaped')");
  }

  // Strips any HTML markup from error text before it reaches a Text widget —
  // Pannellum and some HTTP client exceptions embed raw <a href="..."> tags
  // meant for HTML rendering, which must never be shown as literal text.
  static String _sanitizeErrorText(String? raw) {
    if (raw == null || raw.isEmpty) return 'This tour could not be loaded.';
    final stripped = raw
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return stripped.isEmpty ? 'This tour could not be loaded.' : stripped;
  }

  // ── AI narration ─────────────────────────────────────────────────────────────

  Future<void> _requestNarration() async {
    if (_aiLoading) return;
    if (_aiNarration != null) {
      _showNarrationInWebView(_aiNarration!);
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final resp = await ApiService.postRequest('/virtual-tours/narration', {
        'scene_id': _currentSceneId,
        'scene_name': _currentSceneName,
        'tour_title': _tour?['title'] ?? widget.tourTitle,
        'destination_name': _tour?['destination_name'],
      });

      final narration =
          resp['narration'] as String? ??
          'Welcome to ${_currentSceneName.isEmpty ? "this location" : _currentSceneName}. Explore in every direction!';

      if (mounted) {
        setState(() {
          _aiNarration = narration;
          _aiLoading = false;
        });
        _showNarrationInWebView(narration);
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load AI narration')),
        );
      }
    }
  }

  Future<void> _showNarrationInWebView(String text) async {
    final escaped = text.replaceAll("'", "\\'").replaceAll('\n', ' ');
    await _webCtrl.runJavaScript("showAiNarration('$escaped')");
  }

  // ── Navigate to scene ────────────────────────────────────────────────────────

  Future<void> _goToScene(Map<String, dynamic> scene) async {
    await _webCtrl.runJavaScript("goToScene('${scene['sceneKey']}')");
    setState(() => _sceneListOpen = false);
  }

  // ── Info dialog ──────────────────────────────────────────────────────────────

  void _showInfoDialog(String title, String text) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFF2CAFBC).withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2CAFBC),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2CAFBC),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFD8EEF2),
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF2CAFBC)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError(_error!);
    return _buildPlayer();
  }

  Widget _buildLoading() => Scaffold(
    backgroundColor: const Color(0xFF0D1B2A),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: Color(0xFF2CAFBC),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Preparing virtual tour…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildError(String msg) => Scaffold(
    backgroundColor: const Color(0xFF0D1B2A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D1B2A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Tour Unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9A9E9D),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2CAFBC),
              ),
              onPressed: _loadTourData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPlayer() {
    final scenes = (_tour!['scenes'] as List? ?? []);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 360° panorama WebView
          WebViewWidget(controller: _webCtrl),

          // Top controls bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _glassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (scenes.length > 1)
                    _glassButton(
                      icon: Icons.menu_rounded,
                      onTap: () =>
                          setState(() => _sceneListOpen = !_sceneListOpen),
                      label: 'Scenes',
                    ),
                  const SizedBox(width: 8),
                  _glassButton(
                    icon: _aiLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.headset_mic_rounded,
                    onTap: _aiLoading ? null : _requestNarration,
                    label: 'AI Guide',
                    accent: const Color(0xFF2CAFBC),
                  ),
                ],
              ),
            ),
          ),

          // Scene list panel (slides in from right)
          if (_sceneListOpen && scenes.length > 1)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.70,
              child: _SceneListPanel(
                scenes: scenes,
                currentSceneName: _currentSceneName,
                onSceneTap: _goToScene,
                onClose: () => setState(() => _sceneListOpen = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback? onTap,
    String? label,
    Color? accent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A).withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent != null
                ? accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent ?? Colors.white, size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: accent ?? Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Scene List Side Panel ────────────────────────────────────────────────────

class _SceneListPanel extends StatelessWidget {
  final List scenes;
  final String currentSceneName;
  final ValueChanged<Map<String, dynamic>> onSceneTap;
  final VoidCallback onClose;

  const _SceneListPanel({
    required this.scenes,
    required this.currentSceneName,
    required this.onSceneTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(left: BorderSide(color: Color(0xFF1B3A4C))),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                children: [
                  const Text(
                    'Scenes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFF1B3A4C), height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: scenes.length,
              itemBuilder: (_, i) {
                final s = scenes[i] as Map<String, dynamic>;
                final isActive = s['scene_name'] == currentSceneName;
                return GestureDetector(
                  onTap: () => onSceneTap(s),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2CAFBC).withValues(alpha: 0.15)
                          : const Color(0xFF1B3A4C).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF2CAFBC).withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF2CAFBC).withValues(alpha: 0.2)
                                : const Color(
                                    0xFF1B5A6E,
                                  ).withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF2CAFBC)
                                    : Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s['scene_name'] ?? 'Scene ${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF2CAFBC)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          const Icon(
                            Icons.visibility_rounded,
                            color: Color(0xFF2CAFBC),
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
