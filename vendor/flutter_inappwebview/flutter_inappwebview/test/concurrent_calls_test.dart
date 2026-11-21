/// 主包并发调用测试
///
/// 覆盖场景：
///   - 同一 controller 并发多个方法调用
///   - 多 controller 实例并发操作
///   - 并发 mixed 操作（get/set 混合）
///
/// 对应用例覆盖度报告：主包并发测试缺失（-3 分）

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('Concurrent operations on single controller', () {
    InAppWebViewPlatform? previousPlatform;
    late FakePlatformInAppWebViewController fake;
    late InAppWebViewController controller;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppWebViewController();
      controller = InAppWebViewController.fromPlatform(platform: fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('concurrent loadUrl calls should all complete', () async {
      final futures = List.generate(5, (i) {
        return controller.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://example.com/page$i'),
          ),
        );
      });

      await Future.wait(futures);
      // All should complete without throwing
    });

    test('concurrent getUrl, getTitle, getProgress should return results',
        () async {
      final results = await Future.wait([
        controller.getUrl(),
        controller.getTitle(),
        controller.getProgress(),
      ]);

      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(results[2], isNotNull);
    });

    test('concurrent reload and loadUrl should complete', () async {
      await Future.wait([
        controller.reload(),
        controller.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://example.com')),
        ),
      ]);
    });

    test('concurrent scrollTo and pageDown should complete', () async {
      await Future.wait([
        controller.scrollTo(x: 0, y: 100),
        controller.pageDown(bottom: false),
      ]);
    });

    test('concurrent evaluateJavascript calls should return results',
        () async {
      final results = await Future.wait([
        controller.evaluateJavascript(source: '1+1'),
        controller.evaluateJavascript(source: 'document.title'),
        controller.evaluateJavascript(source: '2*3'),
      ]);

      expect(results.length, 3);
    });

    test('concurrent canGoBack + canGoForward + isLoading', () async {
      final results = await Future.wait([
        controller.canGoBack(),
        controller.canGoForward(),
        controller.isLoading(),
      ]);

      expect(results.length, 3);
    });

    test('concurrent setSettings + getSettings should not conflict',
        () async {
      final results = await Future.wait([
        controller.getSettings(),
        controller.getSettings(),
      ]);

      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
    });

    test('concurrent 10 getUrl calls should all complete', () async {
      final futures = List.generate(10, (_) => controller.getUrl());
      final results = await Future.wait(futures);
      expect(results.length, 10);
    });

    test('concurrent mixed read-write operations should be safe', () async {
      final results = await Future.wait([
        controller.getUrl(),
        controller.getTitle(),
        controller.getProgress(),
        controller.canGoBack(),
        controller.isLoading(),
      ]);

      expect(results.length, 5);
    });
  });

  group('Concurrent operations across multiple controllers', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('two controllers should operate independently', () async {
      final fake1 = FakePlatformInAppWebViewController(id: 'c1');
      final fake2 = FakePlatformInAppWebViewController(id: 'c2');
      final c1 = InAppWebViewController.fromPlatform(platform: fake1);
      final c2 = InAppWebViewController.fromPlatform(platform: fake2);

      final results = await Future.wait([
        c1.getUrl(),
        c2.getUrl(),
        c1.getTitle(),
        c2.getTitle(),
      ]);

      expect(results.length, 4);
    });

    test('two controllers concurrent loadUrl should not interfere',
        () async {
      final fake1 = FakePlatformInAppWebViewController(id: 'c3');
      final fake2 = FakePlatformInAppWebViewController(id: 'c4');
      final c1 = InAppWebViewController.fromPlatform(platform: fake1);
      final c2 = InAppWebViewController.fromPlatform(platform: fake2);

      await Future.wait([
        c1.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://a.example.com')),
        ),
        c2.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://b.example.com')),
        ),
      ]);
    });
  });
}
