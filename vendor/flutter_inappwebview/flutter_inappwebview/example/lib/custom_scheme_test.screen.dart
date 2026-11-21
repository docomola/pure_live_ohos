import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class CustomSchemeTestScreen extends StatefulWidget {
  @override
  _CustomSchemeTestScreenState createState() => _CustomSchemeTestScreenState();
}

class _CustomSchemeTestScreenState extends State<CustomSchemeTestScreen> {
  static const String _customSchemeName = 'my-special-custom-scheme';
  static const String _singleImageHtml =
      'test_assets/in_app_webview_on_load_resource_custom_scheme_test.html';

  InAppWebViewController? webViewController;
  int _webViewGeneration = 0;
  int _callbackCount = 0;
  bool _imageLoaded = false;

  final List<String> logs = [];
  final ScrollController logScrollController = ScrollController();

  bool? issueReproduced;
  Timer? _evaluateDebounceTimer;

  @override
  void dispose() {
    _evaluateDebounceTimer?.cancel();
    logScrollController.dispose();
    super.dispose();
  }

  void _scheduleEvaluateIssueState({
    String? reason,
    Duration delay = const Duration(milliseconds: 800),
  }) {
    _evaluateDebounceTimer?.cancel();
    _evaluateDebounceTimer = Timer(delay, () {
      if (mounted) {
        _evaluateIssueState(reason: reason);
      }
    });
  }

  void addLog(String message) {
    if (!mounted) return;
    setState(() {
      logs.add('[${DateTime.now().toString().substring(11, 23)}] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (logScrollController.hasClients) {
        logScrollController.animateTo(
          logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _resolveAssetPath(String rawPath) {
    var path = rawPath;
    if (path.startsWith('images/')) {
      path = 'test_assets/$path';
    }
    return path;
  }

  String _guessContentType(String assetPath) {
    final lower = assetPath.toLowerCase();
    if (lower.endsWith('.html') || lower.endsWith('.htm')) {
      return 'text/html';
    }
    if (lower.endsWith('.css')) {
      return 'text/css';
    }
    if (lower.endsWith('.js')) {
      return 'application/javascript';
    }
    if (lower.endsWith('.svg')) {
      return 'image/svg+xml';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.ico')) {
      return 'image/x-icon';
    }
    return 'application/octet-stream';
  }

  void _evaluateIssueState({String? reason}) {
    final reproduced = _callbackCount < 1 || !_imageLoaded;
    setState(() {
      issueReproduced = reproduced;
    });
    addLog(
      reproduced
          ? '>>> Issue #98 REPRODUCED (callbacks=$_callbackCount, imageLoaded=$_imageLoaded)'
          : '>>> OK: callbacks=$_callbackCount, imageLoaded=$_imageLoaded',
    );
    if (reason != null) {
      addLog(reason);
    }
  }

  Future<CustomSchemeResponse?> _onLoadResourceWithCustomScheme(
      InAppWebViewController controller, WebResourceRequest request) async {
    _callbackCount++;
    addLog(
        '[Issue#98] onLoadResourceWithCustomScheme #$_callbackCount: ${request.url}');

    if (request.url.scheme != _customSchemeName) {
      return null;
    }

    final assetPath =
        _resolveAssetPath(request.url.toString().replaceFirst(
              '$_customSchemeName://',
              '',
            ));
    
    try {
      final bytes = await rootBundle.load(assetPath);
      return CustomSchemeResponse(
        data: bytes.buffer.asUint8List(),
        contentType: _guessContentType(assetPath),
        contentEncoding: 'utf-8',
      );
    } catch (e) {
      addLog('ERROR loading $assetPath: $e');
      return null;
    } finally {
      _scheduleEvaluateIssueState(
        reason: 'After onLoadResourceWithCustomScheme #$_callbackCount',
      );
    }
  }

  Future<void> _resetTest() async {
    _evaluateDebounceTimer?.cancel();
    setState(() {
      _callbackCount = 0;
      _imageLoaded = false;
      issueReproduced = null;
      webViewController = null;
      _webViewGeneration++;
    });
    addLog('--- Resetting test ---');
  }

  String get _platformLabel {
    if (kIsWeb) return 'Web';
    return defaultTargetPlatform.name;
  }

  Widget _buildWebView() {
    return InAppWebView(
      key: ValueKey('issue98_singleImage_$_webViewGeneration'),
      initialFile: _singleImageHtml,
      initialSettings: InAppWebViewSettings(
        isInspectable: kDebugMode,
        javaScriptEnabled: true,
        clearCache: true,
        resourceCustomSchemes: [_customSchemeName],
      ),
      onWebViewCreated: (controller) {
        webViewController = controller;
        addLog('WebView created');
        addLog('Target: initialFile: $_singleImageHtml');

        controller.addJavaScriptHandler(
          handlerName: 'imageLoaded',
          callback: (args) {
            setState(() {
              _imageLoaded = true;
            });
            addLog('JS handler: imageLoaded');
            _evaluateIssueState();
          },
        );

        _scheduleEvaluateIssueState(
          reason: 'Fallback after WebView created',
          delay: const Duration(seconds: 4),
        );
      },
      onLoadStart: (controller, url) {
        addLog('onLoadStart: $url');
      },
      onLoadStop: (controller, url) async {
        addLog('onLoadStop: $url');
        _scheduleEvaluateIssueState(
          reason: 'Post-load check after onLoadStop',
          delay: const Duration(seconds: 1),
        );
      },
      onLoadResourceWithCustomScheme: _onLoadResourceWithCustomScheme,
      onReceivedError: (controller, request, error) {
        addLog('Error: ${error.description} url=${request.url}');
      },
      onConsoleMessage: (controller, consoleMessage) {
        addLog('Console: ${consoleMessage.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool? reproduced = issueReproduced;

    return Scaffold(
      drawer: myDrawer(context: context),
      appBar: AppBar(
        title: const Text('Issue #98 Custom Scheme'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _platformLabel,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetTest(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: reproduced == null
                ? Colors.grey.shade200
                : (reproduced ? Colors.red.shade100 : Colors.green.shade100),
            child: Row(
              children: [
                Icon(
                  reproduced == null
                      ? Icons.hourglass_empty
                      : (reproduced ? Icons.bug_report : Icons.check_circle),
                  color: reproduced == null
                      ? Colors.grey
                      : (reproduced ? Colors.red : Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reproduced == null
                        ? (_callbackCount > 0
                            ? '已收到 $_callbackCount 次回调，正在判定…'
                            : '等待 custom scheme 回调…')
                        : (reproduced
                            ? '已复现 Issue #98：回调 $_callbackCount 次（期望 ≥ 1）'
                            : '未复现：回调 $_callbackCount 次，图片加载 $_imageLoaded'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '当前模式: 单图测试',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SelectableText(
                  'initialFile: $_singleImageHtml',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildWebView(),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border(top: BorderSide(color: Colors.grey.shade700)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.grey.shade800,
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Debug Log',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${logs.length} messages',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: logScrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color textColor = Colors.green;
                      if (log.contains('ERROR') ||
                          log.contains('REPRODUCED') ||
                          log.contains('FAIL')) {
                        textColor = Colors.red;
                      } else if (log.contains('>>>')) {
                        textColor = Colors.cyan;
                      } else if (log.contains('[Issue#98]')) {
                        textColor = Colors.yellow;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
