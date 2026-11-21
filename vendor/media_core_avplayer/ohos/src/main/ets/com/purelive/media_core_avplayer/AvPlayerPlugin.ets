/*
 * media_core_avplayer — HarmonyOS AVPlayer backend for media_core.
 *
 * Registers the method/event channels the Dart adapter talks to, and owns the
 * AVPlayer instances (one per Dart player handle).
 */

import {
  AbilityAware,
  AbilityPluginBinding,
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
  TextureRegistry
} from '@ohos/flutter_ohos';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { AvPlayerController, OpenRequest } from './AvPlayerController';

const TAG = 'AvPlayerPlugin';
const DOMAIN = 0x0000;
const METHOD_CHANNEL = 'com.purelive/av_player';
const EVENT_CHANNEL = 'com.purelive/av_player/events';

class EventBridge implements StreamHandler {
  private sink: EventSink | null = null;

  onListen(args: Object, events: EventSink): void {
    this.sink = events;
  }

  onCancel(args: Object): void {
    this.sink = null;
  }

  emit(event: Record<string, Object>): void {
    const sink = this.sink;
    if (sink == null) {
      return;
    }
    try {
      sink.success(event);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'event delivery failed: %{public}s', `${error}`);
    }
  }
}

export default class AvPlayerPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private readonly events: EventBridge = new EventBridge();
  private registry: TextureRegistry | null = null;
  private players: Map<number, AvPlayerController> = new Map();
  private nextPlayerId: number = 1;
  private context: common.UIAbilityContext | null = null;

  getUniqueClassName(): string {
    return 'AvPlayerPlugin';
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.context = null;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.registry = binding.getTextureRegistry();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
    this.channel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL);
    this.eventChannel.setStreamHandler(this.events);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    if (this.eventChannel != null) {
      this.eventChannel.setStreamHandler(null);
      this.eventChannel = null;
    }
    this.players.forEach((controller: AvPlayerController) => {
      controller.release();
    });
    this.players.clear();
    this.registry = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'create':
        this.createPlayer(result);
        break;
      case 'open':
        this.handleOpen(call, result);
        break;
      case 'play':
        this.withPlayer(call, result, (controller: AvPlayerController) => controller.play());
        break;
      case 'pause':
        this.withPlayer(call, result, (controller: AvPlayerController) => controller.pause());
        break;
      case 'stop':
        this.withPlayer(call, result, (controller: AvPlayerController) => controller.stop());
        break;
      case 'seek':
        this.withPlayer(call, result, (controller: AvPlayerController) => {
          controller.seek(Number(call.argument('positionMs') as number));
          return Promise.resolve();
        });
        break;
      case 'setVolume':
        this.withPlayer(call, result, (controller: AvPlayerController) => {
          controller.setVolume(Number(call.argument('volume') as number));
          return Promise.resolve();
        });
        break;
      case 'setVideoSurfaceEnabled':
        this.withPlayer(call, result, (controller: AvPlayerController) => {
          controller.setVideoSurfaceEnabled(Boolean(call.argument('enabled') as boolean));
          return Promise.resolve();
        });
        break;
      case 'release':
        this.releasePlayer(call, result);
        break;
      case 'log': {
        // Diagnostic bridge: Dart has no stdout on this platform, so the Dart
        // side reports its own lifecycle through here and it lands in hilog
        // next to the native lines.
        const message = call.argument('message') as string | null;
        hilog.info(0x0000, 'AvPlayerDart', '%{public}s', message == null ? '' : message);
        result.success(null);
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }

  private async createPlayer(result: MethodResult): Promise<void> {
    const registry = this.registry;
    if (registry == null) {
      result.error('unavailable', 'TextureRegistry is not attached.', null);
      return;
    }
    const playerId = this.nextPlayerId++;
    try {
      const textureId = registry.getTextureId();
      const entry = registry.registerTexture(textureId);
      const controller = new AvPlayerController(
        playerId,
        textureId,
        entry,
        registry,
        (event: Record<string, Object>) => this.events.emit(event)
      );
      await controller.create();
      this.players.set(playerId, controller);
      const payload: Record<string, Object> = {
        'playerId': playerId,
        'textureId': textureId
      };
      result.success(payload);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'create failed: %{public}s', `${error}`);
      result.error('create_failed', `${error}`, null);
    }
  }

  private async handleOpen(call: MethodCall, result: MethodResult): Promise<void> {
    const controller = this.controllerOf(call);
    if (controller == null) {
      result.error('no_player', 'Unknown player id.', null);
      return;
    }
    const url = String(call.argument('url') as string);
    // ArkTS forbids implicitly-typed values ('Any' is an ESObject alias), so
    // the decoded map is named through its real type at the call site.
    const map = call.argument('headers') as Map<Object, Object> | null;
    const headers: Record<string, string> = {};
    if (map != null) {
      map.forEach((value: Object, key: Object) => {
        headers[`${key}`] = `${value}`;
      });
    }
    const request: OpenRequest = { url: url, headers: headers };
    try {
      await controller.open(request);
      result.success(null);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'open failed: %{public}s', `${error}`);
      result.error('open_failed', `${error}`, null);
    }
  }

  private withPlayer(
    call: MethodCall,
    result: MethodResult,
    action: (controller: AvPlayerController) => Promise<void>
  ): void {
    const controller = this.controllerOf(call);
    if (controller == null) {
      result.error('no_player', 'Unknown player id.', null);
      return;
    }
    action(controller).then(() => {
      result.success(null);
    }).catch((error: Object) => {
      hilog.error(DOMAIN, TAG, 'command failed: %{public}s', `${error}`);
      result.error('command_failed', `${error}`, null);
    });
  }

  private async releasePlayer(call: MethodCall, result: MethodResult): Promise<void> {
    const playerId = Number(call.argument('playerId') as number);
    const controller = this.players.get(playerId);
    this.players.delete(playerId);
    if (controller != null) {
      await controller.release();
    }
    result.success(null);
  }

  private controllerOf(call: MethodCall): AvPlayerController | null {
    const playerId = Number(call.argument('playerId') as number);
    const controller = this.players.get(playerId);
    return controller == null ? null : controller;
  }
}
