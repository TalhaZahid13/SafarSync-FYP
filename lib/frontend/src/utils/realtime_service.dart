import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase Realtime *private broadcast* channels that
/// replaces the old Socket.io rooms one-for-one:
///
/// ```text
///   Socket.io room            Supabase topic
///   ------------------------  ----------------------
///   user:<id>                 user:<id>
///   group:<id>  (chat)        group:<id>
///   group-tracking:<id>       group-tracking:<id>
///   emergency:admin           emergency:admin
///   (io.emit to everyone)     broadcast:all
/// ```
///
/// Server-side events are emitted by the `api` Edge Function; who may join
/// which topic is enforced by RLS policies on `realtime.messages`.
class RealtimeRoom {
  RealtimeRoom._(this.topic, this._channel);

  final String topic;
  final RealtimeChannel _channel;
  bool _subscribed = false;
  bool _disposed = false;

  /// Fires with `true` once joined and `false` on error/close.
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  /// Register a handler for a broadcast [event]. Call before [join].
  RealtimeRoom on(
    String event,
    void Function(Map<String, dynamic> data) handler,
  ) {
    _channel.onBroadcast(
      event: event,
      callback: (message) {
        if (_disposed) return;
        // Messages arrive as {type, event, payload}; unwrap to the payload so
        // handlers see exactly what the old socket.io events carried.
        final inner = message['payload'];
        final data = inner is Map ? Map<String, dynamic>.from(inner) : message;
        try {
          handler(data);
        } catch (e) {
          debugPrint('[Realtime] handler for $event on $topic threw: $e');
        }
      },
    );
    return this;
  }

  /// Join the topic. Safe to call once; reconnection is automatic.
  RealtimeRoom join() {
    if (_subscribed) return this;
    _subscribed = true;
    _channel.subscribe((status, error) {
      if (_disposed) return;
      connected.value = status == RealtimeSubscribeStatus.subscribed;
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        debugPrint('[Realtime] $topic → $status ${error ?? ''}');
      }
    });
    return this;
  }

  /// Client → room broadcast (typing indicators, live group locations).
  Future<void> emit(String event, Map<String, dynamic> payload) async {
    if (_disposed) return;
    try {
      await _channel.sendBroadcastMessage(event: event, payload: payload);
    } catch (e) {
      debugPrint('[Realtime] emit $event on $topic failed: $e');
    }
  }

  Future<void> leave() async {
    if (_disposed) return;
    _disposed = true;
    connected.value = false;
    try {
      await Supabase.instance.client.removeChannel(_channel);
    } catch (_) {}
    connected.dispose();
  }
}

class RealtimeService {
  RealtimeService._();

  /// Create a private room for [topic]. Requires a signed-in user.
  static RealtimeRoom room(String topic) {
    final client = Supabase.instance.client;
    final channel = client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );
    return RealtimeRoom._(topic, channel);
  }

  static bool get canConnect =>
      Supabase.instance.client.auth.currentSession != null;
}
