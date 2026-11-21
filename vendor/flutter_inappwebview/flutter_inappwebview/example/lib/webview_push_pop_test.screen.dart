import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class WebViewPushPopTestScreen extends StatelessWidget {
  const WebViewPushPopTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Push/Pop Test')),
      drawer: myDrawer(context: context),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WebViewPushPopChildScreen(),
              ),
            );
          },
          child: const Text('进入 WebView 页面'),
        ),
      ),
    );
  }
}

class WebViewPushPopChildScreen extends StatelessWidget {
  const WebViewPushPopChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView 子页'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InAppWebView(
        webViewEnvironment: webViewEnvironment,
        initialUrlRequest: URLRequest(url: WebUri('https://flutter.cn')),
        initialSettings: InAppWebViewSettings(isInspectable: kDebugMode),
      ),
    );
  }
}
