import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('PrintJobController', () {
    test('should expose id and onComplete', () {
      var completed = false;
      final fake = FakePlatformPrintJobController(
        id: 'print-42',
        onComplete: (success, error) async {
          completed = true;
        },
      );
      final controller = PrintJobController.fromPlatform(platform: fake);

      expect(controller.id, 'print-42');
      expect(controller.onComplete, isNotNull);
      controller.onComplete = (success, error) async {
        completed = true;
      };
      expect(controller.onComplete, isNotNull);
    });

    test('cancel should delegate to platform', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.cancel();
      expect(fake.cancelCalled, isTrue);
    });

    test('restart should delegate to platform', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.restart();
      expect(fake.restartCalled, isTrue);
    });

    test('dismiss should delegate to platform', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.dismiss();
      expect(fake.dismissCalled, isTrue);
    });

    test('getInfo should return print job info', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      final info = await controller.getInfo();
      expect(info, isNotNull);
      expect(info!.state, PrintJobState.COMPLETED);
    });

    test('dispose should delegate to platform', () {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      controller.dispose();
      expect(fake.disposed, isTrue);
    });

    test('fromPlatformCreationParams should create controller', () {
      final previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      try {
        final controller = PrintJobController.fromPlatformCreationParams(
          params: PlatformPrintJobControllerCreationParams(id: 'job-99'),
        );
        expect(controller.id, 'job-99');
        expect(controller.platform, isA<FakePlatformPrintJobController>());
      } finally {
        restoreInAppWebViewPlatform(previousPlatform);
      }
    });
  });

  group('CookieManager', () {
    late FakePlatformCookieManager fake;
    late CookieManager manager;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformCookieManager();
      manager = CookieManager.fromPlatform(fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('instance should return singleton', () {
      expect(identical(CookieManager.instance(), CookieManager.instance()),
          isTrue);
    });

    test('fromPlatformCreationParams should create manager', () {
      final manager = CookieManager.fromPlatformCreationParams(
        const PlatformCookieManagerCreationParams(),
      );
      expect(manager.platform, isA<FakePlatformCookieManager>());
    });

    test('getAllCookies should return all cookies', () async {
      fake.allCookies.add(Cookie(name: 'a', value: '1'));
      final cookies = await manager.getAllCookies();
      expect(cookies.length, 1);
      expect(cookies.first.name, 'a');
    });

    test('deleteCookie should delete cookie by name', () async {
      final result = await manager.deleteCookie(
        url: WebUri('https://example.com'),
        name: 'test',
      );
      expect(result, isTrue);
    });

    test('getCookies deleteCookies deleteAllCookies removeSessionCookies should delegate',
        () async {
      fake.allCookies.add(Cookie(name: 'a', value: '1'));
      final cookies = await manager.getCookies(
        url: WebUri('https://example.com'),
      );
      expect(cookies.length, 1);
      expect(await manager.deleteCookies(url: WebUri('https://example.com')),
          isTrue);
      expect(await manager.deleteAllCookies(), isTrue);
      expect(await manager.removeSessionCookies(), isTrue);
    });

    test('setCookie and getCookie should work', () async {
      await manager.setCookie(
        url: WebUri('https://example.com'),
        name: 'session',
        value: 'abc',
      );
      fake.allCookies.add(Cookie(name: 'session', value: 'abc'));
      final cookie = await manager.getCookie(
        url: WebUri('https://example.com'),
        name: 'session',
      );
      expect(cookie?.value, 'abc');
    });
  });

  group('ProxyController', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('instance should return singleton', () {
      expect(identical(ProxyController.instance(), ProxyController.instance()),
          isTrue);
    });

    test('fromPlatformCreationParams should create controller', () {
      final controller = ProxyController.fromPlatformCreationParams(
        const PlatformProxyControllerCreationParams(),
      );
      expect(controller.platform, isA<FakePlatformProxyController>());
    });

    test('clearProxyOverride should delegate to platform', () async {
      final fake = FakePlatformProxyController();
      final controller = ProxyController.fromPlatform(fake);
      await controller.clearProxyOverride();
      expect(fake.clearCalled, isTrue);
    });

    test('setProxyOverride should delegate to platform', () async {
      final fake = FakePlatformProxyController();
      final controller = ProxyController.fromPlatform(fake);
      await controller.setProxyOverride(
        settings: ProxySettings(bypassRules: ['localhost']),
      );
      expect(fake.setProxyCalled, isTrue);
    });
  });

  group('TracingController', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should create controller through platform factory', () {
      final controller = TracingController();
      expect(controller.platform, isA<FakePlatformTracingController>());
    });

    test('fromPlatformCreationParams should create controller', () {
      final controller = TracingController.fromPlatformCreationParams(
        const PlatformTracingControllerCreationParams(),
      );
      expect(controller.platform, isA<FakePlatformTracingController>());
    });

    test('isTracing should reflect platform state', () async {
      final fake = FakePlatformTracingController();
      final controller = TracingController.fromPlatform(fake);
      expect(await controller.isTracing(), isFalse);
      await controller.start(
          settings: TracingSettings(categories: ['blink']));
      expect(await controller.isTracing(), isTrue);
      expect(await controller.stop(), isTrue);
    });
  });
}
