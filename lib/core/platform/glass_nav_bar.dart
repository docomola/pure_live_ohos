import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/core/platform/platform_utils.dart';

/// 一个交给原生底栏渲染的栏目。
///
/// 图标不上送：ArkTS 侧按 [key] 映射到系统符号（`sys.symbol.*`），
/// 这样图标永远跟随系统风格，也不需要为多套分辨率出图。
class GlassNavItem {
  const GlassNavItem({required this.key, required this.label});

  final String key;
  final String label;

  Map<String, dynamic> toJson() => <String, dynamic>{'key': key, 'label': label};
}

/// 鸿蒙原生沉浸光感底栏（ArkTS，`uiMaterial.ImmersiveMaterial`）的 Dart 端。
///
/// 底栏本身由 ArkTS 绘制并浮在 Flutter 画面之上，所以这里只负责三件事：
/// 下推栏目清单、下推选中项、接收点击回调。非鸿蒙平台 [isSupported] 为 false，
/// 调用方应回退到 Flutter 自绘的 NavigationBar。
class GlassNavBar {
  GlassNavBar._();

  static const MethodChannel _channel = MethodChannel('pure_live/glass_nav');

  /// 与 ArkTS 侧 `BAR_HEIGHT` 对齐。
  static const double barHeight = 56;

  /// 胶囊与屏幕底边的间距（ArkTS 侧 `BOTTOM_MARGIN`）。
  static const double bottomMargin = 16;

  /// 列表内容需要多留的底部高度：胶囊上沿（56+16）+ 呼吸余量。
  /// 内容本身要能从胶囊下方滚过去，否则玻璃背后永远是纯色，看不出材质。
  static const double contentInset = barHeight + bottomMargin + 16;

  /// 原生底栏被点击时回调（参数是下推时 items 的下标）。
  static void Function(int index)? onSelected;

  static bool get isSupported {
    if (kIsWeb) return false;
    return PlatformUtils.isOhos;
  }

  static bool _handlerBound = false;
  static String _lastPayload = '';

  static Future<void> _ensureHandler() async {
    if (_handlerBound) return;
    _handlerBound = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'onSelected') return null;
      final dynamic raw = call.arguments;
      if (raw is! String) return null;
      try {
        final Map<String, dynamic> args = jsonDecode(raw) as Map<String, dynamic>;
        final int index = (args['selected'] as num?)?.toInt() ?? (args['index'] as num?)?.toInt() ?? 0;
        onSelected?.call(index);
      } catch (error) {
        debugPrint('GlassNavBar: bad onSelected payload -> $error');
      }
      return null;
    });
  }

  /// 下推栏目清单与选中项。内容没变时不发消息，避免每帧过通道。
  static Future<void> configure({
    required List<GlassNavItem> items,
    required int selectedIndex,
    bool visible = true,
  }) async {
    if (!isSupported) return;
    await _ensureHandler();
    final String payload = jsonEncode(<String, dynamic>{
      'items': items.map((GlassNavItem item) => item.toJson()).toList(),
      'selected': selectedIndex,
      'visible': visible,
    });
    if (payload == _lastPayload) return;
    _lastPayload = payload;
    try {
      await _channel.invokeMethod<void>('configure', payload);
    } on PlatformException catch (error) {
      debugPrint('GlassNavBar.configure failed: ${error.message}');
    }
  }

  /// 只更新选中项（切页时用，比整包 configure 便宜）。
  static Future<void> setSelected(int selectedIndex) async {
    if (!isSupported) return;
    await _ensureHandler();
    try {
      await _channel.invokeMethod<void>(
        'setSelected',
        jsonEncode(<String, dynamic>{'selected': selectedIndex}),
      );
    } on PlatformException catch (error) {
      debugPrint('GlassNavBar.setSelected failed: ${error.message}');
    }
  }

  /// 显隐。离开首页（例如进入直播间）时必须收起，否则会压在播放页上。
  static Future<void> setVisible(bool visible) async {
    if (!isSupported) return;
    await _ensureHandler();
    try {
      await _channel.invokeMethod<void>(
        'setVisible',
        jsonEncode(<String, dynamic>{'visible': visible}),
      );
    } on PlatformException catch (error) {
      debugPrint('GlassNavBar.setVisible failed: ${error.message}');
    }
  }
}
