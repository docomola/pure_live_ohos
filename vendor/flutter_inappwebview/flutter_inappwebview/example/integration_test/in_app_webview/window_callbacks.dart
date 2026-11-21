part of 'main.dart';

void windowCallbacks() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('onCreateWindow and onCloseWindow',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<int> onCreateWindowCompleter = Completer<int>();
    final Completer<void> onCloseWindowCompleter = Completer<void>();

    const html = '''
<!DOCTYPE html>
<html>
  <body>
    <button id="open" onclick="window.open('about:blank','_blank')">open</button>
  </body>
</html>
''';

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
          initialSettings: InAppWebViewSettings(
            javaScriptCanOpenWindowsAutomatically: true,
            supportMultipleWindows: true,
            clearCache: true,
          ),
          onWebViewCreated: (controller) {
            controllerCompleter.complete(controller);
          },
          onCreateWindow: (controller, createNavigationAction) async {
            if (!onCreateWindowCompleter.isCompleted) {
              onCreateWindowCompleter.complete(createNavigationAction.windowId);
            }
            return true;
          },
        ),
      ),
    );

    final InAppWebViewController controller = await controllerCompleter.future;

    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://window.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));
    await controller.evaluateJavascript(
        source: "document.getElementById('open').click();");

    final windowId = await onCreateWindowCompleter.future;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          windowId: windowId,
          initialSettings: InAppWebViewSettings(clearCache: true),
          onLoadStop: (controller, url) async {
            if (url!.scheme != 'about') {
              await controller.evaluateJavascript(source: "window.close();");
            }
          },
          onCloseWindow: (controller) {
            if (!onCloseWindowCompleter.isCompleted) {
              onCloseWindowCompleter.complete();
            }
          },
        ),
      ),
    );

    await expectLater(onCloseWindowCompleter.future, completes);
  }, skip: shouldSkip);
}
