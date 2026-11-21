import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// Loads [assets/async_post_test.html] in an [InAppWebView].
///
/// The page defines the MDN-style async `post(url, data)` fetch method and a
/// button that calls `post('https://httpbin.org/post', { answer: 42 })`.
class AsyncPostTestScreen extends StatefulWidget {
  @override
  _AsyncPostTestScreenState createState() => _AsyncPostTestScreenState();
}

class _AsyncPostTestScreenState extends State<AsyncPostTestScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  double progress = 0;
  String statusMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Async POST (fetch) Test")),
      drawer: myDrawer(context: context),
      body: Column(children: <Widget>[
        if (progress < 1.0) LinearProgressIndicator(value: progress),
        if (statusMessage.isNotEmpty)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Text(statusMessage, style: TextStyle(fontSize: 12)),
          ),
        Expanded(
          child: InAppWebView(
            key: webViewKey,
            initialFile: "assets/async_post_test.html",
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccess: true,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStop: (controller, url) {
              setState(() {
                statusMessage = "Loaded: $url";
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('web console: $consoleMessage');
              setState(() {
                statusMessage = "console: ${consoleMessage.message}";
              });
            },
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame == false) return;
              setState(() {
                statusMessage =
                    "onReceivedError: ${request.url} | ${error.description}";
              });
            },
            shouldInterceptRequest: (controller, request) async {
              print("shouldInterceptRequest: ${request.url}");
              await Future.delayed(Duration(seconds: 3));
              return null;
            },
          ),
        ),
      ]),
    );
  }
}
