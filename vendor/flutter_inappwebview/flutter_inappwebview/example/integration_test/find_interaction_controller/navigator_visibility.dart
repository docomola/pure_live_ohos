part of 'main.dart';

void navigatorVisibility() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets(
      'isFindNavigatorVisible, presentFindNavigator, dismissFindNavigator',
      (WidgetTester tester) async {
    final Completer<void> pageLoaded = Completer<void>();
    final findInteractionController = FindInteractionController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialFile: "test_assets/in_app_webview_initial_file_test.html",
          findInteractionController: findInteractionController,
          initialSettings: InAppWebViewSettings(
              clearCache: true, isFindInteractionEnabled: true),
          onLoadStop: (controller, url) {
            pageLoaded.complete();
          },
        ),
      ),
    );

    await pageLoaded.future;
    await tester.pump();
    await Future.delayed(const Duration(seconds: 1));

    const searchText = "text";
    await findInteractionController.setSearchText(searchText);
    await findInteractionController.presentFindNavigator();
    expect(await findInteractionController.getSearchText(), searchText);
    expect(await findInteractionController.isFindNavigatorVisible(), isTrue);

    await findInteractionController.dismissFindNavigator();
    expect(await findInteractionController.isFindNavigatorVisible(), isFalse);
  }, skip: shouldSkip);
}
