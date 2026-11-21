part of 'main.dart';

void removeJavaScriptHandlerTests() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('removeJavaScriptHandler and hasJavaScriptHandler',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();

    const html = '''
<!DOCTYPE html>
<html>
  <body>
    <script>
      window.flutter_inappwebview.callHandler('testHandler');
    </script>
  </body>
</html>
''';

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
          initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
          onWebViewCreated: (controller) {
            controllerCompleter.complete(controller);
            controller.addJavaScriptHandler(
                handlerName: 'testHandler', callback: (args) => 'ok');
          },
          onLoadStop: (controller, url) {
            if (!pageLoaded.isCompleted) {
              pageLoaded.complete();
            }
          },
        ),
      ),
    );

    final InAppWebViewController controller = await controllerCompleter.future;
    await pageLoaded.future;

    expect(controller.hasJavaScriptHandler(handlerName: 'testHandler'), isTrue);

    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://handler.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    controller.removeJavaScriptHandler(handlerName: 'testHandler');
    expect(controller.hasJavaScriptHandler(handlerName: 'testHandler'), isFalse);
  }, skip: shouldSkip);
}
