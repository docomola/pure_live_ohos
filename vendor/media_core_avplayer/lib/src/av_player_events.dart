import 'dart:async';

import 'package:flutter/services.dart';

/// Event kinds the native side reports.
enum AvPlayerEventType {
  prepared,
  playing,
  paused,
  stopped,
  completed,
  buffering,
  bufferProgress,
  position,
  duration,
  size,
  frame,
  error,
  unknown,
}

/// One decoded event from the native player.
final class AvPlayerEvent {
  const AvPlayerEvent({required this.playerId, required this.type, this.data = const {}});

  final int playerId;
  final AvPlayerEventType type;
  final Map<Object?, Object?> data;

  int? get intValue => switch (data['positionMs'] ?? data['durationMs'] ?? data['width']) {
    final int value => value,
    final num value => value.toInt(),
    _ => null,
  };

  String? get message => data['message'] as String?;

  bool get isBuffering => (data['buffering'] as bool?) ?? false;

  double? get percent => (data['percent'] as num?)?.toDouble();

  @override
  String toString() => 'AvPlayerEvent($playerId, ${type.name}, $data)';
}

/// Thin wrapper over the two platform channels the native plugin owns.
///
/// A single process-wide event stream is shared by every adapter instance;
/// each adapter filters on its own player id. Subscribing per adapter would
/// re-register the platform-side stream handler on every listen, which drops
/// the events of the players that were already listening.
final class AvPlayerChannel {
  AvPlayerChannel._();

  static final AvPlayerChannel instance = AvPlayerChannel._();

  static const MethodChannel _methods = MethodChannel('com.purelive/av_player');
  static const EventChannel _events = EventChannel('com.purelive/av_player/events');

  Stream<AvPlayerEvent>? _broadcast;

  /// All events, from every player this process created.
  Stream<AvPlayerEvent> get events {
    final existing = _broadcast;
    if (existing != null) {
      return existing;
    }
    final stream = _events
        .receiveBroadcastStream()
        .map(_decode)
        .where((event) => event != null)
        .cast<AvPlayerEvent>()
        .asBroadcastStream();
    _broadcast = stream;
    return stream;
  }

  static AvPlayerEvent? _decode(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final playerId = switch (raw['playerId']) {
      final int value => value,
      final num value => value.toInt(),
      _ => -1,
    };
    if (playerId < 0) {
      return null;
    }
    return AvPlayerEvent(playerId: playerId, type: _typeOf(raw['type'] as String?), data: raw);
  }

  static AvPlayerEventType _typeOf(String? name) => switch (name) {
    'prepared' => AvPlayerEventType.prepared,
    'playing' => AvPlayerEventType.playing,
    'paused' => AvPlayerEventType.paused,
    'stopped' => AvPlayerEventType.stopped,
    'completed' => AvPlayerEventType.completed,
    'buffering' => AvPlayerEventType.buffering,
    'bufferProgress' => AvPlayerEventType.bufferProgress,
    'position' => AvPlayerEventType.position,
    'duration' => AvPlayerEventType.duration,
    'size' => AvPlayerEventType.size,
    'frame' => AvPlayerEventType.frame,
    'error' => AvPlayerEventType.error,
    _ => AvPlayerEventType.unknown,
  };

  /// Creates a native player plus its external texture.
  Future<({int playerId, int textureId})> create() async {
    final reply = await _methods.invokeMapMethod<String, Object?>('create');
    final playerId = (reply?['playerId'] as num?)?.toInt();
    final textureId = (reply?['textureId'] as num?)?.toInt();
    if (playerId == null || textureId == null) {
      throw PlatformException(code: 'create_failed', message: 'The platform returned no player handle.');
    }
    return (playerId: playerId, textureId: textureId);
  }

  Future<void> open({required int playerId, required String url, required Map<String, String> headers}) {
    return _methods.invokeMethod<void>('open', <String, Object?>{
      'playerId': playerId,
      'url': url,
      'headers': headers,
    });
  }

  Future<void> play(int playerId) => _methods.invokeMethod<void>('play', {'playerId': playerId});

  Future<void> pause(int playerId) => _methods.invokeMethod<void>('pause', {'playerId': playerId});

  Future<void> stop(int playerId) => _methods.invokeMethod<void>('stop', {'playerId': playerId});

  Future<void> seek(int playerId, Duration position) =>
      _methods.invokeMethod<void>('seek', {'playerId': playerId, 'positionMs': position.inMilliseconds});

  Future<void> setVolume(int playerId, double volume) =>
      _methods.invokeMethod<void>('setVolume', {'playerId': playerId, 'volume': volume});

  Future<void> setVideoSurfaceEnabled(int playerId, bool enabled) =>
      _methods.invokeMethod<void>('setVideoSurfaceEnabled', {'playerId': playerId, 'enabled': enabled});

  Future<void> release(int playerId) => _methods.invokeMethod<void>('release', {'playerId': playerId});

  /// Writes a line to the platform log next to the native player's own.
  ///
  /// Dart's `print` does not reach hilog on this embedding, which makes a
  /// playback failure invisible from outside the app.
  Future<void> log(String message) async {
    try {
      await _methods.invokeMethod<void>('log', {'message': message});
    } catch (_) {
      // Diagnostics must never be the reason playback breaks.
    }
  }
}
