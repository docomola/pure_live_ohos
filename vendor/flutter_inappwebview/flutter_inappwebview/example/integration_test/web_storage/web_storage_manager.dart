part of 'main.dart';

void webStorageManager() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableGroup('WebStorageManager', () {
    WebStorageManager? webStorageManager;

    setUp(() {
      webStorageManager = WebStorageManager.instance();
    });

    final shouldSkipAndroid = kIsWeb
        ? true
        : ![
            TargetPlatform.android,
            TargetPlatform.ohos,
          ].contains(defaultTargetPlatform);

    skippableTestWidgets('getOrigins, deleteOrigin, quota and usage',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      const html = '''
<!DOCTYPE html>
<html>
  <body>
    <script>
      localStorage.setItem('managerTest', 'value');
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
        baseUrl: WebUri('https://manager.test/'),
      );
      await Future.delayed(const Duration(seconds: 1));

      final origins = await webStorageManager!.getOrigins();
      expect(origins, isNotEmpty);

      final origin = origins.first.origin;
      expect(origin, isNotNull);
      expect(await webStorageManager!.getQuotaForOrigin(origin: origin!),
          greaterThanOrEqualTo(0));
      expect(await webStorageManager!.getUsageForOrigin(origin: origin),
          greaterThanOrEqualTo(0));

      await webStorageManager!.deleteOrigin(origin: origin);
      final originsAfterDelete = await webStorageManager!.getOrigins();
      expect(
          originsAfterDelete
              .where((element) => element.origin == origin)
              .isEmpty,
          isTrue);

      await webStorageManager!.deleteAllData();
    }, skip: shouldSkipAndroid);

    final shouldSkipApple = kIsWeb
        ? true
        : ![
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ].contains(defaultTargetPlatform);

    skippableTestWidgets(
        'fetchDataRecords, removeDataFor, removeDataModifiedSince',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      const html = '''
<!DOCTYPE html>
<html>
  <body>
    <script>
      localStorage.setItem('appleManagerTest', 'value');
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
        baseUrl: WebUri('https://applemanager.test/'),
      );
      await Future.delayed(const Duration(seconds: 1));

      final dataTypes = {WebsiteDataType.WKWebsiteDataTypeLocalStorage};
      final records =
          await webStorageManager!.fetchDataRecords(dataTypes: dataTypes);
      expect(records, isNotEmpty);

      await webStorageManager!
          .removeDataFor(dataTypes: dataTypes, dataRecords: records);

      final recordsAfterRemove =
          await webStorageManager!.fetchDataRecords(dataTypes: dataTypes);
      expect(recordsAfterRemove, isEmpty);

      await controller.loadData(
        data: html,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('https://applemanager2.test/'),
      );
      await Future.delayed(const Duration(seconds: 1));

      await webStorageManager!.removeDataModifiedSince(
          dataTypes: dataTypes, date: DateTime.now());
    }, skip: shouldSkipApple);
  }, skip: shouldSkip);
}
