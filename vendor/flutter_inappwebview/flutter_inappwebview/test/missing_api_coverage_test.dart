import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('WebViewEnvironment', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('create should return environment from platform', () async {
      final env = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(),
      );
      expect(env.id, 'created-env');
      expect(env.settings, isNull);
    });

    test('getAvailableVersion should delegate to platform', () async {
      expect(await WebViewEnvironment.getAvailableVersion(), '1.0.0.0');
      expect(
        await WebViewEnvironment.getAvailableVersion(
          browserExecutableFolder: r'C:\Edge',
        ),
        '1.0.0.0',
      );
    });

    test('compareBrowserVersions should delegate to platform', () async {
      expect(
        await WebViewEnvironment.compareBrowserVersions(
          version1: '1.0.0.0',
          version2: '2.0.0.0',
        ),
        lessThan(0),
      );
    });

    test('dispose should delegate to platform', () async {
      final fake = FakePlatformWebViewEnvironment(environmentId: 'env-dispose');
      final env = WebViewEnvironment.fromPlatform(platform: fake);
      expect(env.id, 'env-dispose');
      await env.dispose();
      expect(fake.disposed, isTrue);
    });

    test('fromPlatformCreationParams should create environment', () {
      final env = WebViewEnvironment.fromPlatformCreationParams(
        params: const PlatformWebViewEnvironmentCreationParams(),
      );
      expect(env.platform, isA<FakePlatformWebViewEnvironment>());
    });
  });

  group('ServiceWorkerController', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('serviceWorkerClient setters should expose client', () async {
      final fake = FakePlatformServiceWorkerController();
      final controller = ServiceWorkerController.fromPlatform(fake);
      final client =
          ServiceWorkerClient(shouldInterceptRequest: (_) async => null);
      await controller.setServiceWorkerClient(client);
      expect(controller.serviceWorkerClient, same(client));
    });

    test('static accessors should delegate to platform', () async {
      final platform =
          InAppWebViewPlatform.instance as FakeInAppWebViewPlatform;
      final fake = platform.sharedServiceWorkerController;
      fake.allowContentAccess = true;
      fake.allowFileAccess = true;
      fake.blockNetworkLoads = false;
      fake.cacheMode = CacheMode.LOAD_DEFAULT;

      expect(await ServiceWorkerController.getAllowContentAccess(), isTrue);
      expect(await ServiceWorkerController.getAllowFileAccess(), isTrue);
      expect(await ServiceWorkerController.getBlockNetworkLoads(), isFalse);
      expect(
        await ServiceWorkerController.getCacheMode(),
        CacheMode.LOAD_DEFAULT,
      );

      await ServiceWorkerController.setAllowContentAccess(false);
      await ServiceWorkerController.setAllowFileAccess(false);
      await ServiceWorkerController.setBlockNetworkLoads(true);
      await ServiceWorkerController.setCacheMode(CacheMode.LOAD_NO_CACHE);

      expect(fake.allowContentAccess, isFalse);
      expect(fake.allowFileAccess, isFalse);
      expect(fake.blockNetworkLoads, isTrue);
      expect(fake.cacheMode, CacheMode.LOAD_NO_CACHE);
    });

    test('fromPlatformCreationParams and fromPlatform should create controller',
        () {
      final fromParams = ServiceWorkerController.fromPlatformCreationParams(
        const PlatformServiceWorkerControllerCreationParams(),
      );
      expect(fromParams.platform, isA<FakePlatformServiceWorkerController>());

      final fromPlatform = ServiceWorkerController.fromPlatform(
        FakePlatformServiceWorkerController(),
      );
      expect(fromPlatform.platform, isA<FakePlatformServiceWorkerController>());
    });
  });

  group('ProcessGlobalConfig', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('apply should delegate to platform', () async {
      final fake = FakePlatformProcessGlobalConfig();
      final config = ProcessGlobalConfig.fromPlatform(fake);
      final settings = ProcessGlobalConfigSettings(
        dataDirectorySuffix: 'test-suffix',
      );
      await config.apply(settings: settings);
      expect(fake.applyCalled, isTrue);
      expect(fake.lastSettings?.dataDirectorySuffix, 'test-suffix');
    });

    test('instance should return shared ProcessGlobalConfig', () {
      final first = ProcessGlobalConfig.instance();
      final second = ProcessGlobalConfig.instance();
      expect(identical(first, second), isTrue);
      expect(first.platform, isA<FakePlatformProcessGlobalConfig>());
    });

    test('fromPlatformCreationParams and fromPlatform should create config', () {
      final fromParams = ProcessGlobalConfig.fromPlatformCreationParams(
        const PlatformProcessGlobalConfigCreationParams(),
      );
      expect(fromParams.platform, isA<FakePlatformProcessGlobalConfig>());

      final fake = FakePlatformProcessGlobalConfig();
      final fromPlatform = ProcessGlobalConfig.fromPlatform(fake);
      expect(fromPlatform.platform, same(fake));
    });
  });

  group('ContextMenu', () {
    test('constructor should expose menuItems settings and callbacks', () {
      var created = false;
      var hidden = false;
      var clicked = false;
      final item = ContextMenuItem(id: 1, title: 'Copy');
      final menu = ContextMenu(
        menuItems: [item],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
        onCreateContextMenu: (_) => created = true,
        onHideContextMenu: () => hidden = true,
        onContextMenuActionItemClicked: (_) => clicked = true,
      );

      expect(menu.menuItems.length, 1);
      expect(menu.settings?.hideDefaultSystemContextMenuItems, isTrue);
      menu.onCreateContextMenu?.call(
        InAppWebViewHitTestResult(
          type: InAppWebViewHitTestResultType.UNKNOWN_TYPE,
        ),
      );
      menu.onHideContextMenu?.call();
      menu.onContextMenuActionItemClicked?.call(item);
      expect(created && hidden && clicked, isTrue);
    });

    test('toMap and toString should serialize context menu', () {
      final menu = ContextMenu(
        menuItems: [ContextMenuItem(id: 7, title: 'Paste')],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      );
      final map = menu.toMap();
      expect(map['menuItems'], isNotEmpty);
      expect(map['settings']?['hideDefaultSystemContextMenuItems'], isTrue);
      expect(menu.toJson()['menuItems'], isNotEmpty);
      expect(menu.toString(), contains('ContextMenu'));
      expect(ContextMenu.fromMap(null), isNull);
    });
  });

  group('ContextMenuItem', () {
    test('constructor should expose id title and action', () {
      var acted = false;
      final item = ContextMenuItem(
        id: 42,
        title: 'Share',
        action: () => acted = true,
      );
      expect(item.id, 42);
      expect(item.title, 'Share');
      item.action?.call();
      expect(acted, isTrue);
    });

    test('toMap toJson and toString should serialize item', () {
      final item = ContextMenuItem(id: 9, title: 'Open');
      final map = item.toMap();
      expect(map['id'], 9);
      expect(map['title'], 'Open');
      expect(item.toJson()['title'], 'Open');
      expect(item.toString(), contains('Open'));
      expect(ContextMenuItem.fromMap(null), isNull);
    });
  });

  group('ContextMenuSettings', () {
    test('toMap fromMap copy and toString should work', () {
      final settings = ContextMenuSettings(
        hideDefaultSystemContextMenuItems: true,
      );
      expect(settings.hideDefaultSystemContextMenuItems, isTrue);
      expect(settings.toMap()['hideDefaultSystemContextMenuItems'], isTrue);
      expect(settings.toJson()['hideDefaultSystemContextMenuItems'], isTrue);

      final restored = ContextMenuSettings.fromMap({
        'hideDefaultSystemContextMenuItems': false,
      });
      expect(restored?.hideDefaultSystemContextMenuItems, isFalse);
      expect(settings.copy().hideDefaultSystemContextMenuItems, isTrue);
      expect(settings.toString(), contains('hideDefaultSystemContextMenuItems'));
    });
  });
}
