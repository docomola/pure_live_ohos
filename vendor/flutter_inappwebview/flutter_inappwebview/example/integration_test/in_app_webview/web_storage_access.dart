part of 'main.dart';

void webStorageAccess() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('controller.webStorage getter', (WidgetTester tester) async {
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

    final webStorage = controller.webStorage;
    expect(webStorage.localStorage, isA<LocalStorage>());
    expect(webStorage.sessionStorage, isA<SessionStorage>());

    await webStorage.localStorage.setItem(key: 'accessTest', value: 'value');
    expect(await webStorage.localStorage.getItem(key: 'accessTest'), 'value');

    webStorage.dispose();
  }, skip: shouldSkip);
}
