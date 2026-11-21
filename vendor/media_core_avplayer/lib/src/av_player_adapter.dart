import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:media_core/media_core.dart';

import 'av_player_events.dart';

/// Backend id of the HarmonyOS AVPlayer adapter.
const String kAvPlayerBackendId = 'avplayer';

/// [PlayerAdapter] backed by the HarmonyOS system media engine (AVPlayer).
///
/// The engine decodes through the platform's own pipeline (H.264/H.265 in
/// hardware, AAC/MP3 audio) and writes the picture into an external texture
/// the Flutter engine owns, so the picture is a normal composited layer: the
/// room's controls, danmaku and PiP chrome draw on top of it without a
/// platform view's z-order problems.
///
/// It is deliberately a thin transport. Everything the app knows about live
/// playback policy — retry ladders, line switching, quality pins — stays in
/// media_core; this class only moves commands to the platform and platform
/// reports back.
final class AvPlayerAdapter extends PlayerAdapterBase implements PlayerVideo {
  AvPlayerAdapter({super.id = kAvPlayerBackendId, PlayerAdapterCapabilities capabilities = defaultCapabilities})
    : super(capabilities: capabilities);

  /// What the platform engine can actually do.
  ///
  /// `supportsAudioOnly` is declared because the adapter implements it — by
  /// detaching the rendering surface — and not because AVPlayer can stop
  /// decoding the video track; see [onSetAudioOnly].
  ///
  /// `supportsRateControl` stays false: the platform only accepts a fixed
  /// enumeration of speeds, which is not the general contract, and live
  /// streams have nothing to speed up.
  ///
  /// `supportsVideoFrameProgress` stays false: AVPlayer exposes a
  /// `startRenderFrame` callback, but this build never raises it, and a
  /// backend that promises per-frame progress must actually report it.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsStop: true,
    supportsVolumeControl: true,
    supportsAudioOnly: true,
    supportsVideoSizeChanged: true,
    supportsVideoFrameProgress: false,
    supportsBufferingProgress: true,
    supportsHardwareDecoder: true,
    supportedProtocols: {'http', 'https', 'hls', 'dash', 'file'},
    supportedFormats: {'hls', 'flv', 'mp4', 'mkv', 'mpegTs', 'ts', 'dash', 'mpd', 'm4a', 'mp3'},
  );

  final ValueNotifier<BoxFit> _fitNotifier = ValueNotifier<BoxFit>(BoxFit.contain);
  final ValueNotifier<Size?> _videoSizeNotifier = ValueNotifier<Size?>(null);

  StreamSubscription<AvPlayerEvent>? _eventSubscription;
  Completer<void>? _prepared;

  int? _playerId;
  int? _textureId;
  BoxFit _videoFit = BoxFit.contain;
  bool _audioOnly = false;

  /// Whether the engine is currently stalled waiting for data.
  ///
  /// Buffer-percentage reports arrive far more often than the state changes,
  /// so the flag is tracked here and the percentages are forwarded on top of
  /// it instead of re-asserting "buffering" on every sample.
  bool _buffering = false;

  /// Whether the platform surface is attached to the picture.
  bool get _surfaceEnabled => !_audioOnly;

  /// The texture the video layer renders, once [onInitialize] has run.
  int? get textureId => _textureId;

  /// Size of the decoded picture, when the engine has reported it.
  ValueListenable<Size?> get videoSize => _videoSizeNotifier;

  /// Current viewport fit, as a listenable for the surface widget.
  ValueListenable<BoxFit> get fitListenable => _fitNotifier;

  /// Events arrive through one process-wide stream, so the base's
  /// source-scoped gate stays open and the adapter filters by id itself.
  @override
  bool get gatesSourceEvents => false;

  /// A failure reported while a source is being opened means the source did
  /// not open — the caller must not be told "opened" first.
  @override
  bool get engineReportsOpenFailure => true;

  AvPlayerChannel get _channel => AvPlayerChannel.instance;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onInitialize(PlayerAdapterContext context) async {
    final ({int playerId, int textureId}) handle;
    try {
      handle = await _channel.create();
    } catch (error) {
      await _channel.log('adapter init FAILED: $error');
      rethrow;
    }

    _playerId = handle.playerId;
    _textureId = handle.textureId;
    await _channel.log('adapter init: player=${handle.playerId} texture=${handle.textureId}');

    _eventSubscription = _channel.events.where((event) => event.playerId == handle.playerId).listen(_onEvent);

    final volume = context.config.volume;
    if (volume != 1.0) {
      await _channel.setVolume(handle.playerId, volume.clamp(0.0, 1.0));
    }
  }

  @override
  Future<void> onOpen(PlayerSource source) async {
    final playerId = _playerId;
    if (playerId == null) {
      throw StateError('$runtimeType has no platform player.');
    }
    await _channel.log('open: ${source.uri} headers=${source.headers?.values.keys.toList()}');

    _videoSizeNotifier.value = null;
    _buffering = false;
    _prepared = Completer<void>();

    final url = source.uri.toString();
    final headers = source.headers?.values ?? const <String, String>{};

    await _channel.open(playerId: playerId, url: url, headers: headers);

    // Opening is not done when the URL is handed over: the engine still has
    // to probe the container and produce a first frame. Waiting here is what
    // keeps the room on its loading state instead of showing a black picture
    // that never fills in, and what turns a dead line into an error the
    // recovery ladder can act on.
    await _awaitPrepared();
    await _channel.log('opened: ${source.uri}');
  }

  Future<void> _awaitPrepared() async {
    final prepared = _prepared;
    if (prepared == null) {
      return;
    }
    try {
      await prepared.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw StateError('AVPlayer did not reach the prepared state in time.');
    } finally {
      _prepared = null;
    }
  }

  @override
  Future<void> onAfterOpen(PlayerSource source) async {
    if (_audioOnly) {
      await _applySurfaceState();
    }
  }

  @override
  Future<void> onPlay() async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.play(playerId);
  }

  @override
  Future<void> onPause() async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.pause(playerId);
  }

  @override
  Future<void> onStop() async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.stop(playerId);
  }

  @override
  Future<void> onSeek(Duration position) async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.seek(playerId, position);
  }

  @override
  Future<void> onSetVolume(double volume) async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.setVolume(playerId, volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> onSetRate(double rate) async {
    // Declared unsupported; the platform's speed control is a fixed
    // enumeration that does not model an arbitrary rate.
  }

  @override
  Future<void> onSetAudioOnly(bool audioOnly) async {
    _audioOnly = audioOnly;
    await _applySurfaceState();
  }

  Future<void> _applySurfaceState() async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.setVideoSurfaceEnabled(playerId, _surfaceEnabled);
  }

  @override
  Future<void> onClose() async {
    final playerId = _playerId;
    if (playerId == null) return;
    await _channel.stop(playerId);
  }

  @override
  Future<void> onDispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    final playerId = _playerId;
    _playerId = null;
    _textureId = null;
    if (playerId != null) {
      try {
        await _channel.release(playerId);
      } on PlatformException catch (error) {
        debugPrint('AvPlayerAdapter: release failed: $error');
      }
    }

    _fitNotifier.dispose();
    _videoSizeNotifier.dispose();
  }

  // ---------------------------------------------------------------------------
  // PlayerVideo
  // ---------------------------------------------------------------------------

  @override
  bool get available => !isDisposed && !_audioOnly && _textureId != null;

  @override
  void setVideoFit(BoxFit fit) {
    if (_videoFit == fit || isDisposed) return;
    _videoFit = fit;
    _fitNotifier.value = fit;
  }

  @override
  Widget build() {
    final textureId = _textureId;
    if (textureId == null || !available) {
      return const SizedBox.shrink();
    }
    return _AvPlayerTexture(textureId: textureId, fit: _fitNotifier, size: _videoSizeNotifier);
  }

  @override
  Future<void> attach() async {}

  @override
  Future<void> detach() async {}

  // ---------------------------------------------------------------------------
  // Platform reports
  // ---------------------------------------------------------------------------

  void _onEvent(AvPlayerEvent event) {
    switch (event.type) {
      case AvPlayerEventType.prepared:
        _channel.log('event: prepared');
        final prepared = _prepared;
        if (prepared != null && !prepared.isCompleted) {
          prepared.complete();
        }
      case AvPlayerEventType.playing:
        emitPlaying();
      case AvPlayerEventType.paused:
        emitPaused();
      case AvPlayerEventType.stopped:
        break;
      case AvPlayerEventType.completed:
        emitCompleted();
      case AvPlayerEventType.buffering:
        _buffering = event.isBuffering;
        emitBuffering(_buffering);
      case AvPlayerEventType.bufferProgress:
        final percent = event.percent;
        if (percent == null) {
          break;
        }
        // Carries the ratio only: the transport state is what the native
        // start/end transitions said, not whatever the last sample implies.
        emitBuffering(_buffering, progress: (percent / 100).clamp(0.0, 1.0));
      case AvPlayerEventType.position:
        final positionMs = event.intValue;
        if (positionMs != null) {
          emitPositionChanged(Duration(milliseconds: positionMs));
        }
      case AvPlayerEventType.duration:
        final data = event.data['durationMs'];
        final durationMs = data is num ? data.toInt() : null;
        if (durationMs != null && durationMs > 0) {
          emitDurationChanged(Duration(milliseconds: durationMs));
        }
      case AvPlayerEventType.size:
        final width = (event.data['width'] as num?)?.toInt();
        final height = (event.data['height'] as num?)?.toInt();
        if (width != null && height != null && width > 0 && height > 0) {
          _channel.log('event: size ${width}x$height');
          _videoSizeNotifier.value = Size(width.toDouble(), height.toDouble());
          emitVideoSizeChangedIfChanged(width, height);
        }
      case AvPlayerEventType.frame:
        // Never raised by this build; the capability is false so the emitter
        // must not be called (it asserts on an undeclared signal).
        break;
      case AvPlayerEventType.error:
        _channel.log('event: error ${event.message}');
        final prepared = _prepared;
        if (prepared != null && !prepared.isCompleted) {
          prepared.completeError(StateError(event.message ?? 'AVPlayer error'));
        }
        reportEngineError(message: event.message ?? 'AVPlayer error');
      case AvPlayerEventType.unknown:
        break;
    }
  }
}

/// Paints the platform texture, letterboxed by the current [BoxFit].
///
/// The texture arrives at the decoded resolution, so its box has to be fitted
/// against the viewport the host gives the player; painting it into the whole
/// viewport would stretch a 4:3 stream across a 16:9 screen.
final class _AvPlayerTexture extends StatelessWidget {
  const _AvPlayerTexture({required this.textureId, required this.fit, required this.size});

  final int textureId;
  final ValueListenable<BoxFit> fit;
  final ValueListenable<Size?> size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BoxFit>(
      valueListenable: fit,
      builder: (context, fitValue, _) {
        return ValueListenableBuilder<Size?>(
          valueListenable: size,
          builder: (context, sizeValue, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final texture = Texture(textureId: textureId);
                if (sizeValue == null || sizeValue.isEmpty) {
                  // No frame geometry yet: keep the surface attached (the
                  // engine reports its size on the first frame) but show the
                  // player background instead of a stretched single pixel.
                  return const ColoredBox(color: Color(0xFF000000), child: SizedBox.expand());
                }
                final box = constraints.biggest;
                if (box.isEmpty) {
                  return texture;
                }
                final fitted = applyBoxFit(fitValue, sizeValue, box);
                final destination = fitted.destination;
                return ClipRect(
                  child: Center(
                    child: SizedBox(
                      width: destination.width,
                      height: destination.height,
                      child: texture,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
