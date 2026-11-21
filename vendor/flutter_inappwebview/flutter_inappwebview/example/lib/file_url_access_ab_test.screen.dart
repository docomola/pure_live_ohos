import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';

class FileUrlAccessABTestScreen extends StatefulWidget {
  @override
  _FileUrlAccessABTestScreenState createState() =>
      _FileUrlAccessABTestScreenState();
}

class _FileUrlAccessABTestScreenState extends State<FileUrlAccessABTestScreen> {
  bool _allowFileAccessFromFileURLs = true;
  String _status = "Preparing test files...";
  String? _imagePath;
  String? _imageFileUrl;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _prepareTestFiles();
  }

  Future<void> _prepareTestFiles() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final flutterCacheDir = Directory('${cacheDir.path}/flutter');
      if (!flutterCacheDir.existsSync()) {
        flutterCacheDir.createSync(recursive: true);
      }
      final pngFile = File('${flutterCacheDir.path}/test_png.png');
      await pngFile.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR42mP8z8BQDwAFgwJ/l8L3QwAAAABJRU5ErkJggg==',
        ),
        flush: true,
      );

      _imagePath = pngFile.path;
      _imageFileUrl = pngFile.uri.toString();

      if (!mounted) return;
      setState(() {
        _isReady = true;
        _status = "Ready. Loading assets/test.html ...";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = "Prepare failed: $e";
      });
    }
  }

  Future<void> _injectFileUrlImage(InAppWebViewController controller) async {
    if (_imageFileUrl == null) return;
    final imageFileUrl = jsonEncode(_imageFileUrl);
    final allow = jsonEncode(_allowFileAccessFromFileURLs.toString());
    await controller.evaluateJavascript(source: '''
window.setFileUrlAccessTestImage && window.setFileUrlAccessTestImage($imageFileUrl, $allow);
''');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        appBar: AppBar(title: Text("File URL Access A/B Test")),
        drawer: myDrawer(context: context),
        body: Center(child: Text(_status)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("File URL Access A/B Test")),
      drawer: myDrawer(context: context),
      body: Column(
        children: <Widget>[
          SwitchListTile(
            title: Text("allowFileAccessFromFileURLs"),
            subtitle: Text(
              '$_allowFileAccessFromFileURLs\nasset: assets/test.html\nimage: $_imagePath',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            value: _allowFileAccessFromFileURLs,
            onChanged: (bool value) {
              setState(() {
                _allowFileAccessFromFileURLs = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(_status, style: TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: InAppWebView(
              key: ValueKey<bool>(_allowFileAccessFromFileURLs),
              initialFile: "assets/test.html",
              initialSettings: InAppWebViewSettings(
                allowFileAccess: true,
                allowFileAccessFromFileURLs: _allowFileAccessFromFileURLs,
                javaScriptEnabled: true,
                loadsImagesAutomatically: true,
              ),
              onLoadStop: (controller, url) async {
                await _injectFileUrlImage(controller);
                setState(() {
                  _status = "onLoadStop: $url";
                });
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame == false) {
                  return;
                }
                setState(() {
                  _status =
                      "onReceivedError: ${request.url} | ${error.description}";
                });
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('web console: $consoleMessage');
                setState(() {
                  _status = "console: ${consoleMessage.message}";
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
