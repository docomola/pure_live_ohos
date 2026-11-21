part of 'main.dart';

void getAllCookies() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets('getAllCookies and deleteCookie by domain',
      (WidgetTester tester) async {
    CookieManager cookieManager = CookieManager.instance();
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<String> pageLoaded = Completer<String>();

    var headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: TEST_CROSS_PLATFORM_URL_1),
      onWebViewCreated: (controller) {
        controllerCompleter.complete(controller);
      },
      onLoadStop: (controller, url) {
        pageLoaded.complete(url!.toString());
      },
    );

    await headlessWebView.run();

    final url = WebUri(await pageLoaded.future);

    await cookieManager.setCookie(
        url: url, name: "allCookiesTest", value: "cookieValue");
    final allCookies = await cookieManager.getAllCookies();
    expect(allCookies.any((cookie) => cookie.name == "allCookiesTest"), isTrue);

    expect(
        await cookieManager.deleteCookie(
            url: url,
            name: "allCookiesTest",
            domain: ".${TEST_CROSS_PLATFORM_URL_1.host}"),
        isTrue);
    final cookiesAfterDelete = await cookieManager.getAllCookies();
    expect(
        cookiesAfterDelete.any((cookie) => cookie.name == "allCookiesTest"),
        isFalse);

    await cookieManager.deleteAllCookies();
    headlessWebView.dispose();
  }, skip: shouldSkip);
}
