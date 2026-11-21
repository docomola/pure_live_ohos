
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { GlassNavBridge } from '../common/GlassNavBridge';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    // 沉浸光感底栏的通道必须挂在同一个引擎上，才能和 Flutter 侧的
    // 'pure_live/glass_nav' 对上。
    GlassNavBridge.getInstance().attach(flutterEngine)
  }
}
