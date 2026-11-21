part of 'main.dart';

void localSessionStorage() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableGroup('Local and Session Storage', () {
    skippableTestWidgets('webStorage localStorage and sessionStorage APIs',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      const html = '''
<!DOCTYPE html>
<html>
  <body>
    <div id="test">web-storage</div>
    <script>
      localStorage.setItem('jsLocal', 'jsLocalValue');
      sessionStorage.setItem('jsSession', 'jsSessionValue');
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

      final InAppWebViewController controller =
          await controllerCompleter.future;
      await pageLoaded.future;

      await controller.loadData(
        data: html,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://webstorage.test/'),
      );
      await Future.delayed(const Duration(seconds: 1));

      final webStorage = controller.webStorage;
      final localStorage = webStorage.localStorage;
      final sessionStorage = webStorage.sessionStorage;

      expect(await localStorage.getItem(key: 'jsLocal'), 'jsLocalValue');
      expect(await sessionStorage.getItem(key: 'jsSession'), 'jsSessionValue');

      await localStorage.setItem(key: 'flutterLocal', value: 'localValue');
      await sessionStorage.setItem(key: 'flutterSession', value: 'sessionValue');

      expect(await localStorage.length(), greaterThanOrEqualTo(2));
      expect(await sessionStorage.length(), greaterThanOrEqualTo(2));

      final localItems = await localStorage.getItems();
      expect(localItems.any((item) => item.key == 'flutterLocal'), isTrue);

      final firstKey = await localStorage.key(index: 0);
      expect(firstKey, isNotEmpty);

      expect(
          await controller.evaluateJavascript(
              source: "localStorage.getItem('flutterLocal');"),
          'localValue');
      expect(
          await controller.evaluateJavascript(
              source: "sessionStorage.getItem('flutterSession');"),
          'sessionValue');

      await localStorage.removeItem(key: 'flutterLocal');
      expect(await localStorage.getItem(key: 'flutterLocal'), isNull);

      await sessionStorage.setItem(key: 'tmp1', value: '1');
      await sessionStorage.setItem(key: 'tmp2', value: '2');
      await sessionStorage.clear();
      expect(await sessionStorage.length(), 0);

      localStorage.dispose();
      sessionStorage.dispose();
      webStorage.dispose();
    });
  }, skip: shouldSkip);
}
