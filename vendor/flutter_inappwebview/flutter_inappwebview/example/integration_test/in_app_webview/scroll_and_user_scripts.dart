part of 'main.dart';

void scrollAndUserScripts() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets(
      'canScrollVertically, canScrollHorizontally, addUserScript, removeUserScriptsByGroupName, hasWebMessageListener',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();

    const html = '''
<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;">
    <div style="height:5000px;width:5000px;">scrollable content</div>
  </body>
</html>
''';

    WebMessageListener? listener;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 400,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
            onWebViewCreated: (controller) async {
              listener = WebMessageListener(
                jsObjectName: 'scrollTestObj',
                allowedOriginRules: Set.from(['https://*.scroll.test']),
              );
              await controller.addWebMessageListener(listener!);
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

    expect(controller.hasWebMessageListener(listener!), isTrue);

    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://scroll.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    expect(await controller.canScrollVertically(), isTrue);
    expect(await controller.canScrollHorizontally(), isTrue);

    await controller.addUserScript(
      userScript: UserScript(
        source: 'window.groupA = 1;',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        groupName: 'groupA',
      ),
    );
    await controller.addUserScript(
      userScript: UserScript(
        source: 'window.groupB = 2;',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        groupName: 'groupB',
      ),
    );
    await controller.reload();
    await Future.delayed(const Duration(seconds: 1));

    expect(await controller.evaluateJavascript(source: 'window.groupA;'), 1);
    expect(await controller.evaluateJavascript(source: 'window.groupB;'), 2);

    await controller.removeUserScriptsByGroupName(groupName: 'groupA');
    await controller.reload();
    await Future.delayed(const Duration(seconds: 1));

    expect(await controller.evaluateJavascript(source: 'window.groupA;'), isNull);
    expect(await controller.evaluateJavascript(source: 'window.groupB;'), 2);

    listener!.dispose();
  }, skip: shouldSkip);
}
