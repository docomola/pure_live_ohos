import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:media_core/media_core.dart';
import 'package:media_core_fullscreen/media_core_fullscreen.dart';
import 'package:pure_live/core/index.dart';
import 'package:pure_live/core/platform/platform_utils.dart' as pure_platform;
import 'package:pure_live/core/player/kernel/player_kernel_service.dart';

@visibleForTesting
bool supportsOrientationLockForLogicalDisplay(Size logicalDisplaySize) {
  return logicalDisplaySize.shortestSide < 600;
}

@visibleForTesting
Future<void> enterDesktopFullscreen({
  required bool isWindows,
  required Future<void> Function() prepareWindowsFullscreen,
  required Future<void> Function(bool fullscreen) setFullScreen,
}) async {
  // window_manager 0.5.2 marks a hidden-title-bar window as frameless while
  // initializing it on Windows. Its native SetFullScreen implementation skips
  // every style and bounds update while that flag is set, although it still
  // reports fullscreen=true. Reapplying the same title-bar style clears the
  // stale native guard before the actual transition.
  if (isWindows) {
    await prepareWindowsFullscreen();
  }
  await setFullScreen(true);
}

final class PureLiveFullscreenWindow implements FullscreenWindow {
  const PureLiveFullscreenWindow();

  @override
  Future<bool> get isFullscreen => windowManager.isFullScreen();

  @override
  Future<Rect> captureBounds() => windowManager.getBounds();

  @override
  Future<void> setFullscreen(bool value, {Rect? restoreBounds}) async {
    if (value) {
      await enterDesktopFullscreen(
        isWindows: Platform.isWindows,
        prepareWindowsFullscreen: () => windowManager.setTitleBarStyle(TitleBarStyle.hidden),
        setFullScreen: windowManager.setFullScreen,
      );
      return;
    }
    await windowManager.setFullScreen(false);
    if (restoreBounds != null) {
      await windowManager.setBounds(restoreBounds);
    }
  }
}

final FullscreenDriver fullscreenDriver = FullscreenDriver(
  // Restoring the pre-fullscreen bounds is load-bearing beyond fullscreen
  // itself: entering picture-in-picture releases fullscreen first, and the
  // PiP backend captures the window state at that moment. Without the
  // restore, that state is the screen-sized window, and both the PiP exit
  // and the next fullscreen exit bring the window back screen-sized.
  config: const FullscreenConfig(restorePreviousBounds: true),
  desktopWindow: const PureLiveFullscreenWindow(),
);

class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  bool _canApplyMobileOrientationLock() {
    // 鸿蒙不走 Android 那套"平板不锁方向"的尺寸豁免：Flutter-OH 的
    // Display.size 语义与官方 SDK 不一致（可能直接给物理像素），拿来判
    // 手机/平板会误杀手机全屏；而点全屏本身就是显式意图，直接放行。
    if (pure_platform.PlatformUtils.isOhos) return true;
    if (!Platform.isAndroid) return true;
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return true;
    final display = views.first.display;
    final logicalSize = Size(
      display.size.width / display.devicePixelRatio,
      display.size.height / display.devicePixelRatio,
    );
    return supportsOrientationLockForLogicalDisplay(logicalSize);
  }

  Future<void> landScape() async {
    dynamic document;
    try {
      if (kIsWeb) {
        await document.documentElement?.requestFullscreen();
      } else if (pure_platform.PlatformUtils.isMobile) {
        if (!_canApplyMobileOrientationLock()) return;
        if (pure_platform.PlatformUtils.isOhos) {
          // 鸿蒙的方向解码是位掩码（见 Flutter-OH PlatformChannel.decodeOrientations）：
          //   [landscapeLeft]              → 0x08 → window.Orientation.LANDSCAPE（强制横屏）
          //   [landscapeLeft, right]       → 0x0a → AUTO_ROTATION_LANDSCAPE（受系统"自动旋转"开关约束）
          // 全屏按钮必须无条件横屏，所以这里只传一个方向，拿强制 LANDSCAPE。
          await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
          return;
        }
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await doEnterFullScreen();
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> verticalScreen() async {
    if (!_canApplyMobileOrientationLock()) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> followSystemOrientation() async {
    if (!pure_platform.PlatformUtils.isMobile) return;
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]);
  }

  Future<void> doEnterFullScreen() async {
    if (kIsWeb) return;
    // One driver request serves both platform families: the driver performs
    // the desktop window transition (through PureLiveFullscreenWindow, with
    // its frameless guard) and the mobile immersive switch itself.
    await fullscreenDriver.initialize();
    await _applyPresentation(PresentationRequest.fullscreen());
  }

  Future<void> doExitFullScreen() async {
    try {
      if (!kIsWeb && pure_platform.PlatformUtils.isMobile) {
        // Host-owned policy on mobile: the status bar styling and the
        // orientation restore are this app's theming and orientation rules.
        // The system UI mode itself is restored by the driver below.
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
        );
        // 手机退全屏回竖屏:iOS 只解除限制(空数组 = 跟随系统)并不会主动把
        // 已经横着的界面转回来,设备会一直停在横屏。平板等大屏不锁方向
        // (verticalScreen 内部守卫直接跳过),保持自由旋转。
        await verticalScreen();
      }
      await fullscreenDriver.initialize();
      await _applyPresentation(PresentationRequest.normal());
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  /// Routes a mode request through the kernel presentation chain.
  ///
  /// The chain is the only owner of "the previous mode leaves first"
  /// (`PresentationDriverChain._active`). Driving [fullscreenDriver] directly —
  /// which is what the two transitions below used to do — left that bookkeeping
  /// empty, so the chain never released fullscreen when picture-in-picture was
  /// requested: the window stayed system-fullscreen while the small window
  /// applied its own size and picture fit on top of it (cropped picture, the
  /// fullscreen controls inside the small window), and leaving the small window
  /// restored fullscreen geometry. The comment on [fullscreenDriver]'s config
  /// has always described the intended release; this is what makes it happen.
  ///
  /// A host whose kernel is not attached yet still gets the direct call.
  Future<void> _applyPresentation(PresentationRequest request) async {
    final driver = PlayerKernelService.instance.kernel.presentationDriver;
    if (driver != null) {
      await driver.apply(PlayerId('pure-live'), request);
      return;
    }
    await fullscreenDriver.apply(PlayerId('pure-live'), request);
  }
}
