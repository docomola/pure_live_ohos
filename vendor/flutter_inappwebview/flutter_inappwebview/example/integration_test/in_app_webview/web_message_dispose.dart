part of 'main.dart';

void webMessageDispose() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets(
      'WebMessageChannel.dispose, WebMessagePort.close, WebMessageListener.dispose',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();

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

    final channel = await controller.createWebMessageChannel();
    expect(channel, isNotNull);
    await channel!.port1.close();
    channel.dispose();

    final listener = WebMessageListener(
      jsObjectName: 'disposeTestObj',
      allowedOriginRules: Set.from(['https://*.dispose.test']),
    );
    await controller.addWebMessageListener(listener);
    expect(controller.hasWebMessageListener(listener), isTrue);
    listener.dispose();
  }, skip: shouldSkip);
}
