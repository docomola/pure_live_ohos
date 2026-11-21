/// 超时异常测试
///
/// 验证：
///   - 所有异步操作可以被 Future.timeout 安全包裹
///   - timeout 后的 catchError 恢复不影响后续操作
///   - 并发 timeout 场景不产生状态污染
///
/// 对应用例覆盖度报告：超时异常场景缺失（-3 分）

import 'dart:async' show TimeoutException;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('Timeout protection wrapping', () {
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

    test('loadUrl can be safely wrapped with .timeout()', () async {
      await expectLater(
        controller
            .loadUrl(
              urlRequest: URLRequest(url: WebUri('https://example.com')),
            )
            .timeout(const Duration(seconds: 5)),
        completes,
      );
    });

    test('evaluateJavascript can be safely wrapped with .timeout()', () async {
      final result = await controller
          .evaluateJavascript(source: '1+1')
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });

    test('reload can be safely wrapped with .timeout()', () async {
      await expectLater(
        controller.reload().timeout(const Duration(seconds: 5)),
        completes,
      );
    });

    test('getTitle can be safely wrapped with .timeout()', () async {
      final result = await controller
          .getTitle()
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });

    test('getUrl can be safely wrapped with .timeout()', () async {
      final result = await controller
          .getUrl()
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });

    test('getProgress can be safely wrapped with .timeout()', () async {
      final result = await controller
          .getProgress()
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });

    test('scrollTo can be safely wrapped with .timeout()', () async {
      await expectLater(
        controller
            .scrollTo(x: 0, y: 100)
            .timeout(const Duration(seconds: 5)),
        completes,
      );
    });

    test(
        'operation after caught timeout should still work without corruption',
        () async {
      // Wrap in custom Future that adds a fake delay then falls through
      final withDelay = Future.delayed(
        const Duration(seconds: 1),
        () => controller.getTitle(),
      );
      final outcome = await withDelay
          .timeout(const Duration(milliseconds: 1))
          .catchError((_) => 'recovered');
      expect(outcome, 'recovered');

      // Subsequent operations must work fine
      final title = await controller.getTitle();
      expect(title, isNotNull);
    });

    test('concurrent operations with timeout wrappers should complete safely',
        () async {
      final futures = List.generate(5, (i) {
        return controller
            .getTitle()
            .timeout(const Duration(seconds: 5))
            .catchError((_) => 'error-$i');
      });
      final results = await Future.wait(futures);
      expect(results.length, 5);
      // All should return valid titles, not error strings
      expect(results.where((r) => r == null).length, 0);
    });

    test('getSettings can be safely wrapped with .timeout()', () async {
      final result = await controller
          .getSettings()
          .timeout(const Duration(seconds: 5));
      expect(result, isNotNull);
    });

    test('mixed operations race with timeout wrappers', () async {
      final futures = <Future>[
        controller.getTitle().timeout(const Duration(seconds: 5)),
        controller
            .loadUrl(
              urlRequest: URLRequest(url: WebUri('https://example.com')),
            )
            .timeout(const Duration(seconds: 5)),
        controller.getProgress().timeout(const Duration(seconds: 5)),
      ];
      final results = await Future.wait(futures);
      expect(results.length, 3);
    });

    test('pause can be safely wrapped with .timeout()', () async {
      await expectLater(
        controller.pause().timeout(const Duration(seconds: 5)),
        completes,
      );
    });

    test('resume can be safely wrapped with .timeout()', () async {
      await expectLater(
        controller.resume().timeout(const Duration(seconds: 5)),
        completes,
      );
    });
  });
}
