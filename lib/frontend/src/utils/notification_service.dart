import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'realtime_service.dart';

/// Singleton service that:
///  1. Manages flutter_local_notifications (emergency + general channels)
///  2. Subscribes to private Supabase Realtime channels for push-style events
///  3. Exposes helpers used by EmergencySOSScreen and the App shell
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final List<RealtimeRoom> _rooms = [];
  bool _initialized = false;
  int _unreadCount = 0;

  // Listeners registered by UI widgets
  final List<VoidCallback> _unreadListeners = [];

  // ── Notification channel IDs ─────────────────────────────────────────────
  static const _kEmergencyChannelId = 'emergency_sos_channel';
  static const _kGeneralChannelId = 'safarsync_general';

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // Create emergency channel (high-priority, red LED, loud)
    const emergencyChannel = AndroidNotificationChannel(
      _kEmergencyChannelId,
      'Emergency SOS',
      description: 'High-priority emergency alert notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFB71C1C),
    );
    // Create general channel
    const generalChannel = AndroidNotificationChannel(
      _kGeneralChannelId,
      'SafarSync Notifications',
      description: 'General in-app notifications',
      importance: Importance.high,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(emergencyChannel);
    await androidImpl?.createNotificationChannel(generalChannel);
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Realtime listeners ────────────────────────────────────────────────────
  /// Call once after the user is authenticated.
  ///  * `user:<id>`        — this user's own notifications
  ///  * `broadcast:all`    — admin broadcast announcements
  ///  * `emergency:admin`  — live SOS feed (admins only; enforced by RLS)
  void startListening() {
    _startListening().ignore();
  }

  Future<void> _startListening() async {
    stopListening();
    if (!RealtimeService.canConnect) return;

    final userId = await ApiService.getCurrentUserId();
    if (userId == null) return;

    void onNotification(Map<String, dynamic> data) {
      final title = data['title']?.toString() ?? 'SafarSync';
      final body = data['message']?.toString() ?? '';
      final type = data['type']?.toString() ?? '';

      _incrementUnread();

      if (type.startsWith('emergency')) {
        _showEmergencyNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
        );
      } else {
        _showGeneralNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
        );
      }
    }

    _rooms.add(
      RealtimeService.room('user:$userId')
        ..on('notification:new', onNotification)
        ..join(),
    );
    _rooms.add(
      RealtimeService.room('broadcast:all')
        ..on('notification:new', onNotification)
        ..join(),
    );

    if (!await ApiService.getIsAdmin()) return;

    final adminRoom = RealtimeService.room('emergency:admin')
      ..on('emergency:sos', (data) {
        final userName = data['user_name']?.toString() ?? 'A user';
        final phone = data['user_phone']?.toString() ?? 'N/A';
        final trip = data['trip_name']?.toString();
        final lat = data['latitude'];
        final lng = data['longitude'];
        final alertId = data['alert_id']?.toString() ?? '';
        final locationLabel = (lat != null && lng != null)
            ? '${double.tryParse(lat.toString())?.toStringAsFixed(4) ?? lat}, '
                  '${double.tryParse(lng.toString())?.toStringAsFixed(4) ?? lng}'
            : 'Unknown location';

        final body =
            '$userName needs help!\n'
            'Phone: $phone'
            '${trip != null ? "\nTrip: $trip" : ""}'
            '\nLocation: $locationLabel';

        _incrementUnread();
        _showEmergencyNotification(
          id: alertId.hashCode,
          title: '🚨 Emergency SOS — $userName',
          body: body,
        );
      })
      ..on('emergency:resolved', (data) {
        final alertId = data['alert_id']?.toString() ?? '';
        _showGeneralNotification(
          id: ('resolved_$alertId').hashCode,
          title: '✅ Emergency Resolved',
          body: 'An emergency alert has been marked as resolved.',
        );
      })
      ..join();
    _rooms.add(adminRoom);
    debugPrint('[NotificationService] Listening on admin emergency channel');
  }

  void stopListening() {
    for (final r in _rooms) {
      r.leave();
    }
    _rooms.clear();
  }

  // ── Public helpers called by EmergencySOSScreen ───────────────────────────

  /// Show a confirmation notification immediately after SOS is triggered.
  Future<void> showSOSSent() async {
    await initialize();
    await _showEmergencyNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🚨 SOS Alert Sent',
      body:
          'Your emergency alert has been broadcast to all admins. Stay calm — help is coming.',
    );
  }

  /// Show a resolved confirmation notification.
  Future<void> showSOSResolved() async {
    await initialize();
    await _showGeneralNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ Emergency Resolved',
      body: 'Your emergency alert has been marked as resolved.',
    );
  }

  // ── Unread badge management ───────────────────────────────────────────────
  int get unreadCount => _unreadCount;

  void setUnreadCount(int count) {
    _unreadCount = count;
    _notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    _notifyListeners();
  }

  void _incrementUnread() {
    _unreadCount++;
    _notifyListeners();
  }

  void addUnreadListener(VoidCallback cb) => _unreadListeners.add(cb);
  void removeUnreadListener(VoidCallback cb) => _unreadListeners.remove(cb);

  void _notifyListeners() {
    for (final cb in _unreadListeners) {
      cb();
    }
  }

  // ── Private show helpers ──────────────────────────────────────────────────
  Future<void> _showEmergencyNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _kEmergencyChannelId,
          'Emergency SOS',
          channelDescription: 'High-priority emergency alert notifications',
          importance: Importance.max,
          priority: Priority.max,
          color: const Color(0xFFB71C1C),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          playSound: true,
          fullScreenIntent: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _showGeneralNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _kGeneralChannelId,
          'SafarSync Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
