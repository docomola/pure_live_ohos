/*
 * media_core_avplayer — HarmonyOS AVPlayer backend for media_core.
 *
 * One controller instance owns one AVPlayer plus the external texture it
 * renders into. The texture is created by the Flutter engine
 * (TextureRegistry), and its surface id is handed to AVPlayer.surfaceId, so
 * the decoded frames reach Flutter as a normal texture — no platform view,
 * which means Flutter overlays (danmaku, controls) composite on top of the
 * video instead of behind it.
 */

import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SurfaceTextureEntry, TextureRegistry } from '@ohos/flutter_ohos';

const TAG = 'AvPlayerController';
const DOMAIN = 0x0000;

/** Minimum gap between two buffer-percentage reports. */
const BUFFER_PERCENT_INTERVAL_MS = 500;

/**
 * Geometry of the external texture on the very first open. AVPlayer only
 * reports the real frame size in `prepared`, which is already too late to
 * resize the surface: changing the buffer geometry while frames are in flight
 * leaves the producer writing into invalidated buffers and the picture stays
 * black. 1280x720 covers the common live resolution; on a later open the size
 * learned from the previous source is applied before `prepare()` instead.
 */
const DEFAULT_BUFFER_WIDTH = 1280;
const DEFAULT_BUFFER_HEIGHT = 720;

/** Emits one event object to the Dart side. */
export type EventEmitter = (event: Record<string, Object>) => void;

/** Parameters for one open. */
export interface OpenRequest {
  url: string;
  headers: Record<string, string>;
}

export class AvPlayerController {
  readonly playerId: number;
  readonly textureId: number;

  private avPlayer: media.AVPlayer | null = null;
  private readonly textureEntry: SurfaceTextureEntry;
  private readonly registry: TextureRegistry;
  private readonly emit: EventEmitter;

  private surfaceId: string = '';
  private state: media.AVPlayerState = 'idle';
  private prepared: boolean = false;
  private released: boolean = false;

  /** Applied once the player reaches `prepared`. */
  private pendingVolume: number = 1.0;
  private pendingSeekMs: number = -1;
  private wantPlay: boolean = false;
  private videoWidth: number = 0;
  private videoHeight: number = 0;

  /** Geometry currently applied to the producer surface. */
  private bufferWidth: number = 0;
  private bufferHeight: number = 0;
  /** Frame size learned from the last source, applied before the next open. */
  private nextWidth: number = 0;
  private nextHeight: number = 0;

  /**
   * `bufferingUpdate` fires per network read — hundreds of times per second on
   * a live stream. Each forwarded event is a Dart rebuild, so the percentage
   * is coalesced here instead of flooding the event channel; only a transition
   * (start/end) is reported as it arrives.
   */
  private bufferingActive: boolean = false;
  private lastBufferPercent: number = -1;
  private lastBufferEmitMs: number = 0;

  constructor(
    playerId: number,
    textureId: number,
    textureEntry: SurfaceTextureEntry,
    registry: TextureRegistry,
    emit: EventEmitter
  ) {
    this.playerId = playerId;
    this.textureId = textureId;
    this.textureEntry = textureEntry;
    this.registry = registry;
    this.emit = emit;
    // The engine hands out a 1x1 buffer by default; AVPlayer writes in video
    // resolution once the first frame arrives, which resizes it (see
    // onVideoSize).
    this.surfaceId = textureEntry.getSurfaceId().toString();
    hilog.info(DOMAIN, TAG, 'created player %{public}d texture %{public}d surface %{public}s',
      playerId, textureId, this.surfaceId);
  }

  async create(): Promise<void> {
    if (this.avPlayer != null) {
      return;
    }
    const player = await media.createAVPlayer();
    this.avPlayer = player;
    this.bindEvents(player);
    // No frames exist yet: the buffer geometry can be set safely here.
    this.applyBufferSize(DEFAULT_BUFFER_WIDTH, DEFAULT_BUFFER_HEIGHT);
  }

  /** Opens a source, replacing whatever played before. */
  async open(request: OpenRequest): Promise<void> {
    const player = this.avPlayer;
    if (player == null) {
      throw new Error('AVPlayer is not created');
    }
    this.prepared = false;
    this.wantPlay = false;
    this.bufferingActive = false;
    this.lastBufferPercent = -1;

    // A new source can only be handed to an idle player.
    if (this.state !== 'idle') {
      try {
        await player.reset();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'reset before open failed: %{public}s', this.describe(error));
      }
    }

    const headers: Record<string, string> = {};
    for (const key of Object.keys(request.headers)) {
      headers[key] = request.headers[key];
    }
    // `reset()` just put the player back in idle, so no buffers are in flight.
    // Apply the size learned from the previous source here — never after
    // `prepared`, where a geometry change blinds the current playback.
    if (this.nextWidth > 0 && this.nextHeight > 0 &&
        (this.nextWidth !== this.bufferWidth || this.nextHeight !== this.bufferHeight)) {
      this.applyBufferSize(this.nextWidth, this.nextHeight);
    }

    const source = media.createMediaSourceWithUrl(request.url, headers);
    await player.setMediaSource(source);
    // stateChange('initialized') is where the surface is attached and
    // prepare() is called; see onStateChange.
  }

  async play(): Promise<void> {
    const player = this.avPlayer;
    if (player == null) {
      return;
    }
    if (!this.prepared) {
      // `play` before the first frame is a request, not a command: the
      // player has nothing to start yet. Remembered and replayed on prepared.
      this.wantPlay = true;
      return;
    }
    try {
      await player.play();
    } catch (error) {
      this.reportError(-1, `play failed: ${this.describe(error)}`);
    }
  }

  async pause(): Promise<void> {
    this.wantPlay = false;
    const player = this.avPlayer;
    if (player == null || this.state !== 'playing') {
      return;
    }
    try {
      await player.pause();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'pause failed: %{public}s', this.describe(error));
    }
  }

  async stop(): Promise<void> {
    this.wantPlay = false;
    const player = this.avPlayer;
    if (player == null || this.state === 'idle' || this.state === 'released') {
      return;
    }
    try {
      await player.stop();
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'stop failed: %{public}s', this.describe(error));
    }
  }

  seek(positionMs: number): void {
    const player = this.avPlayer;
    if (player == null) {
      return;
    }
    if (!this.prepared) {
      this.pendingSeekMs = positionMs;
      return;
    }
    try {
      player.seek(Math.max(0, Math.round(positionMs)));
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'seek failed: %{public}s', this.describe(error));
    }
  }

  setVolume(volume: number): void {
    const clamped = Math.min(1, Math.max(0, volume));
    this.pendingVolume = clamped;
    const player = this.avPlayer;
    if (player == null || !this.prepared) {
      return;
    }
    try {
      player.setVolume(clamped);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'setVolume failed: %{public}s', this.describe(error));
    }
  }

  /** Detaches the picture (audio-only) or re-attaches it. */
  setVideoSurfaceEnabled(enabled: boolean): void {
    const player = this.avPlayer;
    if (player == null || !this.prepared) {
      return;
    }
    try {
      player.surfaceId = enabled ? this.surfaceId : '';
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'surface switch failed: %{public}s', this.describe(error));
    }
  }

  async release(): Promise<void> {
    if (this.released) {
      return;
    }
    this.released = true;
    const player = this.avPlayer;
    this.avPlayer = null;
    if (player != null) {
      try {
        await player.release();
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'release failed: %{public}s', this.describe(error));
      }
    }
    try {
      this.registry.unregisterTexture(this.textureId);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'unregisterTexture failed: %{public}s', this.describe(error));
    }
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  private bindEvents(player: media.AVPlayer): void {
    player.on('stateChange', (state: media.AVPlayerState) => {
      this.state = state;
      hilog.info(DOMAIN, TAG, 'player %{public}d state -> %{public}s', this.playerId, state);
      this.onStateChange(player, state);
    });

    player.on('error', (error: BusinessError) => {
      // The code lands in the Dart error path, which is what the recovery
      // ladder observes; the message is what a user sees.
      this.reportError(error.code, `AVPlayer error ${error.code}: ${error.message}`);
    });

    player.on('videoSizeChange', (width: number, height: number) => {
      this.onVideoSize(width, height);
    });

    player.on('timeUpdate', (timeMs: number) => {
      this.emit({
        'playerId': this.playerId,
        'type': 'position',
        'positionMs': Math.max(0, Math.round(timeMs))
      });
    });

    player.on('durationUpdate', (durationMs: number) => {
      this.emit({
        'playerId': this.playerId,
        'type': 'duration',
        'durationMs': Math.max(0, Math.round(durationMs))
      });
    });

    player.on('bufferingUpdate', (infoType: media.BufferingInfoType, value: number) => {
      if (infoType === media.BufferingInfoType.BUFFERING_START) {
        if (this.bufferingActive) {
          return;
        }
        this.bufferingActive = true;
        this.emit({ 'playerId': this.playerId, 'type': 'buffering', 'buffering': true });
      } else if (infoType === media.BufferingInfoType.BUFFERING_END) {
        if (!this.bufferingActive) {
          return;
        }
        this.bufferingActive = false;
        this.lastBufferPercent = -1;
        this.emit({ 'playerId': this.playerId, 'type': 'buffering', 'buffering': false });
      } else if (infoType === media.BufferingInfoType.BUFFERING_PERCENT) {
        const now = Date.now();
        const changed = this.lastBufferPercent < 0 || Math.abs(value - this.lastBufferPercent) >= 1;
        if (!changed || now - this.lastBufferEmitMs < BUFFER_PERCENT_INTERVAL_MS) {
          return;
        }
        this.lastBufferPercent = value;
        this.lastBufferEmitMs = now;
        this.emit({
          'playerId': this.playerId,
          'type': 'bufferProgress',
          'percent': value
        });
      }
    });

    player.on('seekDone', (positionMs: number) => {
      this.emit({
        'playerId': this.playerId,
        'type': 'position',
        'positionMs': Math.max(0, Math.round(positionMs))
      });
    });

    player.on('endOfStream', () => {
      this.emit({ 'playerId': this.playerId, 'type': 'completed' });
    });
  }

  private onStateChange(player: media.AVPlayer, state: media.AVPlayerState): void {
    if (state === 'initialized') {
      // The surface must be attached before prepare(); attaching it later
      // leaves the player with an audio-only pipeline on some builds.
      try {
        player.surfaceId = this.surfaceId;
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'attach surface failed: %{public}s', this.describe(error));
      }
      player.prepare().catch((error: BusinessError) => {
        this.reportError(error.code, `prepare failed: ${error.message}`);
      });
      return;
    }

    if (state === 'prepared') {
      this.prepared = true;
      try {
        player.setVolume(this.pendingVolume);
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'initial volume failed: %{public}s', this.describe(error));
      }
      const width = player.width;
      const height = player.height;
      if (width > 0 && height > 0) {
        this.onVideoSize(width, height);
      }
      if (this.pendingSeekMs > 0) {
        const target = this.pendingSeekMs;
        this.pendingSeekMs = -1;
        try {
          player.seek(target);
        } catch (error) {
          hilog.warn(DOMAIN, TAG, 'pending seek failed: %{public}s', this.describe(error));
        }
      }
      this.emit({ 'playerId': this.playerId, 'type': 'prepared' });
      if (this.wantPlay) {
        this.wantPlay = false;
        player.play().catch((error: BusinessError) => {
          this.reportError(error.code, `deferred play failed: ${error.message}`);
        });
      }
      return;
    }

    if (state === 'playing') {
      this.emit({ 'playerId': this.playerId, 'type': 'playing' });
      return;
    }

    if (state === 'paused') {
      this.emit({ 'playerId': this.playerId, 'type': 'paused' });
      return;
    }

    if (state === 'completed') {
      this.emit({ 'playerId': this.playerId, 'type': 'completed' });
      return;
    }

    if (state === 'stopped') {
      this.prepared = false;
      this.emit({ 'playerId': this.playerId, 'type': 'stopped' });
      return;
    }

    if (state === 'error') {
      // The `error` event carries the reason; this only guarantees the Dart
      // side leaves the loading state even if that event never arrives.
      this.prepared = false;
      this.reportError(-1, 'AVPlayer entered the error state');
    }
  }

  private onVideoSize(width: number, height: number): void {
    if (width <= 0 || height <= 0) {
      return;
    }
    if (width === this.videoWidth && height === this.videoHeight) {
      return;
    }
    this.videoWidth = width;
    this.videoHeight = height;
    // Remember, do not apply: at this point AVPlayer is already rendering.
    // The geometry is picked up by the next open(), while the player is idle.
    this.nextWidth = width;
    this.nextHeight = height;
    this.emit({
      'playerId': this.playerId,
      'type': 'size',
      'width': width,
      'height': height
    });
  }

  private applyBufferSize(width: number, height: number): void {
    if (width === this.bufferWidth && height === this.bufferHeight) {
      return;
    }
    try {
      this.registry.setTextureBufferSize(this.textureId, width, height);
      this.bufferWidth = width;
      this.bufferHeight = height;
      hilog.info(DOMAIN, TAG, 'texture %{public}d buffer %{public}dx%{public}d',
        this.textureId, width, height);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'setTextureBufferSize failed: %{public}s', this.describe(error));
    }
  }

  private reportError(code: number, message: string): void {
    hilog.error(DOMAIN, TAG, 'player %{public}d error: %{public}s', this.playerId, message);
    this.emit({
      'playerId': this.playerId,
      'type': 'error',
      'code': code,
      'message': message
    });
  }

  private describe(error: Object): string {
    const businessError = error as BusinessError;
    if (businessError != null && businessError.message != null) {
      return `${businessError.code}: ${businessError.message}`;
    }
    return `${error}`;
  }
}
