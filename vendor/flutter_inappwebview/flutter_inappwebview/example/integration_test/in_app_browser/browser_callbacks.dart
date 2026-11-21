part of 'main.dart';

class CallbacksInAppBrowser extends InAppBrowser {
  final Completer<void> browserCreated = Completer<void>();
  final Completer<void> firstPageLoaded = Completer<void>();
  final Completer<void> browserClosed = Completer<void>();
  final Completer<JsAlertRequest> alertCompleter = Completer<JsAlertRequest>();
  final Completer<bool> confirmCompleter = Completer<bool>();
  final Completer<String> promptCompleter = Completer<String>();
  final Completer<String> geolocationCompleter = Completer<String>();
  final Completer<void> overscrollCompleter = Completer<void>();

  @override
  Future onBrowserCreated() async {
    browserCreated.complete();
  }

  @override
  void onLoadStop(WebUri? url) {
    super.onLoadStop(url);
    if (!firstPageLoaded.isCompleted) {
      firstPageLoaded.complete();
    }
  }

  @override
  void onExit() {
    if (!browserClosed.isCompleted) {
      browserClosed.complete();
    }
  }

  @override
  Future<JsAlertResponse?>? onJsAlert(JsAlertRequest jsAlertRequest) {
    if (!alertCompleter.isCompleted) {
      alertCompleter.complete(jsAlertRequest);
    }
    return Future.value(JsAlertResponse(
        handledByClient: true, action: JsAlertResponseAction.CONFIRM));
  }

  @override
  Future<JsConfirmResponse?>? onJsConfirm(JsConfirmRequest jsConfirmRequest) {
    return Future.value(JsConfirmResponse(
        handledByClient: true, action: JsConfirmResponseAction.CONFIRM));
  }

  @override
  Future<JsPromptResponse?>? onJsPrompt(JsPromptRequest jsPromptRequest) {
    return Future.value(JsPromptResponse(
        handledByClient: true,
        action: JsPromptResponseAction.CONFIRM,
        value: 'browser prompt value'));
  }

  @override
  Future<GeolocationPermissionShowPromptResponse?>?
      onGeolocationPermissionsShowPrompt(String origin) {
    if (!geolocationCompleter.isCompleted) {
      geolocationCompleter.complete(origin);
    }
    return Future.value(GeolocationPermissionShowPromptResponse(
        origin: origin, allow: true, retain: true));
  }

  @override
  void onOverScrolled(int x, int y, bool clampedX, bool clampedY) {
    if (!overscrollCompleter.isCompleted && y > 0) {
      overscrollCompleter.complete();
    }
  }
}

void browserCallbacks() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTest('removeMenuItem', () async {
    final inAppBrowser = CallbacksInAppBrowser();
    final menuItem = InAppBrowserMenuItem(
      id: 99,
      title: 'Remove Me',
      order: 0,
      onClick: () {},
    );

    inAppBrowser.addMenuItem(menuItem);
    expect(inAppBrowser.removeMenuItem(menuItem), isTrue);

    await inAppBrowser.openUrlRequest(
      urlRequest: URLRequest(url: TEST_URL_1),
      settings: InAppBrowserClassSettings(
        browserSettings: InAppBrowserSettings(hideDefaultMenuItems: true),
      ),
    );
    await inAppBrowser.browserCreated.future;
    await inAppBrowser.firstPageLoaded.future;
    await inAppBrowser.close();
    await inAppBrowser.browserClosed.future;
  }, skip: shouldSkip);

  skippableTest('onJsAlert, onJsConfirm, onJsPrompt', () async {
    final inAppBrowser = CallbacksInAppBrowser();

    await inAppBrowser.openUrlRequest(
      urlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
      settings: InAppBrowserClassSettings(
        webViewSettings: InAppWebViewSettings(javaScriptEnabled: true),
      ),
    );
    await inAppBrowser.browserCreated.future;

    final controller = inAppBrowser.webViewController!;
    controller.addJavaScriptHandler(
      handlerName: 'confirm',
      callback: (args) {
        if (!inAppBrowser.confirmCompleter.isCompleted) {
          inAppBrowser.confirmCompleter.complete(args[0] as bool);
        }
        return null;
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'prompt',
      callback: (args) {
        if (!inAppBrowser.promptCompleter.isCompleted) {
          inAppBrowser.promptCompleter.complete(args[0] as String);
        }
        return null;
      },
    );

    await controller.loadFile(
      assetFilePath: 'test_assets/in_app_webview_on_js_dialog_test.html',
    );

    final alertRequest = await inAppBrowser.alertCompleter.future;
    expect(alertRequest.message, 'alert message');
    expect(await inAppBrowser.confirmCompleter.future, isTrue);
    expect(await inAppBrowser.promptCompleter.future, 'browser prompt value');

    await inAppBrowser.close();
    await inAppBrowser.browserClosed.future;
  }, skip: shouldSkip);

  skippableTest('onGeolocationPermissionsShowPrompt', () async {
    final inAppBrowser = CallbacksInAppBrowser();

    await inAppBrowser.openUrlRequest(
      urlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
      settings: InAppBrowserClassSettings(
        webViewSettings: InAppWebViewSettings(javaScriptEnabled: true),
      ),
    );
    await inAppBrowser.browserCreated.future;
    await inAppBrowser.firstPageLoaded.future;

    const html = '''
<!DOCTYPE html>
<html>
  <body>
    <script>
      navigator.geolocation.getCurrentPosition(function(){}, function(){});
    </script>
  </body>
</html>
''';

    await inAppBrowser.webViewController!.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://browser-geo.test/'),
    );

    final origin = await inAppBrowser.geolocationCompleter.future;
    expect(origin, isNotEmpty);

    await inAppBrowser.close();
    await inAppBrowser.browserClosed.future;
  }, skip: shouldSkip);

  skippableTest('onOverScrolled', () async {
    final inAppBrowser = CallbacksInAppBrowser();

    await inAppBrowser.openUrlRequest(
      urlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
    );
    await inAppBrowser.browserCreated.future;
    await inAppBrowser.firstPageLoaded.future;

    const html = '''
<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;">
    <div style="height:5000px;width:100%;">tall content</div>
  </body>
</html>
''';

    final controller = inAppBrowser.webViewController!;
    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://browser-overscroll.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));
    await controller.scrollTo(x: 0, y: 4500);

    await expectLater(inAppBrowser.overscrollCompleter.future, completes);

    await inAppBrowser.close();
    await inAppBrowser.browserClosed.future;
  }, skip: shouldSkip);
}
