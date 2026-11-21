part of 'main.dart';

void webViewAssetLoaderHandlers() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets(
      'AssetsPathHandler, ResourcesPathHandler, InternalStoragePathHandler path and type',
      (WidgetTester tester) async {
    final assetsHandler = AssetsPathHandler(path: '/assets/');
    final resourcesHandler = ResourcesPathHandler(path: '/res/');
    final internalHandler = InternalStoragePathHandler(
      path: '/internal/',
      directory: 'test_dir',
    );

    expect(assetsHandler.path, '/assets/');
    expect(assetsHandler.type, 'AssetsPathHandler');
    expect(resourcesHandler.path, '/res/');
    expect(resourcesHandler.type, 'ResourcesPathHandler');
    expect(internalHandler.path, '/internal/');
    expect(internalHandler.type, 'InternalStoragePathHandler');
    expect(internalHandler.directory, 'test_dir');

    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<String> pageLoaded = Completer<String>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialUrlRequest: URLRequest(url: TEST_WEBVIEW_ASSET_LOADER_URL),
          initialSettings: InAppWebViewSettings(
            allowFileAccessFromFileURLs: false,
            allowUniversalAccessFromFileURLs: false,
            allowFileAccess: false,
            allowContentAccess: false,
            webViewAssetLoader: WebViewAssetLoader(
              domain: TEST_WEBVIEW_ASSET_LOADER_DOMAIN,
              pathHandlers: [
                assetsHandler,
                resourcesHandler,
                internalHandler,
              ],
            ),
          ),
          onWebViewCreated: (controller) {
            controllerCompleter.complete(controller);
          },
          onLoadStop: (controller, url) {
            pageLoaded.complete(url.toString());
          },
        ),
      ),
    );

    final InAppWebViewController controller = await controllerCompleter.future;
    final url = await pageLoaded.future;
    expect(url, TEST_WEBVIEW_ASSET_LOADER_URL.toString());

    expect(
      await controller.evaluateJavascript(
          source: "document.querySelector('h1').innerHTML"),
      'WebViewAssetLoader',
    );
  }, skip: shouldSkip);
}
