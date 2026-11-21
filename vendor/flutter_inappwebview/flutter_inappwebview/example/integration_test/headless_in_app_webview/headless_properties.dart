part of 'main.dart';

void headlessProperties() {
  final shouldSkip = kIsWeb
      ? false
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTest('id and webViewController', () async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();

    final headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: TEST_CROSS_PLATFORM_URL_1),
      onWebViewCreated: (controller) {
        controllerCompleter.complete(controller);
      },
      onLoadStop: (controller, url) {
        if (!pageLoaded.isCompleted) {
          pageLoaded.complete();
        }
      },
    );

    expect(headlessWebView.id, isNotEmpty);

    await headlessWebView.run();
    expect(headlessWebView.isRunning(), isTrue);

    final controller = headlessWebView.webViewController;
    expect(controller, isNotNull);
    expect(await controllerCompleter.future, same(controller));
    await pageLoaded.future;

    final String? url = (await controller!.getUrl())?.toString();
    expect(url, TEST_CROSS_PLATFORM_URL_1.toString());

    await headlessWebView.dispose();
    expect(headlessWebView.isRunning(), isFalse);
    expect(headlessWebView.webViewController, isNull);
  }, skip: shouldSkip);
}
