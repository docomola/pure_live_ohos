part of 'main.dart';

void navigationHistory() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('goBackOrForward, canGoBackOrForward, goTo',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();

    const page1 = '''
<!DOCTYPE html>
<html><body><h1>Page 1</h1></body></html>
''';
    const page2 = '''
<!DOCTYPE html>
<html><body><h1>Page 2</h1></body></html>
''';

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
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
    );

    final InAppWebViewController controller = await controllerCompleter.future;
    await pageLoaded.future;

    await controller.loadData(
      data: page1,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://history1.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    await controller.loadData(
      data: page2,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://history2.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    expect(await controller.canGoBack(), isTrue);
    expect(await controller.canGoBackOrForward(steps: -1), isTrue);
    expect(await controller.canGoBackOrForward(steps: 1), isFalse);

    await controller.goBackOrForward(steps: -1);
    await Future.delayed(const Duration(seconds: 1));

    var webHistory = await controller.getCopyBackForwardList();
    expect(webHistory!.currentIndex, 0);

    await controller.goBackOrForward(steps: 1);
    await Future.delayed(const Duration(seconds: 1));
    expect((await controller.getUrl()).toString(),
        contains('https://history2.test/'));

    webHistory = await controller.getCopyBackForwardList();
    await controller.goTo(historyItem: webHistory!.list![0]);
    await Future.delayed(const Duration(seconds: 1));
    expect((await controller.getUrl()).toString(),
        contains('https://history1.test/'));
  }, skip: shouldSkip);
}
