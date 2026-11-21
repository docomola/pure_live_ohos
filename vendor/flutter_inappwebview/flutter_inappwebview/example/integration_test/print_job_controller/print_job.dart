part of 'main.dart';

void printJob() {
  skippableTestWidgets('cancel, restart, dismiss, getInfo, dispose, id, onComplete',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    final Completer<PrintJobController> printJobCompleter =
        Completer<PrintJobController>();
    final Completer<void> onCompleteCompleter = Completer<void>();

    const html = '''
<!DOCTYPE html>
<html>
  <body>
    <h1>Print Job Test</h1>
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
          onPrintRequest: (controller, url, printJobController) async {
            if (printJobController != null &&
                !printJobCompleter.isCompleted) {
              final printJob = PrintJobController.fromPlatform(
                  platform: printJobController);
              printJob.onComplete = (completed, error) async {
                if (!onCompleteCompleter.isCompleted) {
                  onCompleteCompleter.complete();
                }
              };
              printJobCompleter.complete(printJob);
            }
            return false;
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
      baseUrl: WebUri('https://printjob.test/'),
    );
    await Future.delayed(const Duration(seconds: 1));

    await controller.evaluateJavascript(source: "window.print();");

    final printJob = await printJobCompleter.future;
    expect(printJob.id, isNotEmpty);
    expect(printJob.onComplete, isNotNull);

    final info = await printJob.getInfo();
    expect(info, isA<PrintJobInfo?>());

    await expectLater(printJob.cancel(), completes);
    await expectLater(printJob.restart(), completes);
    await expectLater(printJob.dismiss(), completes);

    printJob.dispose();
  });
}
