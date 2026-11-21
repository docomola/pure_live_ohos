import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'main.dart';

class PrintTestScreen extends StatefulWidget {
  @override
  _PrintTestScreenState createState() => _PrintTestScreenState();
}

class _PrintTestScreenState extends State<PrintTestScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  String url = "https://flutter.cn";
  double progress = 0;
  String statusMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Print Test"),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            tooltip: 'Print Current Page',
            onPressed: _printCurrentPage,
          ),
        ],
      ),
      drawer: myDrawer(context: context),
      body: Column(children: <Widget>[
        // URL bar
        TextField(
          decoration: InputDecoration(prefixIcon: Icon(Icons.search)),
          controller: TextEditingController(text: url),
          keyboardType: TextInputType.text,
          onSubmitted: (value) {
            var uri = WebUri(value);
            if (uri.scheme.isEmpty) {
              uri = WebUri("https://www.google.com/search?q=" + value);
            }
            webViewController?.loadUrl(urlRequest: URLRequest(url: uri));
          },
        ),
        // Progress bar
        if (progress < 1.0)
          LinearProgressIndicator(value: progress),
        // Status message
        if (statusMessage.isNotEmpty)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Text(statusMessage, style: TextStyle(fontSize: 12)),
          ),
        // WebView
        Expanded(
          child: InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(url)),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                this.url = url.toString();
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                this.url = url.toString();
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
            onPrintRequest: (controller, url, printJob) async {
              setState(() {
                statusMessage = "onPrintRequest fired!\nURL: $url\nPrintJob ID: ${printJob?.id}";
              });
              return true;
            },
          ),
        ),
      ]),
    );
  }

  /// Print with handledByClient = true (returns a PrintJobController)
  void _printCurrentPage() async {
    if (webViewController == null) return;

    setState(() {
      statusMessage = "Printing (handledByClient=true)...";
    });

    try {
      final printJob = await webViewController!.printCurrentPage(
        settings: PrintJobSettings(handledByClient: true),
      );

      setState(() {
        if (printJob != null) {
          statusMessage = "Print started!\nPrintJob ID: ${printJob.id}";
        } else {
          statusMessage = "printCurrentPage returned null";
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = "Print error: $e";
      });
    }
  }

}
