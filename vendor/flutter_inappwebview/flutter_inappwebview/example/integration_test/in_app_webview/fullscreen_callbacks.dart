part of 'main.dart';

void fullscreenCallbacks() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableGroup('fullscreen callbacks', () {
    skippableTestWidgets('onEnterFullscreen, onExitFullscreen, isInFullscreen',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();
      final Completer<void> onEnterFullscreenCompleter = Completer<void>();
      final Completer<void> onExitFullscreenCompleter = Completer<void>();

      const html = '''
<!DOCTYPE html>
<html>
  <body>
    <button id="fs" onclick="document.body.requestFullscreen().catch(function(){})">
      fullscreen
    </button>
    <script>
      function exitFullscreen() {
        if (document.exitFullscreen) {
          document.exitFullscreen();
        }
      }
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
            },
            onLoadStop: (controller, url) {
              if (!pageLoaded.isCompleted) {
                pageLoaded.complete();
              }
            },
            onEnterFullscreen: (controller) {
              if (!onEnterFullscreenCompleter.isCompleted) {
                onEnterFullscreenCompleter.complete();
              }
            },
            onExitFullscreen: (controller) {
              if (!onExitFullscreenCompleter.isCompleted) {
                onExitFullscreenCompleter.complete();
              }
            },
          ),
        ),
      );

      final InAppWebViewController controller =
          await controllerCompleter.future;
      await pageLoaded.future;

      await controller.loadData(
        data: html,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://fullscreen.test/'),
      );
      await Future.delayed(const Duration(seconds: 1));

      expect(await controller.isInFullscreen(), isFalse);

      await controller.evaluateJavascript(
          source: "document.getElementById('fs').click();");
      await Future.delayed(const Duration(seconds: 1));

      if ([TargetPlatform.iOS, TargetPlatform.macOS]
          .contains(defaultTargetPlatform)) {
        await expectLater(onEnterFullscreenCompleter.future, completes);
        await controller.evaluateJavascript(source: "exitFullscreen();");
        await expectLater(onExitFullscreenCompleter.future, completes);
      }
    });
  }, skip: shouldSkip);
}
