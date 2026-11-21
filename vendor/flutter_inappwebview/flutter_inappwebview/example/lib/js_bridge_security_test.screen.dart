import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class JSBridgeSecurityTestScreen extends StatefulWidget {
  @override
  _JSBridgeSecurityTestScreenState createState() =>
      _JSBridgeSecurityTestScreenState();
}

class _JSBridgeSecurityTestScreenState
    extends State<JSBridgeSecurityTestScreen> {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings();
  List<String> testResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("_callHandlerID 来自 JS 侧安全测试")),
        drawer: myDrawer(context: context),
        body: SafeArea(
            child: Column(children: <Widget>[
          Expanded(
            child: InAppWebView(
              initialFile: "assets/js_bridge_security_test.html",
              initialSettings: settings,
              onWebViewCreated: (controller) async {
                webViewController = controller;
                controller.addJavaScriptHandler(
                    handlerName: 'securityTestHandler',
                    callback: (args) {
                      if (args.isNotEmpty) {
                        return 'echo:${args[0]}';
                      }
                      return 'echo:null';
                    });
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("[JSBridgeTest] ${consoleMessage.message}");
              },
            ),
          ),
        ])));
  }
}
