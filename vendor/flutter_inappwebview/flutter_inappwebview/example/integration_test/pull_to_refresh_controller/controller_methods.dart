part of 'main.dart';

void controllerMethods() {
  skippableTestWidgets(
      'isEnabled, beginRefreshing, isRefreshing, setColor, setBackgroundColor, setDistanceToTriggerSync, setIndicatorSize, dispose',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    late PullToRefreshController pullToRefreshController;
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
        backgroundColor: Colors.grey,
        enabled: true,
        distanceToTriggerSync: 120,
        size: PullToRefreshSize.DEFAULT,
      ),
      onRefresh: () async {
        await pullToRefreshController.endRefreshing();
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
          pullToRefreshController: pullToRefreshController,
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

    await controllerCompleter.future;
    await pageLoaded.future;

    expect(await pullToRefreshController.isEnabled(), isTrue);

    await pullToRefreshController.setEnabled(false);
    expect(await pullToRefreshController.isEnabled(), isFalse);
    await pullToRefreshController.setEnabled(true);

    await pullToRefreshController.setColor(Colors.red);
    await pullToRefreshController.setBackgroundColor(Colors.white);
    await pullToRefreshController.setDistanceToTriggerSync(200);
    await pullToRefreshController.setIndicatorSize(PullToRefreshSize.LARGE);

    await pullToRefreshController.beginRefreshing();
    expect(await pullToRefreshController.isRefreshing(), isTrue);
    await pullToRefreshController.endRefreshing();
    expect(await pullToRefreshController.isRefreshing(), isFalse);

    pullToRefreshController.dispose();
  });
}
