part of 'main.dart';

void keepAliveState() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets(
      'keepAlive preserves userScripts and javaScriptHandlers',
      (WidgetTester tester) async {
    final keepAlive = InAppWebViewKeepAlive();

    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<InAppWebViewController> controllerCompleter2 =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    final Completer<String> handlerCompleter = Completer<String>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          keepAlive: keepAlive,
          initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
          initialUserScripts: UnmodifiableListView<UserScript>([
            UserScript(
              source: 'window.keepAliveVar = 42;',
              injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
            ),
          ]),
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
              handlerName: 'keepAliveHandler',
              callback: (args) {
                if (!handlerCompleter.isCompleted) {
                  handlerCompleter.complete(args[0] as String);
                }
                return null;
              },
            );
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
    expect(await controller.evaluateJavascript(source: 'window.keepAliveVar;'),
        42);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          keepAlive: keepAlive,
          onWebViewCreated: (controller) {
            controllerCompleter2.complete(controller);
          },
        ),
      ),
    );

    final InAppWebViewController controller2 =
        await controllerCompleter2.future;
    expect(await controller2.evaluateJavascript(source: 'window.keepAliveVar;'),
        42);

    await controller2.evaluateJavascript(
        source:
            "window.flutter_inappwebview.callHandler('keepAliveHandler', 'ok');");
    expect(await handlerCompleter.future, 'ok');

    await expectLater(
        InAppWebViewController.disposeKeepAlive(keepAlive), completes);
  }, skip: shouldSkip);
}
