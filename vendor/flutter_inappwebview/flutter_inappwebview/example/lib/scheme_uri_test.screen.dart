import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// Manual test for uri.URI + regex scheme parsing in InAppWebViewClient.ets.
class SchemeUriTestScreen extends StatefulWidget {
  @override
  State<SchemeUriTestScreen> createState() => _SchemeUriTestScreenState();
}

class _SchemeUriTestScreenState extends State<SchemeUriTestScreen> {
  static const String _testDescription = '''
测试步骤：
1. 进入测试页，确认 Flutter 回调计数为 0（无自动加载干扰）。
2. 点击「合法scheme 资源」，注入：
   my-special-custom-scheme://images/flutter-logo.svg
3. 点击「畸形 URL：URI 解析失败」，注入：
   my-special-custom-scheme（无 :）
4. （可选）点击「对照：scheme 可解析但无数据」，注入：
   my-special-custom-scheme:<<<invalid>>>
5. 需重新测试时，先点击「重置计数/日志」。

预期结果：
合法 scheme://...：Flutter 回调 +1，返回资源，图片加载成功。
畸形 URL（无 :）：Flutter 回调不增加，不进入 custom scheme 处理。
对照无数据：Flutter 回调 +1，不返回资源，图片不加载。
重复点击同一 URL：每次点击会加 ?_cb= 防缓存。

实际结果：（测试时填写）
合法 scheme://...：
畸形 URL（无 :）：

说明：原生层优先 uri.URI(url).scheme；失败时用
/^([a-zA-Z][a-zA-Z0-9+.-]*):/ 提取 scheme，不使用 split 回退。
''';

  static const String _testScheme = 'my-special-custom-scheme';
  static const String _validSchemeUrl =
      '$_testScheme://images/flutter-logo.svg';
  static const String _malformedSchemeUrl = _testScheme;
  static const String _noDataSchemeUrl = '$_testScheme:<<<invalid>>>';

  static const String _initialHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: sans-serif; text-align: center; margin: 12px; }
    #scheme-uri-image { max-width: 100%; max-height: 160px; border: 1px dashed #aaa; }
    .hint { color: #666; font-size: 13px; }
  </style>
</head>
<body>
  <p class="hint">点击下方测试按钮加载 custom scheme 图片</p>
  <img id="scheme-uri-image" alt="scheme uri.URI 解析 test image">
</body>
</html>
''';

  InAppWebViewController? _webViewController;
  int _webViewGeneration = 0;
  int _flutterCallbackCount = 0;
  int _returnedResourceCount = 0;
  bool _imageLoaded = false;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 23)}] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _urlWithCacheBust(String baseUrl) {
    final sep = baseUrl.contains('?') ? '&' : '?';
    return '$baseUrl${sep}_cb=${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _assetPathFromCustomSchemeUrl(String url) {
    const prefix = '$_testScheme://';
    if (!url.startsWith(prefix)) {
      return null;
    }
    var path = url.substring(prefix.length);
    final query = path.indexOf('?');
    if (query >= 0) {
      path = path.substring(0, query);
    }
    final hash = path.indexOf('#');
    if (hash >= 0) {
      path = path.substring(0, hash);
    }
    return path.isEmpty ? null : path;
  }

  Future<CustomSchemeResponse?> _onLoadResourceWithCustomScheme(
    InAppWebViewController controller,
    WebResourceRequest request,
  ) async {
    setState(() => _flutterCallbackCount++);
    final url = request.url.toString();
    _log(
      'Flutter 回调 #$_flutterCallbackCount: $url\n'
      '  request.url.scheme=${request.url.scheme}',
    );

    if (request.url.scheme != _testScheme) {
      _log('  跳过: 非 $_testScheme scheme');
      return null;
    }

    final relativePath = _assetPathFromCustomSchemeUrl(url);
    if (relativePath == null) {
      _log('  对照用例: scheme 可解析，返回 null（非 scheme:// 形态）');
      return null;
    }

    final assetPath = 'test_assets/$relativePath';
    try {
      final bytes = await rootBundle.load(assetPath);
      setState(() => _returnedResourceCount++);
      _log(
        '  已返回资源 #$_returnedResourceCount: $assetPath '
        '(${bytes.lengthInBytes} bytes)',
      );
      return CustomSchemeResponse(
        data: bytes.buffer.asUint8List(),
        contentType: 'image/svg+xml',
        contentEncoding: 'utf-8',
      );
    } catch (e) {
      _log('  ERROR 加载资源 $assetPath: $e');
      return null;
    }
  }

  Future<void> _loadImage(String imageUrl, {required String label}) async {
    final controller = _webViewController;
    if (controller == null) {
      _log('WebView 未就绪，请稍候');
      return;
    }
    final url = _urlWithCacheBust(imageUrl);
    setState(() => _imageLoaded = false);
    _log('>>> $label');
    _log('  请求 URL: $url');
    await controller.evaluateJavascript(source: '''
      (function() {
        var url = ${jsonEncode(url)};
        var oldImg = document.getElementById('scheme-uri-image');
        var img = document.createElement('img');
        img.id = 'scheme-uri-image';
        img.alt = 'scheme uri.URI 解析 test image';
        img.style.maxWidth = '100%';
        img.style.maxHeight = '160px';
        if (oldImg && oldImg.parentNode) {
          oldImg.parentNode.replaceChild(img, oldImg);
        }
        img.onload = function() {
          window.flutter_inappwebview.callHandler('schemeUriImageLoaded');
        };
        img.onerror = function() {
          window.flutter_inappwebview.callHandler('schemeUriImageError');
        };
        img.src = url;
      })();
    ''');
  }

  Future<void> _testValidSchemeResource() async {
    await _loadImage(_validSchemeUrl, label: '测试: 合法 scheme 资源');
  }

  Future<void> _testMalformedNoColon() async {
    await _loadImage(
      _malformedSchemeUrl,
      label: '测试: 畸形 URL：URI 解析失败',
    );
  }

  Future<void> _testParseableNoData() async {
    await _loadImage(
      _noDataSchemeUrl,
      label: '对照: scheme 可解析但无数据',
    );
  }

  Future<void> _resetCountersAndLogs() async {
    setState(() {
      _flutterCallbackCount = 0;
      _returnedResourceCount = 0;
      _imageLoaded = false;
      _logs.clear();
    });
    _log('--- 已重置计数与日志 ---');
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _testValidSchemeResource(),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('合法 scheme 资源'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => _testMalformedNoColon(),
          icon: const Icon(Icons.gpp_bad_outlined),
          label: const Text('畸形 URL：URI 解析失败'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _testParseableNoData(),
          icon: const Icon(Icons.warning_amber_outlined),
          label: const Text('对照：scheme 可解析但无数据'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _resetCountersAndLogs(),
          icon: const Icon(Icons.clear_all),
          label: const Text('重置计数 / 日志'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageStatus = _imageLoaded ? '已加载' : '未加载';

    return Scaffold(
      appBar: AppBar(
        title: const Text('scheme 测试'),
      ),
      drawer: myDrawer(context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'scheme 测试说明',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                '平台: $defaultTargetPlatform',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              initiallyExpanded: false,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _testDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flutter 回调次数：$_flutterCallbackCount',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('已返回资源次数：$_returnedResourceCount'),
                Text('WebView图片：$imageStatus'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: _buildActionButtons(),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InAppWebView(
                    key: ValueKey('scheme_uri_webview_$_webViewGeneration'),
                    initialData: InAppWebViewInitialData(
                      data: _initialHtml,
                      baseUrl: WebUri('https://sec004.test/'),
                    ),
                    initialSettings: InAppWebViewSettings(
                      isInspectable: kDebugMode,
                      javaScriptEnabled: true,
                      clearCache: true,
                      resourceCustomSchemes: [_testScheme],
                      useShouldInterceptRequest: false,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      _log('WebView 已创建，scheme=$_testScheme');

                      controller.addJavaScriptHandler(
                        handlerName: 'schemeUriImageLoaded',
                        callback: (args) {
                          setState(() => _imageLoaded = true);
                          _log('WebView 图片 onload 触发');
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'schemeUriImageError',
                        callback: (args) {
                          setState(() => _imageLoaded = false);
                          _log('WebView 图片 onerror 触发');
                        },
                      );
                    },
                    onLoadResourceWithCustomScheme: _onLoadResourceWithCustomScheme,
                    onReceivedError: (controller, request, error) {
                      _log(
                        'onReceivedError: ${error.description} url=${request.url}',
                      );
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      _log('Console: ${consoleMessage.message}');
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '测试日志',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border(top: BorderSide(color: Colors.grey.shade700)),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        '点击上方按钮开始 SEC-004 scheme 测试。',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.green;
                        if (log.contains('ERROR') || log.contains('onerror')) {
                          textColor = Colors.red;
                        } else if (log.contains('>>>')) {
                          textColor = Colors.cyan;
                        } else if (log.contains('回调')) {
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
          ),
        ],
      ),
    );
  }
}
