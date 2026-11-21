part of 'main.dart';

void contentDimensions() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('getContentWidth, getHitTestResult, isInFullscreen',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();

    const html = '''
<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;">
    <div style="width:1200px;height:800px;">
      <a id="link" href="https://example.com">link</a>
    </div>
  </body>
</html>
''';

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 600,
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
      baseUrl: WebUri('https://dimensions.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    final contentWidth = await controller.getContentWidth();
    expect(contentWidth, isNotNull);
    expect(contentWidth!, greaterThan(0));

    expect(await controller.isInFullscreen(), isFalse);

    await controller.evaluateJavascript(
        source: "document.getElementById('link').click();");
    await Future.delayed(const Duration(milliseconds: 500));

    final hitTestResult = await controller.getHitTestResult();
    expect(hitTestResult, isA<InAppWebViewHitTestResult?>());
  }, skip: shouldSkip);
}
