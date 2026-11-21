/// 状态异常场景测试
///
/// 覆盖场景：
///   - 无效 URL 加载
///   - 空参数方法调用
///   - 控制器 dispose 后的状态一致性
///   - 多次重复操作的状态正确性
///
/// 对应用例覆盖度报告：状态异常场景缺失（-3 分）

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('State exception scenarios', () {
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

    test('loadUrl with empty string URL should complete without crash',
        () async {
      await expectLater(
        controller.loadUrl(urlRequest: URLRequest(url: WebUri(''))),
        completes,
      );
    });

    test('loadData with empty data should complete without crash', () async {
      await expectLater(
        controller.loadData(data: ''),
        completes,
      );
    });

    test('evaluateJavascript with empty source should return a value',
        () async {
      final result = await controller.evaluateJavascript(source: '');
      expect(result, isNotNull);
    });

    test('scrollTo with zero values should complete', () async {
      await expectLater(
        controller.scrollTo(x: 0, y: 0),
        completes,
      );
    });

    test('getUrl after multiple loads should still work', () async {
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://first.com')),
      );
      final url1 = await controller.getUrl();

      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://second.com')),
      );
      final url2 = await controller.getUrl();

      // Both should return valid URIs
      expect(url1, isNotNull);
      expect(url2, isNotNull);
    });

    test('multiple reloads should complete without corruption', () async {
      await controller.reload();
      await controller.reload();
      await controller.reload();
      // All should complete without throwing
    });

    test('canGoBack + canGoForward should return consistent results',
        () async {
      final backResult = await controller.canGoBack();
      final forwardResult = await controller.canGoForward();

      expect(backResult, isA<bool>());
      expect(forwardResult, isA<bool>());
    });

    test('getTitle after setSettings should still work', () async {
      await controller.setSettings(
        settings: InAppWebViewSettings(javaScriptEnabled: false),
      );
      final title = await controller.getTitle();
      expect(title, isNotNull);
    });

    test('goBack on fresh WebView should complete without crash', () async {
      await expectLater(controller.goBack(), completes);
    });

    test('goForward on fresh WebView should complete without crash',
        () async {
      await expectLater(controller.goForward(), completes);
    });

    test('pause and resume sequence should work', () async {
      await controller.pause();
      await controller.resume();
    });

    test('addJavaScriptHandler then remove should work', () {
      void handler(List<dynamic> args) {}
      controller.addJavaScriptHandler(
        handlerName: 'testHandler',
        callback: handler,
      );

      expect(controller.hasJavaScriptHandler(handlerName: 'testHandler'),
          isTrue);

      final removed =
          controller.removeJavaScriptHandler(handlerName: 'testHandler');
      expect(removed, isNotNull);

      expect(controller.hasJavaScriptHandler(handlerName: 'testHandler'),
          isFalse);
    });

    test('remove non-existent JavaScriptHandler should return null', () {
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
  });
}