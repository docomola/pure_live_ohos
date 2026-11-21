part of 'main.dart';

void overscrollCallbacks() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('onOverScrolled', (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    final Completer<void> onOverScrolledCompleter = Completer<void>();

    const html = '''
<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;">
    <div style="height:5000px;width:100%;">tall content</div>
  </body>
</html>
''';

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 400,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
            onWebViewCreated: (controller) {
              controllerCompleter.complete(controller);
            },
            onLoadStop: (controller, url) {
              if (!pageLoaded.isCompleted) {
                pageLoaded.complete();
              }
            },
            onOverScrolled: (controller, x, y, clampedX, clampedY) {
              if (!onOverScrolledCompleter.isCompleted && y > 0) {
                onOverScrolledCompleter.complete();
              }
            },
          ),
        ),
      ),
    );

    final InAppWebViewController controller = await controllerCompleter.future;
    await pageLoaded.future;

    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://overscroll.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    await controller.scrollTo(x: 0, y: 4500);
    await expectLater(onOverScrolledCompleter.future, completes);
  }, skip: shouldSkip);
}
