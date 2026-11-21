import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_inappwebview_platform_interface/src/in_app_webview/in_app_webview_keep_alive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('InAppWebViewController', () {
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

    test('fromPlatformCreationParams should create controller', () {
      final created = InAppWebViewController.fromPlatformCreationParams(
        params: PlatformInAppWebViewControllerCreationParams(id: 'created'),
      );
      expect(created, isA<InAppWebViewController>());
    });

    test('fromPlatform should create controller', () {
      expect(controller, isA<InAppWebViewController>());
      expect(controller.platform, same(fake));
      expect(controller.android, isNotNull);
      expect(controller.ios, isNotNull);
    });

    test('webStorage should expose local and session storage', () {
      expect(controller.webStorage.localStorage, isA<LocalStorage>());
      expect(controller.webStorage.sessionStorage, isA<SessionStorage>());
    });

    test('navigation methods should delegate to platform', () async {
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
      );
      await controller.postUrl(
        url: WebUri('https://example.com/post'),
        postData: Uint8List.fromList([1]),
      );
      await controller.loadData(data: '<html></html>');
      await controller.loadFile(assetFilePath: 'assets/index.html');
      await controller.reload();
      await controller.goBack();
      await controller.goForward();
      await controller.goBackOrForward(steps: -1);
      await controller.stopLoading();

      expect(await controller.canGoBack(), isTrue);
      expect(await controller.canGoForward(), isFalse);
      expect(await controller.canGoBackOrForward(steps: -1), isTrue);
      expect(await controller.isLoading(), isFalse);

      final history = await controller.getCopyBackForwardList();
      expect(history?.list?.length, 1);
      await controller.goTo(historyItem: history!.list!.first);
      await controller.clearHistory();
    });

    test('page info methods should delegate to platform', () async {
      expect((await controller.getUrl())?.rawValue, 'https://example.com');
      expect((await controller.getOriginalUrl())?.rawValue,
          'https://example.com');
      expect(await controller.getTitle(), 'Example');
      expect(await controller.getProgress(), 100);
      expect(await controller.getHtml(), '<html></html>');
      expect(await controller.getFavicons(), isNotEmpty);
      expect(await controller.getContentHeight(), 800);
      expect(await controller.getContentWidth(), 400);
      expect(await controller.getZoomScale(), 1.0);
      expect(await controller.getSelectedText(), 'selected');
      expect(await controller.getHitTestResult(), isNotNull);
      expect(await controller.isInFullscreen(), isFalse);
      expect(await controller.getScrollX(), 0);
      expect(await controller.getScrollY(), 0);
    });

    test('javascript handlers should delegate to platform', () {
      controller.addJavaScriptHandler(
        handlerName: 'testHandler',
        callback: (args) => args,
      );
      expect(controller.hasJavaScriptHandler(handlerName: 'testHandler'), isTrue);
      expect(
        controller.removeJavaScriptHandler(handlerName: 'testHandler'),
        isNotNull,
      );
      expect(controller.hasJavaScriptHandler(handlerName: 'testHandler'), isFalse);
    });

    test('user scripts and messaging should delegate to platform', () async {
      final script = UserScript(
        source: 'window.a = 1;',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        groupName: 'group-a',
      );
      await controller.addUserScript(userScript: script);
      expect(fake.userScripts.length, 1);
      await controller.addUserScripts(userScripts: [script]);
      expect(controller.hasUserScript(userScript: script), isTrue);
      expect(await controller.removeUserScript(userScript: script), isTrue);
      await controller.addUserScript(userScript: script);
      await controller.removeUserScriptsByGroupName(groupName: 'group-a');
      expect(fake.removedGroupNames, contains('group-a'));
      await controller.addUserScript(userScript: script);
      await controller.removeAllUserScripts();
      expect(fake.userScripts, isEmpty);

      final listener = WebMessageListener.fromPlatform(
        platform: FakePlatformWebMessageListener(),
      );
      await controller.addWebMessageListener(listener);
      fake.listeners.add(listener.platform);
      expect(controller.hasWebMessageListener(listener), isTrue);

      final channel = await controller.createWebMessageChannel();
      expect(channel, isA<WebMessageChannel>());
      await controller.postWebMessage(message: WebMessage(data: 'hello'));
    });

    test('settings scripts and media methods should delegate', () async {
      await controller.setSettings(
        settings: InAppWebViewSettings(javaScriptEnabled: true),
      );
      final settings = await controller.getSettings();
      expect(settings?.javaScriptEnabled, isTrue);

      expect(await controller.evaluateJavascript(source: '1 + 1'), 'ok');
      await controller.injectJavascriptFileFromUrl(
        urlFile: WebUri('https://example.com/app.js'),
      );
      expect(
        await controller.injectJavascriptFileFromAsset(
          assetFilePath: 'assets/app.js',
        ),
        isNotNull,
      );
      await controller.injectCSSCode(source: 'body {}');
      await controller.injectCSSFileFromUrl(
        urlFile: WebUri('https://example.com/app.css'),
      );
      await controller.injectCSSFileFromAsset(assetFilePath: 'assets/app.css');
      final asyncResult = await controller.callAsyncJavaScript(
        functionBody: 'return true;',
      );
      expect(asyncResult?.value, 'ok');

      await controller.scrollTo(x: 0, y: 100);
      await controller.scrollBy(x: 0, y: 10);
      await controller.pauseTimers();
      await controller.resumeTimers();
      await controller.zoomBy(zoomFactor: 1.5);
      await controller.pageDown(bottom: true);
      await controller.pageUp(top: true);
      expect(await controller.zoomIn(), isTrue);
      expect(await controller.zoomOut(), isTrue);
      expect(await controller.canScrollVertically(), isTrue);
      expect(await controller.canScrollHorizontally(), isFalse);
      expect(await controller.startSafeBrowsing(), isTrue);
      await controller.clearSslPreferences();
      await controller.pause();
      await controller.resume();
      await controller.pauseAllMediaPlayback();
      await controller.setAllMediaPlaybackSuspended(suspended: true);
      await controller.closeAllMediaPresentations();
      expect(await controller.requestMediaPlaybackState(),
          MediaPlaybackState.NONE);
      await controller.clearFormData();
      expect(await controller.getCameraCaptureState(), MediaCaptureState.NONE);
      await controller.setCameraCaptureState(state: MediaCaptureState.ACTIVE);
      expect(await controller.getMicrophoneCaptureState(),
          MediaCaptureState.NONE);
      await controller.setMicrophoneCaptureState(state: MediaCaptureState.ACTIVE);
    });

    test('utility methods should delegate to platform', () async {
      expect(await controller.takeScreenshot(), isNotNull);
      expect(await controller.isSecureContext(), isTrue);
      expect(await controller.getCertificate(), isNull);
      expect(await controller.hasOnlySecureContent(), isTrue);
      expect(await controller.saveWebArchive(filePath: '/tmp/archive.mht'),
          '/tmp/archive.mht');
      expect(await controller.createPdf(), isNotNull);
      expect(await controller.createWebArchiveData(), isNotNull);
      await controller.clearFocus();
      await controller.setContextMenu(ContextMenu(menuItems: []));
      expect(await controller.requestFocusNodeHref(), isNotNull);
      expect(await controller.requestImageRef(), isNotNull);
      expect(await controller.getMetaTags(), isEmpty);
      expect(await controller.getMetaThemeColor(), isNotNull);
      await controller.loadSimulatedRequest(
        urlRequest: URLRequest(url: WebUri('https://example.com')),
        data: Uint8List.fromList([1]),
      );
      await controller.openDevTools();
      await controller.callDevToolsProtocolMethod(methodName: 'Runtime.evaluate');
      await controller.addDevToolsProtocolEventListener(
        eventName: 'Log.entryAdded',
        callback: (_) {},
      );
      await controller.removeDevToolsProtocolEventListener(
        eventName: 'Log.entryAdded',
      );
      expect(await controller.getIFrameId(), 'frame-1');
      expect(controller.getViewId(), 'test-id');

      final printJob = await controller.printCurrentPage();
      expect(printJob, isA<PrintJobController>());
      controller.dispose();
      expect(fake.disposed, isTrue);
    });
  });

  group('InAppWebViewController static methods', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('static helpers should delegate to platform', () async {
      expect(await InAppWebViewController.getDefaultUserAgent(), 'Mozilla/test');
      await InAppWebViewController.clearAllCache();
      await InAppWebViewController.clearClientCertPreferences();
      expect(
        (await InAppWebViewController.getSafeBrowsingPrivacyPolicyUrl())
            ?.rawValue,
        'https://example.com/policy',
      );
      expect(
        await InAppWebViewController.setSafeBrowsingAllowlist(
          hosts: ['example.com'],
        ),
        isTrue,
      );
      expect(
        (await InAppWebViewController.getCurrentWebViewPackage())?.packageName,
        'com.test.webview',
      );
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      expect(await InAppWebViewController.getVariationsHeader(), 'variations');
      expect(await InAppWebViewController.isMultiProcessEnabled(), isTrue);
      await InAppWebViewController.disableWebView();
      expect(await InAppWebViewController.handlesURLScheme('https'), isTrue);
      await InAppWebViewController.disposeKeepAlive(InAppWebViewKeepAlive());
      expect(await InAppWebViewController.tRexRunnerHtml, contains('t-rex'));
      expect(await InAppWebViewController.tRexRunnerCss, isNotEmpty);
    });
  });

  group('InAppWebViewKeepAlive', () {
    test('should expose id', () {
      final keepAlive = InAppWebViewKeepAlive();
      expect(keepAlive.id, isNotEmpty);
    });

    test('javaScriptHandlersMap should be preserved for keep alive restore', () {
      final props = InAppWebViewControllerKeepAliveProps(
        javaScriptHandlersMap: {
          'handler': (args) => args,
        },
      );
      expect(props.javaScriptHandlersMap.containsKey('handler'), isTrue);
    });

    test('userScripts should be preserved for keep alive restore', () {
      final script = UserScript(
        source: 'window.test = 1;',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      );
      final props = InAppWebViewControllerKeepAliveProps(
        userScripts: {
          UserScriptInjectionTime.AT_DOCUMENT_START: [script],
        },
      );
      expect(props.userScripts.length, 1);
    });

    test('webMessageListenerObjNames should be preserved for keep alive restore',
        () {
      final props = InAppWebViewControllerKeepAliveProps(
        webMessageListenerObjNames: {'FlutterBridge'},
      );
      expect(props.webMessageListenerObjNames, {'FlutterBridge'});
    });

    test('webMessageChannels should be preserved for keep alive restore', () {
      final channel = FakePlatformWebMessageChannel();
      final props = InAppWebViewControllerKeepAliveProps(
        webMessageChannels: {channel},
      );
      expect(props.webMessageChannels, contains(channel));
    });

    test('webMessageListeners should be preserved for keep alive restore', () {
      final listener = FakePlatformWebMessageListener();
      final props = InAppWebViewControllerKeepAliveProps(
        webMessageListeners: {listener},
      );
      expect(props.webMessageListeners, contains(listener));
    });

    test('injectedScriptsFromURL should be preserved for keep alive restore',
        () {
      final props = InAppWebViewControllerKeepAliveProps(
        injectedScriptsFromURL: {
          'https://example.com/app.js': ScriptHtmlTagAttributes(async: true),
        },
      );
      expect(
        props.injectedScriptsFromURL['https://example.com/app.js']?.async,
        isTrue,
      );
    });

    test(
        'devToolsProtocolEventListenerMap should be preserved for keep alive restore',
        () {
      var receivedData;
      final props = InAppWebViewControllerKeepAliveProps(
        devToolsProtocolEventListenerMap: {
          'Network.loadingFinished': (data) => receivedData = data,
        },
      );
      props.devToolsProtocolEventListenerMap['Network.loadingFinished']
          ?.call({'requestId': '1'});
      expect(receivedData, {'requestId': '1'});
    });
  });
}
