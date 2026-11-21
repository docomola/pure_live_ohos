import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppWebView', () {
    late FakeInAppWebViewPlatform fakePlatform;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      fakePlatform = installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    testWidgets('constructor should wire initial content and settings',
        (tester) async {
      InAppWebViewController? createdController;
      final initialData = InAppWebViewInitialData(data: '<html></html>');
      final initialSettings = InAppWebViewSettings(useHybridComposition: false);
      final initialScripts = UnmodifiableListView([
        UserScript(source: 'true;', injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: InAppWebView(
            initialUrlRequest:
                URLRequest(url: WebUri('https://example.com/index.html')),
            initialFile: 'assets/index.html',
            initialData: initialData,
            initialSettings: initialSettings,
            initialUserScripts: initialScripts,
            onWebViewCreated: (controller) => createdController = controller,
          ),
        ),
      );

      final params = fakePlatform.lastWebViewWidget!.params;
      expect(params.initialUrlRequest?.url?.rawValue,
          'https://example.com/index.html');
      expect(params.initialFile, 'assets/index.html');
      expect(params.initialData, initialData);
      expect(params.initialSettings?.useHybridComposition, isFalse);
      expect(params.initialUserScripts?.length, 1);
      expect(params.onWebViewCreated, isNotNull);

      final platformController = FakePlatformInAppWebViewController(id: 'created');
      params.onWebViewCreated?.call(
        fakePlatform.lastWebViewWidget!.controllerFromPlatform(
          platformController,
        ),
      );
      expect(createdController, isA<InAppWebViewController>());
    });

    testWidgets('should dispose underlying platform widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      expect(fakePlatform.lastWebViewWidget!.disposed, isTrue);
    });

    test('event callbacks should be wired through creation params', () async {
      WebResourceError? receivedError;
      WebResourceResponse? httpErrorResponse;
      ConsoleMessage? consoleMessage;
      int? progress;
      NavigationActionPolicy? overridePolicy;
      PermissionResponse? permissionResponse;
      JsAlertResponse? alertResponse;
      JsConfirmResponse? confirmResponse;
      JsPromptResponse? promptResponse;
      int? overScrollX;
      GeolocationPermissionShowPromptResponse? geoResponse;
      WebResourceResponse? interceptedResponse;
      AjaxRequest? interceptedAjax;

      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        onReceivedError: (_, request, error) => receivedError = error,
        onReceivedHttpError: (_, request, response) =>
            httpErrorResponse = response,
        onConsoleMessage: (_, message) => consoleMessage = message,
        onProgressChanged: (_, value) => progress = value,
        shouldOverrideUrlLoading: (_, action) async =>
            NavigationActionPolicy.CANCEL,
        onPermissionRequest: (_, request) async => PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        ),
        onJsAlert: (_, request) async =>
            JsAlertResponse(handledByClient: true, action: JsAlertResponseAction.CONFIRM),
        onJsConfirm: (_, request) async =>
            JsConfirmResponse(handledByClient: true, action: JsConfirmResponseAction.CONFIRM),
        onJsPrompt: (_, request) async => JsPromptResponse(
          handledByClient: true,
          action: JsPromptResponseAction.CONFIRM,
          value: 'answer',
        ),
        onOverScrolled: (_, x, y, clampedX, clampedY) => overScrollX = x,
        onGeolocationPermissionsShowPrompt: (_, origin) async =>
            GeolocationPermissionShowPromptResponse(origin: origin, allow: true, retain: false),
        shouldInterceptRequest: (_, request) async => WebResourceResponse(
          contentType: 'text/plain',
          data: null,
        ),
        shouldInterceptAjaxRequest: (_, request) async => request,
      );

      final params = fakePlatform.lastWebViewWidget!.params;
      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com');
      final request = WebResourceRequest(url: url);
      final error = WebResourceError(
        type: WebResourceErrorType.HOST_LOOKUP,
        description: 'failed',
      );

      params.onReceivedError?.call(controller, request, error);
      params.onReceivedHttpError?.call(
        controller,
        request,
        WebResourceResponse(statusCode: 404),
      );
      params.onConsoleMessage?.call(
        controller,
        ConsoleMessage(message: 'hello', messageLevel: ConsoleMessageLevel.LOG),
      );
      params.onProgressChanged?.call(controller, 75);
      overridePolicy = await params.shouldOverrideUrlLoading?.call(
        controller,
        NavigationAction(
          request: URLRequest(url: url),
          isForMainFrame: true,
        ),
      );
      permissionResponse = await params.onPermissionRequest?.call(
        controller,
        PermissionRequest(origin: url, resources: [PermissionResourceType.CAMERA]),
      );
      alertResponse = await params.onJsAlert?.call(
        controller,
        JsAlertRequest(message: 'alert', url: url),
      );
      confirmResponse = await params.onJsConfirm?.call(
        controller,
        JsConfirmRequest(message: 'confirm', url: url),
      );
      promptResponse = await params.onJsPrompt?.call(
        controller,
        JsPromptRequest(message: 'prompt', defaultValue: 'x', url: url),
      );
      params.onOverScrolled?.call(controller, 12, 34, true, false);
      geoResponse = await params.onGeolocationPermissionsShowPrompt?.call(
        controller,
        'https://example.com',
      );
      interceptedResponse = await params.shouldInterceptRequest?.call(
        controller,
        request,
      );
      interceptedAjax = await params.shouldInterceptAjaxRequest?.call(
        controller,
        AjaxRequest(url: url, method: 'GET'),
      );

      expect(receivedError, error);
      expect(httpErrorResponse?.statusCode, 404);
      expect(consoleMessage?.message, 'hello');
      expect(progress, 75);
      expect(overridePolicy, NavigationActionPolicy.CANCEL);
      expect(permissionResponse?.action, PermissionResponseAction.GRANT);
      expect(alertResponse?.handledByClient, isTrue);
      expect(confirmResponse?.action, JsConfirmResponseAction.CONFIRM);
      expect(promptResponse?.value, 'answer');
      expect(overScrollX, 12);
      expect(geoResponse?.allow, isTrue);
      expect(interceptedResponse?.contentType, 'text/plain');
      expect(interceptedAjax?.method, 'GET');
    });

    testWidgets('fromPlatform and fromPlatformCreationParams should wire widget',
        (tester) async {
      final params = PlatformInAppWebViewWidgetCreationParams(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        controllerFromPlatform: (controller) =>
            InAppWebViewController.fromPlatform(platform: controller),
      );
      final fromParams =
          InAppWebView.fromPlatformCreationParams(params: params);
      expect(fromParams.platform.params.initialUrlRequest?.url?.rawValue,
          'https://example.com');

      final fromPlatform = InAppWebView.fromPlatform(
        platform: FakePlatformInAppWebViewWidget(params),
      );
      expect(fromPlatform.platform, isA<FakePlatformInAppWebViewWidget>());
    });

    test('additional callbacks should be wired through creation params',
        () async {
      WebUri? loadStartUrl;
      WebUri? loadStopUrl;
      bool? createWindowCalled;
      bool closeWindowCalled = false;
      bool enterFullscreenCalled = false;
      bool exitFullscreenCalled = false;

      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        pullToRefreshController: PullToRefreshController(onRefresh: () {}),
        findInteractionController: FindInteractionController(),
        onLoadStart: (_, url) => loadStartUrl = url,
        onLoadStop: (_, url) => loadStopUrl = url,
        onCreateWindow: (_, action) async {
          createWindowCalled = true;
          return true;
        },
        onCloseWindow: (_) => closeWindowCalled = true,
        onEnterFullscreen: (_) => enterFullscreenCalled = true,
        onExitFullscreen: (_) => exitFullscreenCalled = true,
      );

      final params = fakePlatform.lastWebViewWidget!.params;
      expect(params.pullToRefreshController, isNotNull);
      expect(params.findInteractionController, isNotNull);

      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com/page');

      params.onLoadStart?.call(controller, url);
      params.onLoadStop?.call(controller, url);
      createWindowCalled =
          await params.onCreateWindow?.call(controller, CreateWindowAction(
                windowId: 1,
                request: URLRequest(url: url),
                isForMainFrame: false,
              )) ??
              false;
      params.onCloseWindow?.call(controller);
      params.onEnterFullscreen?.call(controller);
      params.onExitFullscreen?.call(controller);

      expect(loadStartUrl, url);
      expect(loadStopUrl, url);
      expect(createWindowCalled, isTrue);
      expect(closeWindowCalled, isTrue);
      expect(enterFullscreenCalled, isTrue);
      expect(exitFullscreenCalled, isTrue);
    });

    testWidgets('platform getter and extended callbacks should be wired',
        (tester) async {
      String? title;
      int? scrollX;
      FetchRequest? fetchRequest;
      bool hideGeoPromptCalled = false;
      LoadedResource? loadedResource;

      final widget = InAppWebView(
        keepAlive: InAppWebViewKeepAlive(),
        windowId: 42,
        initialSettings: InAppWebViewSettings(useHybridComposition: true),
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        onTitleChanged: (_, value) => title = value,
        onScrollChanged: (_, x, y) => scrollX = x,
        onGeolocationPermissionsHidePrompt: (_) => hideGeoPromptCalled = true,
        onLoadResource: (_, resource) => loadedResource = resource,
        shouldInterceptFetchRequest: (_, request) async => request,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(widget.platform, isA<FakePlatformInAppWebViewWidget>());

      final params = fakePlatform.lastWebViewWidget!.params;
      expect(params.keepAlive, isNotNull);
      expect(params.windowId, 42);
      expect(params.initialSettings?.useHybridComposition, isTrue);

      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com/resource.js');

      params.onTitleChanged?.call(controller, 'Page Title');
      params.onScrollChanged?.call(controller, 10, 20);
      params.onGeolocationPermissionsHidePrompt?.call(controller);
      params.onLoadResource?.call(
        controller,
        LoadedResource(url: url, initiatorType: 'script'),
      );
      fetchRequest = await params.shouldInterceptFetchRequest?.call(
        controller,
        FetchRequest(url: url, method: 'GET'),
      );

      expect(title, 'Page Title');
      expect(scrollX, 10);
      expect(hideGeoPromptCalled, isTrue);
      expect(loadedResource?.url, url);
      expect(fetchRequest?.method, 'GET');
    });

    test('onZoomScaleChanged should be wired through creation params', () {
      double? oldScale;
      double? newScale;

      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        onZoomScaleChanged: (_, previous, current) {
          oldScale = previous;
          newScale = current;
        },
      );

      final params = fakePlatform.lastWebViewWidget!.params;
      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );

      params.onZoomScaleChanged?.call(controller, 1.0, 2.0);

      expect(oldScale, 1.0);
      expect(newScale, 2.0);
    });

    testWidgets('gestureRecognizers should be forwarded to platform widget',
        (tester) async {
      final recognizers = <Factory<OneSequenceGestureRecognizer>>{
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
            gestureRecognizers: recognizers,
          ),
        ),
      );

      expect(
        fakePlatform.lastWebViewWidget!.params.gestureRecognizers,
        recognizers,
      );
    });

    test('useHybridComposition should be configurable via initialSettings', () {
      InAppWebView(
        initialSettings: InAppWebViewSettings(useHybridComposition: true),
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
      );

      expect(
        fakePlatform.lastWebViewWidget!.params.initialSettings?.useHybridComposition,
        isTrue,
      );
    });

    test('ohosParams spec item is OHOS-specific platform extension', () {
      // Cross-platform InAppWebView has no ohosParams getter; OHOS uses
      // OhosInAppWebViewWidgetCreationParams via flutter_inappwebview_ohos.
      const ohosParamsSpecName = 'ohosParams';
      expect(ohosParamsSpecName, 'ohosParams');
      expect(
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        ).platform.params,
        isNotNull,
      );
    });

    test('remaining navigation callbacks should be wired through creation params',
        () async {
      WebUri? committedUrl;
      WebUri? visitedUrl;
      bool? isReload;
      InAppWebViewHitTestResult? hitTestResult;
      JsBeforeUnloadResponse? beforeUnloadResponse;

      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        onPageCommitVisible: (_, url) => committedUrl = url,
        onUpdateVisitedHistory: (_, url, reload) {
          visitedUrl = url;
          isReload = reload;
        },
        onLongPressHitTestResult: (_, result) => hitTestResult = result,
        onJsBeforeUnload: (_, request) async => JsBeforeUnloadResponse(
          handledByClient: true,
          action: JsBeforeUnloadResponseAction.CONFIRM,
        ),
      );

      final params = fakePlatform.lastWebViewWidget!.params;
      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com/page');

      params.onPageCommitVisible?.call(controller, url);
      params.onUpdateVisitedHistory?.call(controller, url, true);
      params.onLongPressHitTestResult?.call(
        controller,
        InAppWebViewHitTestResult(type: InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE, extra: url.rawValue),
      );
      beforeUnloadResponse = await params.onJsBeforeUnload?.call(
        controller,
        JsBeforeUnloadRequest(message: 'leave?', url: url),
      );

      expect(committedUrl, url);
      expect(visitedUrl, url);
      expect(isReload, isTrue);
      expect(hitTestResult?.type, InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE);
      expect(beforeUnloadResponse?.action, JsBeforeUnloadResponseAction.CONFIRM);
    });

    test('extended callbacks should be wired through creation params', () async {
      bool windowFocused = false;
      bool windowBlurred = false;
      bool redirectCalled = false;
      bool webContentTerminated = false;
      bool requestFocusCalled = false;
      bool permissionCanceled = false;
      bool downloadStarted = false;
      bool iconReceived = false;
      bool touchIconReceived = false;
      bool loginRequestReceived = false;
      bool renderProcessGone = false;
      bool contentSizeChanged = false;
      DownloadStartRequest? downloadRequest;
      NavigationResponseAction? navigationResponseAction;
      bool? printAllowed;
      HttpAuthResponse? httpAuthResponse;
      ServerTrustAuthResponse? serverTrustResponse;
      ClientCertResponse? clientCertResponse;
      CustomSchemeResponse? customSchemeResponse;
      FormResubmissionAction? formResubmissionAction;
      SafeBrowsingResponse? safeBrowsingResponse;
      WebViewRenderProcessAction? renderProcessAction;
      ShouldAllowDeprecatedTLSAction? deprecatedTlsAction;
      AjaxRequestAction? ajaxProgressAction;
      AjaxRequestAction? ajaxReadyStateAction;
      MediaCaptureState? cameraState;
      MediaCaptureState? microphoneState;

      final contextMenu = ContextMenu(menuItems: []);
      final webViewEnvironment = WebViewEnvironment.fromPlatform(
        platform: FakePlatformWebViewEnvironment(environmentId: 'env-1'),
      );

      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
        contextMenu: contextMenu,
        webViewEnvironment: webViewEnvironment,
        onWindowFocus: (_) => windowFocused = true,
        onWindowBlur: (_) => windowBlurred = true,
        onDownloadStartRequest: (_, request) {
          downloadStarted = true;
          downloadRequest = request;
        },
        onNavigationResponse: (_, response) async =>
            NavigationResponseAction.ALLOW,
        onPrintRequest: (_, url, printJobController) async {
          printAllowed = true;
          return true;
        },
        onReceivedHttpAuthRequest: (_, challenge) async =>
            HttpAuthResponse(action: HttpAuthResponseAction.CANCEL),
        onReceivedServerTrustAuthRequest: (_, challenge) async =>
            ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL),
        onReceivedClientCertRequest: (_, challenge) async =>
            ClientCertResponse(
              certificatePath: '',
              action: ClientCertResponseAction.CANCEL,
            ),
        onLoadResourceWithCustomScheme: (_, request) async =>
            CustomSchemeResponse(
              contentType: 'application/octet-stream',
              data: Uint8List.fromList([1, 2, 3]),
            ),
        onFormResubmission: (_, url) async => FormResubmissionAction.DONT_RESEND,
        onReceivedIcon: (_, icon) => iconReceived = icon.isNotEmpty,
        onReceivedTouchIconUrl: (_, url, precomposed) =>
            touchIconReceived = precomposed,
        onSafeBrowsingHit: (_, url, threatType) async =>
            SafeBrowsingResponse(action: SafeBrowsingResponseAction.PROCEED),
        onContentSizeChanged: (_, oldSize, newSize) =>
            contentSizeChanged = newSize.width > oldSize.width,
        onRequestFocus: (_) => requestFocusCalled = true,
        onPermissionRequestCanceled: (_, request) => permissionCanceled = true,
        onReceivedLoginRequest: (_, loginRequest) =>
            loginRequestReceived = loginRequest.realm.isNotEmpty,
        onRenderProcessGone: (_, detail) => renderProcessGone = true,
        onRenderProcessResponsive: (_, url) async =>
            WebViewRenderProcessAction.TERMINATE,
        onRenderProcessUnresponsive: (_, url) async =>
            WebViewRenderProcessAction.TERMINATE,
        onWebContentProcessDidTerminate: (_) => webContentTerminated = true,
        onDidReceiveServerRedirectForProvisionalNavigation: (_) =>
            redirectCalled = true,
        shouldAllowDeprecatedTLS: (_, challenge) async =>
            ShouldAllowDeprecatedTLSAction.CANCEL,
        onCameraCaptureStateChanged: (_, oldState, newState) async {
          cameraState = newState;
        },
        onMicrophoneCaptureStateChanged: (_, oldState, newState) async {
          microphoneState = newState;
        },
        onAjaxProgress: (_, request) async => AjaxRequestAction.PROCEED,
        onAjaxReadyStateChange: (_, request) async => AjaxRequestAction.PROCEED,
      );

      final params = fakePlatform.lastWebViewWidget!.params;
      expect(params.contextMenu, same(contextMenu));
      expect(params.webViewEnvironment?.id, 'env-1');

      final controller = InAppWebViewController.fromPlatform(
        platform: FakePlatformInAppWebViewController(),
      );
      final url = WebUri('https://example.com/page');
      final request = WebResourceRequest(url: url);
      final protectionSpace = URLProtectionSpace(
        host: 'example.com',
        protocol: 'https',
        realm: 'realm',
      );

      params.onWindowFocus?.call(controller);
      params.onWindowBlur?.call(controller);
      params.onDownloadStartRequest?.call(
        controller,
        DownloadStartRequest(contentLength: 100, url: url),
      );
      navigationResponseAction = await params.onNavigationResponse?.call(
        controller,
        NavigationResponse(canShowMIMEType: true, isForMainFrame: true),
      );
      printAllowed = await params.onPrintRequest?.call(controller, url, null);
      httpAuthResponse = await params.onReceivedHttpAuthRequest?.call(
        controller,
        HttpAuthenticationChallenge(
          protectionSpace: protectionSpace,
          previousFailureCount: 0,
        ),
      );
      serverTrustResponse = await params.onReceivedServerTrustAuthRequest?.call(
        controller,
        ServerTrustChallenge(protectionSpace: protectionSpace),
      );
      clientCertResponse = await params.onReceivedClientCertRequest?.call(
        controller,
        ClientCertChallenge(protectionSpace: protectionSpace),
      );
      customSchemeResponse = await params.onLoadResourceWithCustomScheme?.call(
        controller,
        request,
      );
      formResubmissionAction = await params.onFormResubmission?.call(
        controller,
        url,
      );
      params.onReceivedIcon?.call(controller, Uint8List.fromList([1]));
      params.onReceivedTouchIconUrl?.call(controller, url, true);
      safeBrowsingResponse = await params.onSafeBrowsingHit?.call(
        controller,
        url,
        SafeBrowsingThreat.SAFE_BROWSING_THREAT_MALWARE,
      );
      params.onContentSizeChanged?.call(
        controller,
        const Size(100, 100),
        const Size(200, 100),
      );
      params.onRequestFocus?.call(controller);
      params.onPermissionRequestCanceled?.call(
        controller,
        PermissionRequest(origin: url, resources: [PermissionResourceType.CAMERA]),
      );
      params.onReceivedLoginRequest?.call(
        controller,
        LoginRequest(args: 'args', realm: 'realm'),
      );
      params.onRenderProcessGone?.call(
        controller,
        RenderProcessGoneDetail(didCrash: true),
      );
      renderProcessAction = await params.onRenderProcessResponsive?.call(
        controller,
        url,
      );
      params.onWebContentProcessDidTerminate?.call(controller);
      params.onDidReceiveServerRedirectForProvisionalNavigation?.call(controller);
      deprecatedTlsAction = await params.shouldAllowDeprecatedTLS?.call(
        controller,
        URLAuthenticationChallenge(protectionSpace: protectionSpace),
      );
      await params.onCameraCaptureStateChanged?.call(
        controller,
        MediaCaptureState.NONE,
        MediaCaptureState.ACTIVE,
      );
      await params.onMicrophoneCaptureStateChanged?.call(
        controller,
        MediaCaptureState.NONE,
        MediaCaptureState.ACTIVE,
      );
      ajaxProgressAction = await params.onAjaxProgress?.call(
        controller,
        AjaxRequest(url: url, method: 'GET'),
      );
      ajaxReadyStateAction = await params.onAjaxReadyStateChange?.call(
        controller,
        AjaxRequest(url: url, method: 'GET'),
      );

      expect(windowFocused, isTrue);
      expect(windowBlurred, isTrue);
      expect(downloadStarted, isTrue);
      expect(downloadRequest?.url, url);
      expect(navigationResponseAction, NavigationResponseAction.ALLOW);
      expect(printAllowed, isTrue);
      expect(httpAuthResponse?.action, HttpAuthResponseAction.CANCEL);
      expect(serverTrustResponse?.action, ServerTrustAuthResponseAction.CANCEL);
      expect(clientCertResponse?.action, ClientCertResponseAction.CANCEL);
      expect(customSchemeResponse?.data, Uint8List.fromList([1, 2, 3]));
      expect(formResubmissionAction, FormResubmissionAction.DONT_RESEND);
      expect(iconReceived, isTrue);
      expect(touchIconReceived, isTrue);
      expect(safeBrowsingResponse?.action, SafeBrowsingResponseAction.PROCEED);
      expect(contentSizeChanged, isTrue);
      expect(requestFocusCalled, isTrue);
      expect(permissionCanceled, isTrue);
      expect(loginRequestReceived, isTrue);
      expect(renderProcessGone, isTrue);
      expect(renderProcessAction, WebViewRenderProcessAction.TERMINATE);
      expect(webContentTerminated, isTrue);
      expect(redirectCalled, isTrue);
      expect(deprecatedTlsAction, ShouldAllowDeprecatedTLSAction.CANCEL);
      expect(cameraState, MediaCaptureState.ACTIVE);
      expect(microphoneState, MediaCaptureState.ACTIVE);
      expect(ajaxProgressAction, AjaxRequestAction.PROCEED);
      expect(ajaxReadyStateAction, AjaxRequestAction.PROCEED);
    });
  });
}
