part of 'main.dart';

void listenerPostMessage() {
  skippableTestWidgets('WebMessageListener post String',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    final Completer<String> webMessageCompleter = Completer<String>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          onWebViewCreated: (controller) async {
            await controller.addWebMessageListener(WebMessageListener(
              jsObjectName: "myTestObj",
              allowedOriginRules: Set.from(["https://*.example.com"]),
              onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
                if (isMainFrame &&
                    (sourceOrigin.toString() + '/') ==
                        TEST_URL_EXAMPLE.toString()) {
                  replyProxy.postMessage(
                      WebMessage(data: message!.data + " and back"));
                } else {
                  replyProxy.postMessage(WebMessage(data: "Nope"));
                }
              },
            ));
            controllerCompleter.complete(controller);
          },
          onConsoleMessage: (controller, consoleMessage) {
            webMessageCompleter.complete(consoleMessage.message);
          },
          onLoadStop: (controller, url) async {
            if (url.toString() == TEST_URL_EXAMPLE.toString()) {
              pageLoaded.complete();
            }
          },
        ),
      ),
    );
    final controller = await controllerCompleter.future;
    await controller.loadUrl(urlRequest: URLRequest(url: TEST_URL_EXAMPLE));
    await pageLoaded.future;

    await controller.evaluateJavascript(source: """
        myTestObj.addEventListener('message', function(event) {
          console.log(event.data);
        });
        myTestObj.postMessage('JavaScript To Native');
      """);

    final String message = await webMessageCompleter.future;
    expect(message, 'JavaScript To Native and back');
  });

  skippableTestWidgets('WebMessageListener post ArrayBuffer',
      (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<void> pageLoaded = Completer<void>();
    final Completer<String> webMessageCompleter = Completer<String>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          onWebViewCreated: (controller) async {
            await controller.addWebMessageListener(WebMessageListener(
              jsObjectName: "myTestObj",
              allowedOriginRules: Set.from(["https://*.example.com"]),
              onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
                if (isMainFrame &&
                    (sourceOrigin.toString() + '/') ==
                        TEST_URL_EXAMPLE.toString()) {
                  replyProxy.postMessage(WebMessage(
                      data: utf8
                          .encode(utf8.decode(message!.data) + " and back"),
                      type: WebMessageType.ARRAY_BUFFER));
                } else {
                  replyProxy.postMessage(WebMessage(
                      data: utf8.encode("Nope"),
                      type: WebMessageType.ARRAY_BUFFER));
                }
              },
            ));
            controllerCompleter.complete(controller);
          },
          onConsoleMessage: (controller, consoleMessage) {
            webMessageCompleter.complete(consoleMessage.message);
          },
          onLoadStop: (controller, url) async {
            if (url.toString() == TEST_URL_EXAMPLE.toString()) {
              pageLoaded.complete();
            }
          },
        ),
      ),
    );
    final controller = await controllerCompleter.future;
    await controller.loadUrl(urlRequest: URLRequest(url: TEST_URL_EXAMPLE));
    await pageLoaded.future;

    await controller.evaluateJavascript(source: """
        function bufferToString(buffer) {
            if (typeof buffer === 'string') {
                return buffer;
            }
            return String.fromCharCode.apply(null, Array.from(new Uint8Array(buffer)));
        }
        
        function stringToBuffer(value) {
            var buffer = new ArrayBuffer(value.length);
            var view = new Uint8Array(buffer);
            for (var i = 0, length = value.length; i < length; i++) {
                view[i] = value.charCodeAt(i);
            }
            return buffer;
        }

        function normalizeMessageData(data) {
            if (window.ArrayBuffer != null && data instanceof ArrayBuffer) {
                return bufferToString(data);
            }
            if (Array.isArray(data) && data.length > 0 && typeof data[0] === 'number') {
                return bufferToString(new Uint8Array(data).buffer);
            }
            return data != null ? data.toString() : null;
        }
        
        myTestObj.addEventListener('message', function(event) {
          console.log(normalizeMessageData(event.data));
        });
        myTestObj.postMessage(stringToBuffer('JavaScript To Native'));
      """);

    final String message = await webMessageCompleter.future;
    expect(message, 'JavaScript To Native and back');
  });
}
