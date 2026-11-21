part of 'main.dart';

void geolocationPermissions() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('onGeolocationPermissionsShowPrompt',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    final Completer<String> geolocationCompleter = Completer<String>();

    const html = '''
<!DOCTYPE html>
<html>
  <body>
    <script>
      navigator.geolocation.getCurrentPosition(
        function() {},
        function() {}
      );
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
          onGeolocationPermissionsShowPrompt: (controller, origin) async {
            if (!geolocationCompleter.isCompleted) {
              geolocationCompleter.complete(origin);
            }
            return GeolocationPermissionShowPromptResponse(
                origin: origin, allow: true, retain: true);
          },
        ),
      ),
    );

    final InAppWebViewController controller = await controllerCompleter.future;
    await pageLoaded.future;

    await controller.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://geolocation.test/'),
    );

    final origin = await geolocationCompleter.future;
    expect(origin, isNotEmpty);
  }, skip: shouldSkip);
}
