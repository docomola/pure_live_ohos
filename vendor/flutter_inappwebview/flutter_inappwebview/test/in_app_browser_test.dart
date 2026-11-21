import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

class _TrackingInAppBrowser extends InAppBrowser {
  _TrackingInAppBrowser(FakePlatformInAppBrowser platform)
      : super.fromPlatform(platform);

  var browserCreated = false;
  WebUri? loadStartUrl;
  WebUri? loadStopUrl;
  WebResourceError? receivedError;
  int? progress;
  ConsoleMessage? consoleMessage;
  PermissionRequest? permissionRequest;
  JsAlertRequest? jsAlertRequest;
  JsConfirmRequest? jsConfirmRequest;
  String? titleChanged;
  int? overScrollX;
  Uri? loadErrorUrl;
  int? loadErrorCode;

  @override
  void onLoadError(Uri? url, int code, String message) {
    loadErrorUrl = url;
    loadErrorCode = code;
  }

  @override
  void onBrowserCreated() {
    browserCreated = true;
  }

  @override
  void onLoadStart(WebUri? url) {
    loadStartUrl = url;
  }

  @override
  void onLoadStop(WebUri? url) {
    loadStopUrl = url;
  }

  @override
  void onReceivedError(WebResourceRequest request, WebResourceError error) {
    receivedError = error;
  }

  @override
  void onProgressChanged(int progress) {
    this.progress = progress;
  }

  @override
  void onConsoleMessage(ConsoleMessage consoleMessage) {
    this.consoleMessage = consoleMessage;
  }

  @override
  void onTitleChanged(String? title) {
    titleChanged = title;
  }

  @override
  Future<PermissionResponse?>? onPermissionRequest(
      PermissionRequest permissionRequest) {
    this.permissionRequest = permissionRequest;
    return Future.value(
      PermissionResponse(
        resources: permissionRequest.resources,
        action: PermissionResponseAction.GRANT,
      ),
    );
  }

  @override
  Future<JsAlertResponse?>? onJsAlert(JsAlertRequest jsAlertRequest) {
    this.jsAlertRequest = jsAlertRequest;
    return Future.value(JsAlertResponse(handledByClient: true));
  }

  @override
  Future<JsConfirmResponse?>? onJsConfirm(JsConfirmRequest jsConfirmRequest) {
    this.jsConfirmRequest = jsConfirmRequest;
    return Future.value(JsConfirmResponse(handledByClient: true, action: JsConfirmResponseAction.CONFIRM));
  }

  @override
  void onOverScrolled(int x, int y, bool clampedX, bool clampedY) {
    overScrollX = x;
  }
}

void main() {
  group('InAppBrowser', () {
    late FakeInAppWebViewPlatform fakePlatform;
    InAppWebViewPlatform? previousPlatform;
    late FakePlatformInAppBrowser fakeBrowser;
    late _TrackingInAppBrowser browser;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      fakePlatform = installFakeInAppWebViewPlatform();
      fakeBrowser = FakePlatformInAppBrowser();
      browser = _TrackingInAppBrowser(fakeBrowser);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should create browser through platform factory', () {
      final created = InAppBrowser();
      expect(created.id, isNotEmpty);
      expect(fakePlatform.lastBrowser, isNotNull);
    });

    test('constructor should wire optional browser configuration', () {
      final scripts = UnmodifiableListView([
        UserScript(source: 'true;', injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
      ]);
      final browser = InAppBrowser(
        contextMenu: ContextMenu(menuItems: []),
        pullToRefreshController: PullToRefreshController(onRefresh: () {}),
        findInteractionController: FindInteractionController(),
        initialUserScripts: scripts,
        windowId: 7,
      );

      expect(browser.contextMenu, isNotNull);
      expect(browser.pullToRefreshController, isA<PullToRefreshController>());
      expect(browser.findInteractionController, isA<FindInteractionController>());
      expect(browser.initialUserScripts?.length, 1);
      expect(browser.windowId, 7);
      expect(browser.platform, isA<FakePlatformInAppBrowser>());
    });

    test('id platform and webViewController getters should expose browser state',
        () async {
      expect(browser.id, 'fake-browser-id');
      expect(browser.platform, same(fakeBrowser));

      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
      );
      expect(browser.webViewController, isA<InAppWebViewController>());
    });

    test('fromPlatformCreationParams and fromPlatform should create browser',
        () {
      final params = PlatformInAppBrowserCreationParams(windowId: 9);
      final fromParams = InAppBrowser.fromPlatformCreationParams(params);
      expect(fromParams.windowId, 9);

      final fromPlatform =
          InAppBrowser.fromPlatform(FakePlatformInAppBrowser(params));
      expect(fromPlatform.id, 'fake-browser-id');
    });

    test('openUrlRequest should open browser and expose webViewController',
        () async {
      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
      );

      expect(browser.isOpened(), isTrue);
      expect(browser.webViewController, isA<InAppWebViewController>());
    });

    test('openFile should delegate asset path to platform', () async {
      await browser.openFile(assetFilePath: 'assets/index.html');

      expect(fakeBrowser.openedAssetPath, 'assets/index.html');
      expect(browser.isOpened(), isTrue);
    });

    test('openData should delegate html data to platform', () async {
      await browser.openData(data: '<html><body>test</body></html>');

      expect(fakeBrowser.openedData, '<html><body>test</body></html>');
      expect(browser.isOpened(), isTrue);
    });

    test('setSettings and getSettings should delegate to platform', () async {
      final settings = InAppBrowserClassSettings(
        webViewSettings: InAppWebViewSettings(javaScriptEnabled: true),
      );

      await browser.setSettings(settings: settings);
      final loaded = await browser.getSettings();

      expect(fakeBrowser.setSettingsCalled, isTrue);
      expect(fakeBrowser.getSettingsCalled, isTrue);
      expect(loaded?.webViewSettings?.javaScriptEnabled, isTrue);
    });

    test('event callbacks should be invoked through eventHandler', () {
      final handler = fakeBrowser.eventHandler!;
      final url = WebUri('https://example.com');
      final request = WebResourceRequest(url: url);
      final error = WebResourceError(
        type: WebResourceErrorType.HOST_LOOKUP,
        description: 'host lookup failed',
      );

      handler.onBrowserCreated();
      handler.onLoadStart(url);
      handler.onLoadStop(url);
      handler.onLoadError(url, 404, 'not found');
      handler.onReceivedError(request, error);
      handler.onProgressChanged(50);
      handler.onTitleChanged('Example Title');
      handler.onConsoleMessage(
        ConsoleMessage(message: 'log', messageLevel: ConsoleMessageLevel.LOG),
      );
      handler.onPermissionRequest(
        PermissionRequest(origin: url, resources: [PermissionResourceType.CAMERA]),
      );
      handler.onJsAlert(JsAlertRequest(message: 'alert', url: url));
      handler.onJsConfirm(JsConfirmRequest(message: 'confirm', url: url));
      handler.onOverScrolled(10, 20, true, false);

      expect(browser.browserCreated, isTrue);
      expect(browser.loadStartUrl, url);
      expect(browser.loadStopUrl, url);
      expect(browser.loadErrorUrl, url);
      expect(browser.loadErrorCode, 404);
      expect(browser.receivedError, error);
      expect(browser.progress, 50);
      expect(browser.titleChanged, 'Example Title');
      expect(browser.consoleMessage?.message, 'log');
      expect(browser.permissionRequest?.resources.first,
          PermissionResourceType.CAMERA);
      expect(browser.jsAlertRequest?.message, 'alert');
      expect(browser.jsConfirmRequest?.message, 'confirm');
      expect(browser.overScrollX, 10);
    });

    test('openWithSystemBrowser should delegate to static platform browser',
        () async {
      await InAppBrowser.openWithSystemBrowser(
        url: WebUri('https://example.com'),
      );
    });

    test('menu items show hide close and dispose should delegate to platform',
        () async {
      final menuItem = InAppBrowserMenuItem(
        id: 1,
        title: 'Refresh',
        icon: Uint8List.fromList([1]),
      );

      browser.addMenuItem(menuItem);
      browser.addMenuItems([menuItem]);
      expect(browser.hasMenuItem(menuItem), isTrue);
      expect(browser.removeMenuItem(menuItem), isTrue);
      browser.addMenuItem(menuItem);
      browser.removeMenuItems([menuItem]);
      expect(browser.hasMenuItem(menuItem), isFalse);
      browser.addMenuItem(menuItem);
      browser.removeAllMenuItem();
      expect(fakeBrowser.menuItems, isEmpty);

      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
      );
      expect(browser.isOpened(), isTrue);
      await browser.show();
      expect(await browser.isHidden(), isFalse);
      await browser.hide();
      expect(await browser.isHidden(), isTrue);
      await browser.close();
      expect(browser.isOpened(), isFalse);
      browser.dispose();
    });
  });
}
