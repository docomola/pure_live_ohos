import 'dart:ui';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('HeadlessInAppWebView', () {
    late FakeInAppWebViewPlatform fakePlatform;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      fakePlatform = installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should wire creation params callbacks', () async {
      InAppWebViewController? createdController;
      WebUri? loadStartUrl;
      WebUri? loadStopUrl;
      WebResourceError? receivedError;
      ConsoleMessage? consoleMessage;
      NavigationActionPolicy? overridePolicy;
      final initialData = InAppWebViewInitialData(data: '<html></html>');
      final headless = HeadlessInAppWebView(
        initialSize: const Size(320, 480),
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        initialFile: 'assets/index.html',
        initialData: initialData,
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
        onWebViewCreated: (controller) => createdController = controller,
        onLoadStart: (_, url) => loadStartUrl = url,
        onLoadStop: (_, url) => loadStopUrl = url,
        onReceivedError: (_, request, error) => receivedError = error,
        onConsoleMessage: (_, message) => consoleMessage = message,
        shouldOverrideUrlLoading: (_, action) async =>
            NavigationActionPolicy.CANCEL,
        onProgressChanged: (_, progress) {},
      );

      expect(headless.platform, isA<FakePlatformHeadlessInAppWebView>());
      expect(headless.id, isNotEmpty);
      expect(headless.isRunning(), isFalse);
      expect(headless.webViewController, isNull);

      await headless.run();

      expect(headless.isRunning(), isTrue);
      expect(headless.webViewController, isA<InAppWebViewController>());
      expect(createdController, isA<InAppWebViewController>());
      expect(fakePlatform.lastHeadless!.params.initialUrlRequest?.url?.rawValue,
          'https://example.com');
      expect(fakePlatform.lastHeadless!.params.initialFile, 'assets/index.html');
      expect(fakePlatform.lastHeadless!.params.initialData, initialData);
      expect(
        fakePlatform.lastHeadless!.params.initialSettings?.javaScriptEnabled,
        isTrue,
      );
      expect(fakePlatform.lastHeadless!.params.onProgressChanged, isNotNull);
      expect(fakePlatform.lastHeadless!.params.onLoadStart, isNotNull);

      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com/started');
      final error = WebResourceError(
        type: WebResourceErrorType.HOST_LOOKUP,
        description: 'failed',
      );

      fakePlatform.lastHeadless!.params.onLoadStart?.call(controller, url);
      fakePlatform.lastHeadless!.params.onLoadStop?.call(controller, url);
      fakePlatform.lastHeadless!.params.onReceivedError?.call(
        controller,
        WebResourceRequest(url: url),
        error,
      );
      fakePlatform.lastHeadless!.params.onConsoleMessage?.call(
        controller,
        ConsoleMessage(message: 'hello', messageLevel: ConsoleMessageLevel.LOG),
      );
      overridePolicy =
          await fakePlatform.lastHeadless!.params.shouldOverrideUrlLoading?.call(
        controller,
        NavigationAction(
          request: URLRequest(url: url),
          isForMainFrame: true,
        ),
      );

      expect(loadStartUrl?.rawValue, 'https://example.com/started');
      expect(loadStopUrl?.rawValue, 'https://example.com/started');
      expect(receivedError, error);
      expect(consoleMessage?.message, 'hello');
      expect(overridePolicy, NavigationActionPolicy.CANCEL);
    });

    test('run should be idempotent', () async {
      final headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
      );

      await headless.run();
      await headless.run();

      expect(headless.isRunning(), isTrue);
      expect(headless.webViewController, isA<InAppWebViewController>());
    });

    test('setSize and getSize should delegate to platform', () async {
      final headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
      );

      await headless.run();
      await headless.setSize(const Size(100, 200));
      final size = await headless.getSize();

      expect(size?.width, 100);
      expect(size?.height, 200);
    });

    test('dispose should stop headless webview', () async {
      final headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
      );

      await headless.run();
      await headless.dispose();

      expect(headless.isRunning(), isFalse);
      expect(headless.webViewController, isNull);
    });

    test('fromPlatform should expose wrapped controller', () {
      final fake = FakePlatformHeadlessInAppWebView(
        const PlatformHeadlessInAppWebViewCreationParams(),
      );
      final headless = HeadlessInAppWebView.fromPlatform(platform: fake);

      expect(headless.id, 'fake-headless-id');
    });

    test('fromPlatformCreationParams should wire onWebViewCreated callback', () async {
      InAppWebViewController? createdController;
      final headless = HeadlessInAppWebView.fromPlatformCreationParams(
        params: PlatformHeadlessInAppWebViewCreationParams(
          controllerFromPlatform: (controller) =>
              InAppWebViewController.fromPlatform(platform: controller),
          initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
          onWebViewCreated: (controller) => createdController = controller,
        ),
      );

      await headless.run();
      expect(createdController, isA<InAppWebViewController>());
    });

    test('fromPlatformCreationParams should wire callbacks', () {
      var progressChanged = false;
      final headless = HeadlessInAppWebView.fromPlatformCreationParams(
        params: PlatformHeadlessInAppWebViewCreationParams(
          initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
          onProgressChanged: (_, progress) => progressChanged = true,
        ),
      );

      expect(headless.id, isNotEmpty);
      fakePlatform.lastHeadless!.params.onProgressChanged?.call(
        InAppWebViewController.fromPlatform(
          platform: FakePlatformInAppWebViewController(),
        ),
        50,
      );
      expect(progressChanged, isTrue);
    });

    test('onJsAlert onJsConfirm onJsPrompt should be wired through params',
        () async {
      JsAlertResponse? alertResponse;
      JsConfirmResponse? confirmResponse;
      JsPromptResponse? promptResponse;
      final headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        onJsAlert: (_, request) async =>
            JsAlertResponse(handledByClient: true, action: JsAlertResponseAction.CONFIRM),
        onJsConfirm: (_, request) async =>
            JsConfirmResponse(handledByClient: true, action: JsConfirmResponseAction.CONFIRM),
        onJsPrompt: (_, request) async => JsPromptResponse(
          handledByClient: true,
          action: JsPromptResponseAction.CONFIRM,
          value: 'answer',
        ),
      );

      await headless.run();

      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com');
      alertResponse = await fakePlatform.lastHeadless!.params.onJsAlert?.call(
        controller,
        JsAlertRequest(message: 'alert', url: url),
      );
      confirmResponse = await fakePlatform.lastHeadless!.params.onJsConfirm?.call(
        controller,
        JsConfirmRequest(message: 'confirm', url: url),
      );
      promptResponse = await fakePlatform.lastHeadless!.params.onJsPrompt?.call(
        controller,
        JsPromptRequest(message: 'prompt', defaultValue: 'x', url: url),
      );

      expect(alertResponse?.handledByClient, isTrue);
      expect(confirmResponse?.action, JsConfirmResponseAction.CONFIRM);
      expect(promptResponse?.value, 'answer');
    });

    test('onPermissionRequest should be wired through params', () async {
      PermissionResponse? permissionResponse;
      final headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        onPermissionRequest: (_, request) async => PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        ),
      );

      await headless.run();

      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com');
      permissionResponse = await fakePlatform.lastHeadless!.params
          .onPermissionRequest?.call(
        controller,
        PermissionRequest(
          origin: url,
          resources: [PermissionResourceType.CAMERA],
        ),
      );

      expect(permissionResponse?.action, PermissionResponseAction.GRANT);
    });
  });
}
