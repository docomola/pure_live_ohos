import { FlutterEngine, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import hilog from '@ohos.hilog';

/**
 * Dart 与原生沉浸光感底栏之间的桥。
 *
 * 之所以不用结构化参数，而是整包传 JSON 字符串：StandardMessageCodec 解出来的
 * Map 在 ArkTS 严格模式下要逐层做类型断言，字段一多就非常脆；字符串走
 * JSON.parse 只需一次断言，两端都能各自演进字段。
 */

const DOMAIN: number = 0x5001;
const TAG: string = 'PureLiveGlassNav';
const CHANNEL_NAME: string = 'pure_live/glass_nav';

export const GLASS_NAV_ITEMS_KEY: string = 'glassNavItems';
export const GLASS_NAV_SELECTED_KEY: string = 'glassNavSelected';
export const GLASS_NAV_VISIBLE_KEY: string = 'glassNavVisible';

export interface GlassNavItem {
  key: string;
  label: string;
}

interface ConfigurePayload {
  items: GlassNavItem[];
  selected: number;
  visible: boolean;
}

interface SelectedPayload {
  selected: number;
}

interface VisiblePayload {
  visible: boolean;
}

interface SelectedEvent {
  index: number;
}

export class GlassNavBridge {
  private static instance: GlassNavBridge | null = null;
  private channel: MethodChannel | null = null;

  static getInstance(): GlassNavBridge {
    if (GlassNavBridge.instance === null) {
      GlassNavBridge.instance = new GlassNavBridge();
    }
    return GlassNavBridge.instance;
  }

  attach(engine: FlutterEngine): void {
    if (this.channel !== null) {
      return;
    }
    this.channel = new MethodChannel(engine.dartExecutor.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        this.onMethodCall(call, result);
      }
    });
    hilog.info(DOMAIN, TAG, 'channel ready');
  }

  private onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'configure') {
      this.applyConfigure(call.args as string);
      result.success(null);
      return;
    }
    if (call.method === 'setSelected') {
      this.applySelected(call.args as string);
      result.success(null);
      return;
    }
    if (call.method === 'setVisible') {
      this.applyVisible(call.args as string);
      result.success(null);
      return;
    }
    result.notImplemented();
  }

  private applyConfigure(raw: string): void {
    try {
      const payload = JSON.parse(raw) as ConfigurePayload;
      const items: GlassNavItem[] = payload.items === undefined || payload.items === null ? [] : payload.items;
      AppStorage.setOrCreate<GlassNavItem[]>(GLASS_NAV_ITEMS_KEY, items);
      AppStorage.setOrCreate<number>(GLASS_NAV_SELECTED_KEY, payload.selected);
      AppStorage.setOrCreate<boolean>(GLASS_NAV_VISIBLE_KEY, payload.visible);
      hilog.info(DOMAIN, TAG, 'configure items=%{public}d selected=%{public}d', items.length, payload.selected);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'configure failed: %{public}s', (error as Error).message);
    }
  }

  private applySelected(raw: string): void {
    try {
      const payload = JSON.parse(raw) as SelectedPayload;
      AppStorage.setOrCreate<number>(GLASS_NAV_SELECTED_KEY, payload.selected);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'setSelected failed: %{public}s', (error as Error).message);
    }
  }

  private applyVisible(raw: string): void {
    try {
      const payload = JSON.parse(raw) as VisiblePayload;
      AppStorage.setOrCreate<boolean>(GLASS_NAV_VISIBLE_KEY, payload.visible);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'setVisible failed: %{public}s', (error as Error).message);
    }
  }

  /** 原生侧点击某个栏目：先本地高亮（手感零延迟），再通知 Flutter 切页。 */
  select(index: number): void {
    AppStorage.setOrCreate<number>(GLASS_NAV_SELECTED_KEY, index);
    if (this.channel === null) {
      return;
    }
    const event: SelectedEvent = { index: index };
    this.channel.invokeMethod('onSelected', JSON.stringify(event));
  }
}
