import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('Timeout and error handling', () {
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('loadUrl should not throw for valid URL', () async {
      await expectLater(
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.com')),
        ),
        completes,
      );
    });

    test('loadUrl with empty URL should complete without crash', () async {
      await expectLater(
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('')),
        ),
        completes,
      );
    });

    test('loadData with empty string should complete without crash', () async {
      await expectLater(
        controller.loadData(data: ''),
        completes,
      );
    });

    test('evaluateJavascript with empty string should complete', () async {
      final result = await controller.evaluateJavascript(source: '');
      expect(result, isNotNull);
    });

    test('loadFile with empty path should complete without crash', () async {
      await expectLater(
        controller.loadFile(assetFilePath: ''),
        completes,
      );
    });

    test('scrollTo with negative values should complete without crash',
        () async {
      await expectLater(
        controller.scrollTo(x: -1, y: -1),
        completes,
      );
    });

    test('zoomBy with zero factor should complete without crash', () async {
      await expectLater(
        controller.zoomBy(zoomFactor: 0),
        completes,
      );
    });

    test('zoomBy with extreme factor should complete without crash', () async {
      await expectLater(
        controller.zoomBy(zoomFactor: 100),
        completes,
      );
    });

    test(
        'goBackOrForward with large step should complete without crash',
        () async {
      await expectLater(
        controller.goBackOrForward(steps: 999999),
        completes,
      );
    });
  });

  group('Boundary and edge case tests', () {
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('loadData with very long HTML string should complete', () async {
      final longHtml = '<html>' + 'x' * 10000 + '</html>';
      await expectLater(
        controller.loadData(data: longHtml),
        completes,
      );
    });

    test('evaluateJavascript with very long script should complete', () async {
      final longScript = 'var x = "${"a" * 5000}";';
      final result = await controller.evaluateJavascript(source: longScript);
      expect(result, isNotNull);
    });

    test('postUrl with empty postData should complete', () async {
      await expectLater(
        controller.postUrl(
          url: WebUri('https://example.com/post'),
          postData: Uint8List(0),
        ),
        completes,
      );
    });

    test('postUrl with large postData should complete', () async {
      await expectLater(
        controller.postUrl(
          url: WebUri('https://example.com/post'),
          postData: Uint8List(10000),
        ),
        completes,
      );
    });

    test('loadUrl with URL containing special characters should complete',
        () async {
      await expectLater(
        controller.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://example.com/path?q=hello%20world&lang=zh'),
          ),
        ),
        completes,
      );
    });

    test('loadUrl with data URI scheme should complete', () async {
      await expectLater(
        controller.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('data:text/html,<h1>Hello</h1>'),
          ),
        ),
        completes,
      );
    });

    test('setSettings with empty settings should complete', () async {
      await expectLater(
        controller.setSettings(settings: InAppWebViewSettings()),
        completes,
      );
    });

    test('clearFocus should not throw when called multiple times', () async {
      await controller.clearFocus();
      await controller.clearFocus();
      await controller.clearFocus();
    });

    test('pauseTimers and resumeTimers sequence', () async {
      await controller.pauseTimers();
      await controller.resumeTimers();
      await controller.pauseTimers();
      await controller.pauseTimers();
      await controller.resumeTimers();
    });
  });

  group('Concurrent operations', () {
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('concurrent loadUrl calls should complete without error', () async {
      final results = await Future.wait([
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.com')),
        ),
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.org')),
        ),
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.net')),
        ),
      ]);
      expect(results.length, 3);
    });

    test('concurrent navigation and page info calls should not conflict',
        () async {
      final results = await Future.wait([
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.com')),
        ),
        controller.getUrl(),
        controller.getTitle(),
        controller.getProgress(),
        controller.getHtml(),
      ]);
      expect(results.length, 5);
    });

    test('concurrent evaluateJavascript calls should complete', () async {
      final results = await Future.wait([
        controller.evaluateJavascript(source: '1+1'),
        controller.evaluateJavascript(source: '2+2'),
        controller.evaluateJavascript(source: '3+3'),
        controller.evaluateJavascript(source: '4+4'),
        controller.evaluateJavascript(source: '5+5'),
      ]);
      expect(results.length, 5);
    });

    test('concurrent mixed operations should complete without error', () async {
      await Future.wait([
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.com')),
        ),
        controller.evaluateJavascript(source: 'console.log("test")'),
        controller.getSettings(),
        controller.getZoomScale(),
        controller.isLoading(),
        controller.canGoBack(),
        controller.canGoForward(),
        controller.getScrollX(),
        controller.getScrollY(),
        controller.getContentHeight(),
      ]);
    });

    test('concurrent controller operations with multiple instances', () async {
      final fake2 = FakePlatformInAppWebViewController(id: 'instance-2');
      final controller2 =
          InAppWebViewController.fromPlatform(platform: fake2);

      final futures = <Future>[];
      futures.add(controller.getUrl());
      futures.add(controller.getTitle());
      futures.add(controller2.getUrl());
      futures.add(controller2.getTitle());
      futures.add(controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://a.com')),
      ));
      futures.add(controller2.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://b.com')),
      ));

      await Future.wait(futures);
      controller2.dispose();
    });

    test('concurrent addJavaScriptHandler and evaluateJavascript', () async {
      controller.addJavaScriptHandler(
        handlerName: 'concurrentHandler',
        callback: (args) => 'ok',
      );
      expect(controller.hasJavaScriptHandler(handlerName: 'concurrentHandler'),
          isTrue);

      final results = await Future.wait([
        controller.evaluateJavascript(source: 'window.concurrentHandler()'),
        controller.evaluateJavascript(source: 'window.concurrentHandler()'),
        controller.evaluateJavascript(source: 'window.concurrentHandler()'),
      ]);
      expect(results.length, 3);

      controller.removeJavaScriptHandler(handlerName: 'concurrentHandler');
    });

    test('rapid add/remove userScripts should not lose state', () async {
      final script1 = UserScript(
        source: 'console.log("1")',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      );
      final script2 = UserScript(
        source: 'console.log("2")',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
      );

      await Future.wait([
        controller.addUserScript(userScript: script1),
        controller.addUserScript(userScript: script2),
      ]);

      expect(controller.hasUserScript(userScript: script1), isTrue);
      expect(controller.hasUserScript(userScript: script2), isTrue);

      await Future.wait([
        controller.removeUserScript(userScript: script1),
        controller.removeUserScript(userScript: script2),
      ]);

      expect(controller.hasUserScript(userScript: script1), isFalse);
      expect(controller.hasUserScript(userScript: script2), isFalse);
    });
  });

  group('Parameter validation and null handling', () {
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('addJavaScriptHandler with empty name should work', () {
      controller.addJavaScriptHandler(
        handlerName: '',
        callback: (args) => 'ok',
      );
      expect(controller.hasJavaScriptHandler(handlerName: ''), isTrue);
      controller.removeJavaScriptHandler(handlerName: '');
      expect(controller.hasJavaScriptHandler(handlerName: ''), isFalse);
    });

    test(
        'addJavaScriptHandler with special characters in name should work',
        () {
      const specialName = r'handler$pecial@chars!';
      controller.addJavaScriptHandler(
        handlerName: specialName,
        callback: (args) => 'ok',
      );
      expect(
          controller.hasJavaScriptHandler(handlerName: specialName), isTrue);
      controller.removeJavaScriptHandler(handlerName: specialName);
      expect(
          controller.hasJavaScriptHandler(handlerName: specialName), isFalse);
    });

    test('removeJavaScriptHandler for non-existent handler should return null',
        () {
      final removed =
          controller.removeJavaScriptHandler(handlerName: 'nonexistent');
      expect(removed, isNull);
    });

    test('hasJavaScriptHandler for non-existent handler should return false',
        () {
      expect(
        controller.hasJavaScriptHandler(handlerName: 'nonexistent'),
        isFalse,
      );
    });

    test('addUserScript with empty source should work', () async {
      final script = UserScript(
        source: '',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      );
      await controller.addUserScript(userScript: script);
      expect(controller.hasUserScript(userScript: script), isTrue);
      await controller.removeUserScript(userScript: script);
    });

    test('canGoBackOrForward with zero steps should complete', () async {
      final result = await controller.canGoBackOrForward(steps: 0);
      expect(result, isA<bool>());
    });

    test('scrollBy with zero values should complete', () async {
      await expectLater(
        controller.scrollBy(x: 0, y: 0),
        completes,
      );
    });

    test('setContextMenu with null should complete', () async {
      await expectLater(
        controller.setContextMenu(null),
        completes,
      );
    });

    test('getFavicons should return a list', () async {
      final favicons = await controller.getFavicons();
      expect(favicons, isA<List<Favicon>>());
    });

    test('getMetaTags should return a list', () async {
      final tags = await controller.getMetaTags();
      expect(tags, isA<List<MetaTag>>());
    });

    test('getCopyBackForwardList should return a valid WebHistory', () async {
      final history = await controller.getCopyBackForwardList();
      expect(history?.currentIndex, isNotNull);
      expect(history?.list, isNotEmpty);
    });

    test('dispose should be safe to call', () {
      expect(fake.disposed, isFalse);
      fake.dispose();
      expect(fake.disposed, isTrue);
    });
  });

  group('WebStorage edge cases', () {
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('localStorage getItem for non-existent key should return null',
        () async {
      final value = await controller.webStorage.localStorage
          .getItem(key: 'nonexistent');
      expect(value, isNull);
    });

    test('localStorage setItem with empty key should work', () async {
      await controller.webStorage.localStorage.setItem(key: '', value: 'val');
      final value =
          await controller.webStorage.localStorage.getItem(key: '');
      expect(value, 'val');
    });

    test('localStorage setItem with empty value should work', () async {
      await controller.webStorage.localStorage.setItem(
        key: 'emptyVal',
        value: '',
      );
      final value = await controller.webStorage.localStorage
          .getItem(key: 'emptyVal');
      expect(value, '');
    });

    test('localStorage removeItem for non-existent key should not throw',
        () async {
      await expectLater(
        controller.webStorage.localStorage.removeItem(key: 'nonexistent'),
        completes,
      );
    });

    test('localStorage clear on empty storage should not throw', () async {
      await expectLater(
        controller.webStorage.localStorage.clear(),
        completes,
      );
    });

    test('sessionStorage same operations as localStorage', () async {
      await controller.webStorage.sessionStorage
          .setItem(key: 'sessionKey', value: 'sessionVal');
      final value = await controller.webStorage.sessionStorage
          .getItem(key: 'sessionKey');
      expect(value, 'sessionVal');

      final length = await controller.webStorage.sessionStorage.length();
      expect(length, greaterThanOrEqualTo(1));
    });
  });

  group('Timeout simulation', () {
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('loadUrl with timeout wrapper should complete normally', () async {
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
      ).timeout(const Duration(seconds: 5));
    });

    test('getUrl with timeout should complete', () async {
      final url = await controller.getUrl()
          .timeout(const Duration(seconds: 5));
      expect(url, isNotNull);
    });

    test('evaluateJavascript with timeout should complete', () async {
      final result = await controller.evaluateJavascript(source: '1+1')
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });

    test('multiple operations with timeout should all complete', () async {
      final futures = [
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.com')),
        ).timeout(const Duration(seconds: 5)),
        controller.getTitle().timeout(const Duration(seconds: 5)),
        controller.getProgress().timeout(const Duration(seconds: 5)),
        controller.evaluateJavascript(source: '1')
            .timeout(const Duration(seconds: 5)),
      ];
      await Future.wait(futures);
    });

    test(
        'timeout of zero duration on fast operation should not throw',
        () async {
      await controller.getProgress().timeout(Duration.zero);
    });

    test('takeScreenshot with timeout should complete', () async {
      final result = await controller.takeScreenshot()
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });
  });

  group('CookieManager edge cases', () {
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

    test('setCookie with empty name should complete', () async {
      await expectLater(
        manager.setCookie(
          url: WebUri('https://example.com'),
          name: '',
          value: 'test',
        ),
        completes,
      );
    });

    test('setCookie with empty value should complete', () async {
      await expectLater(
        manager.setCookie(
          url: WebUri('https://example.com'),
          name: 'emptyVal',
          value: '',
        ),
        completes,
      );
    });

    test('setCookie with special characters in value should complete',
        () async {
      await expectLater(
        manager.setCookie(
          url: WebUri('https://example.com'),
          name: 'special',
          value: 'val=ue; domain=test',
        ),
        completes,
      );
    });

    test('getCookie for non-existent cookie should not crash', () async {
      final cookie = await manager.getCookie(
        url: WebUri('https://example.com'),
        name: 'nonexistent',
      );
      expect(cookie, isNull);
    });

    test('deleteCookie for non-existent cookie should not throw', () async {
      final result = await manager.deleteCookie(
        url: WebUri('https://example.com'),
        name: 'nonexistent',
      );
      expect(result, isNotNull);
    });

    test('getCookies with empty store should return empty list', () async {
      final cookies = await manager.getCookies(
        url: WebUri('https://example.com'),
      );
      expect(cookies, isEmpty);
    });

    test('concurrent setCookie calls should complete', () async {
      await Future.wait([
        manager.setCookie(
          url: WebUri('https://example.com'),
          name: 'c1',
          value: 'v1',
        ),
        manager.setCookie(
          url: WebUri('https://example.com'),
          name: 'c2',
          value: 'v2',
        ),
        manager.setCookie(
          url: WebUri('https://example.com'),
          name: 'c3',
          value: 'v3',
        ),
      ]);
    });
  });

  group('FindInteractionController edge cases', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('findAll with empty string should complete', () async {
      final controller = FindInteractionController();
      await expectLater(
        controller.findAll(find: ''),
        completes,
      );
      controller.dispose();
    });

    test('findNext without active search should complete', () async {
      final controller = FindInteractionController();
      await expectLater(
        controller.findNext(forward: true),
        completes,
      );
      controller.dispose();
    });

    test('clearMatches without active search should complete', () async {
      final controller = FindInteractionController();
      await expectLater(
        controller.clearMatches(),
        completes,
      );
      controller.dispose();
    });

    test('setSearchText with null should complete', () async {
      final controller = FindInteractionController();
      await expectLater(
        controller.setSearchText(null),
        completes,
      );
      expect(await controller.getSearchText(), isNull);
      controller.dispose();
    });

    test('setSearchText with empty string should complete', () async {
      final controller = FindInteractionController();
      await controller.setSearchText('');
      expect(await controller.getSearchText(), '');
      controller.dispose();
    });
  });

  group('PullToRefreshController edge cases', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('endRefreshing when not refreshing should complete', () async {
      final controller = PullToRefreshController(
        onRefresh: () {},
      );
      expect(await controller.isRefreshing(), isFalse);
      await expectLater(
        controller.endRefreshing(),
        completes,
      );
      controller.dispose();
    });

    test('beginRefreshing when already refreshing should complete', () async {
      final controller = PullToRefreshController(
        onRefresh: () {},
      );
      await controller.beginRefreshing();
      expect(await controller.isRefreshing(), isTrue);
      await controller.beginRefreshing();
      expect(await controller.isRefreshing(), isTrue);
      await controller.endRefreshing();
      controller.dispose();
    });

    test('setEnabled with same value should complete', () async {
      final controller = PullToRefreshController(
        onRefresh: () {},
      );
      await controller.setEnabled(true);
      await controller.setEnabled(true);
      expect(await controller.isEnabled(), isTrue);
      await controller.setEnabled(false);
      await controller.setEnabled(false);
      expect(await controller.isEnabled(), isFalse);
      controller.dispose();
    });
  });

  group('PrintJobController edge cases', () {
    test('cancel twice should not throw', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.cancel();
      await controller.cancel();
      expect(fake.cancelCalled, isTrue);
    });

    test('dismiss twice should not throw', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.dismiss();
      await controller.dismiss();
      expect(fake.dismissCalled, isTrue);
    });

    test('restart twice should not throw', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.restart();
      await controller.restart();
      expect(fake.restartCalled, isTrue);
    });

    test('cancel then restart then dismiss sequence', () async {
      final fake = FakePlatformPrintJobController();
      final controller = PrintJobController.fromPlatform(platform: fake);
      await controller.cancel();
      await controller.restart();
      await controller.dismiss();
      controller.dispose();
      expect(fake.disposed, isTrue);
    });
  });

  group('InAppBrowser edge cases', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('close when not opened should complete', () async {
      final browser = InAppBrowser();
      await expectLater(
        browser.close(),
        completes,
      );
    });

    test('hide when not opened should complete', () async {
      final browser = InAppBrowser();
      await expectLater(
        browser.hide(),
        completes,
      );
    });

    test('show when hidden should work', () async {
      final browser = InAppBrowser();
      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
      );
      await browser.hide();
      expect(await browser.isHidden(), isTrue);
      await browser.show();
      expect(await browser.isHidden(), isFalse);
    });

    test('addMenuItem with empty items should complete', () {
      final browser = InAppBrowser();
      browser.addMenuItems([]);
      browser.removeAllMenuItem();
    });
  });

  group('TracingController edge cases', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('stop when not tracing should complete', () async {
      final fake = FakePlatformTracingController();
      final controller = TracingController.fromPlatform(fake);
      final result = await controller.stop();
      expect(result, isNotNull);
    });

    test('start when already tracing should work', () async {
      final fake = FakePlatformTracingController();
      final controller = TracingController.fromPlatform(fake);
      await controller.start(
          settings: TracingSettings(categories: ['blink']));
      expect(await controller.isTracing(), isTrue);
      await controller.start(
          settings: TracingSettings(categories: ['blink']));
      expect(await controller.isTracing(), isTrue);
      await controller.stop();
    });
  });

  group('WebStorageManager edge cases', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('deleteOrigin for non-existent origin should complete', () async {
      final manager = WebStorageManager.instance();
      await expectLater(
        manager.deleteOrigin(origin: 'https://nonexistent.com'),
        completes,
      );
    });

    test('getQuotaForOrigin for non-existent origin should return value',
        () async {
      final manager = WebStorageManager.instance();
      final quota =
          await manager.getQuotaForOrigin(origin: 'https://nonexistent.com');
      expect(quota, greaterThanOrEqualTo(0));
    });

    test('getUsageForOrigin for non-existent origin should return value',
        () async {
      final manager = WebStorageManager.instance();
      final usage =
          await manager.getUsageForOrigin(origin: 'https://nonexistent.com');
      expect(usage, greaterThanOrEqualTo(0));
    });

    test('fetchDataRecords with single type should return records', () async {
      final manager = WebStorageManager.instance();
      final records = await manager.fetchDataRecords(
        dataTypes: {WebsiteDataType.WKWebsiteDataTypeLocalStorage},
      );
      expect(records, isNotEmpty);
    });

    test('deleteAllData twice should complete', () async {
      final manager = WebStorageManager.instance();
      await manager.deleteAllData();
      await manager.deleteAllData();
    });
  });

  group('ChromeSafariBrowser edge cases', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('close when not opened should complete', () async {
      final browser = ChromeSafariBrowser();
      await expectLater(
        browser.close(),
        completes,
      );
    });

    test('dispose should be safe to call multiple times', () {
      final browser = ChromeSafariBrowser();
      browser.dispose();
      browser.dispose();
    });

    test('mayLaunchUrl without opening should work', () async {
      final browser = ChromeSafariBrowser();
      final result = await browser.mayLaunchUrl(
        url: WebUri('https://example.com'),
      );
      expect(result, isNotNull);
    });
  });
}
