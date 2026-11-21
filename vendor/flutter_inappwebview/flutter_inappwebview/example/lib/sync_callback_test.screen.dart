import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

enum _WebViewProfile { syncIntercept, customScheme, assetLoader }

/// Manual tests for [SyncBaseCallbackResultImpl] on OpenHarmony (T006).
class SyncCallbackTestScreen extends StatefulWidget {
  @override
  State<SyncCallbackTestScreen> createState() => _SyncCallbackTestScreenState();
}

class _SyncCallbackTestScreenState extends State<SyncCallbackTestScreen> {
  static const String _customScheme = 'my-special-custom-scheme';
  static const String _assetLoaderDomain = 'my.custom.domain.com';
  static final WebUri _assetLoaderUrl = WebUri(
    'https://$_assetLoaderDomain/assets/flutter_assets/test_assets/website/index.html',
  );

  static final Uint8List _inlineSvgBytes = Uint8List.fromList(utf8.encode('''
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <rect width="48" height="48" fill="#54C5F8"/>
  <text x="24" y="30" text-anchor="middle" font-size="12" fill="white">OK</text>
</svg>
'''));

  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;

  _WebViewProfile _profile = _WebViewProfile.syncIntercept;
  int _interceptDelayMs = 2000;
  int _interceptCallCount = 0;
  int _customSchemeCallCount = 0;

  final List<String> _logs = [];

  static const bool _autoRun =
      bool.fromEnvironment('T006_AUTO_RUN', defaultValue: false);

  @override
  void initState() {
    super.initState();
    if (_autoRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runAllTests());
    }
  }

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 23)} $message');
    });
    debugPrint('[T006] $message');
  }

  Future<void> _switchProfile(_WebViewProfile profile) async {
    if (_profile == profile) return;
    setState(() {
      _profile = profile;
      _webViewController = null;
      _interceptCallCount = 0;
      _customSchemeCallCount = 0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _runCase({
    required String title,
    required Future<void> Function() action,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _log('开始 — $title');
    final stopwatch = Stopwatch()..start();
    try {
      await action().timeout(timeout);
      _log('PASS — $title (${stopwatch.elapsedMilliseconds} ms)');
    } on TimeoutException {
      _log('FAIL — $title 超时 (>${timeout.inSeconds}s)，可能存在无限等待');
    } catch (e) {
      _log('FAIL — $title\n  异常: $e');
    }
  }

  Future<void> _waitForPageLoad({Duration timeout = const Duration(seconds: 15)}) async {
    for (var i = 0; i < timeout.inMilliseconds ~/ 100; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final progress = await _webViewController?.getProgress();
      if (progress == 100) return;
    }
    throw TimeoutException('页面加载超时');
  }

  Future<void> _testShouldInterceptRequest({required int delayMs}) async {
    await _switchProfile(_WebViewProfile.syncIntercept);
    _interceptCallCount = 0;
    setState(() => _interceptDelayMs = delayMs);

    final stopwatch = Stopwatch()..start();
    await _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://www.example.com/')),
    );
    await _waitForPageLoad();

    if (_interceptCallCount < 1) {
      throw StateError('未触发 shouldInterceptRequest');
    }
    if (stopwatch.elapsedMilliseconds < delayMs) {
      throw StateError(
        '等待时间过短: ${stopwatch.elapsedMilliseconds}ms < ${delayMs}ms',
      );
    }
    _log('  拦截回调 $_interceptCallCount 次, 耗时 ${stopwatch.elapsedMilliseconds}ms');
  }

  Future<void> _testCustomScheme() async {
    await _switchProfile(_WebViewProfile.customScheme);
    _customSchemeCallCount = 0;
    final imageLoaded = Completer<void>();

    _webViewController?.addJavaScriptHandler(
      handlerName: 'imageLoaded',
      callback: (args) {
        if (!imageLoaded.isCompleted) imageLoaded.complete();
      },
    );

    await _webViewController?.loadFile(
      assetFilePath: 'test_assets/in_app_webview_on_load_resource_custom_scheme_test.html',
    );

    await imageLoaded.future.timeout(const Duration(seconds: 12));
    if (_customSchemeCallCount < 1) {
      throw StateError('onLoadResourceWithCustomScheme 未被触发');
    }
    _log('  onLoadResourceWithCustomScheme 回调 $_customSchemeCallCount 次');
  }

  Future<void> _testWebViewAssetLoader() async {
    await _switchProfile(_WebViewProfile.assetLoader);

    await _webViewController?.loadUrl(urlRequest: URLRequest(url: _assetLoaderUrl));
    await _waitForPageLoad();

    final title = await _webViewController?.evaluateJavascript(
      source: "document.querySelector('h1')?.innerHTML",
    );
    if (title != 'WebViewAssetLoader') {
      throw StateError('页面标题不符: $title');
    }
    _log('  WebViewAssetLoader 页面标题: $title');
  }

  Future<void> _testStressReload() async {
    await _switchProfile(_WebViewProfile.syncIntercept);
    setState(() => _interceptDelayMs = 500);

    const rounds = 5;
    for (var i = 0; i < rounds; i++) {
      _interceptCallCount = 0;
      if (i == 0) {
        await _webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri('https://www.example.com/')),
        );
      } else {
        await _webViewController?.reload();
      }
      await _waitForPageLoad();
      _log('  压力刷新 ${i + 1}/$rounds 完成, intercept=$_interceptCallCount');
    }
  }

  Future<void> _runAllTests() async {
    setState(() => _logs.clear());
    _log('开始运行 T006 全部用例…');
    await _runCase(
      title: 'shouldInterceptRequest 延迟 1s',
      action: () => _testShouldInterceptRequest(delayMs: 1000),
    );
    await _runCase(
      title: 'shouldInterceptRequest 延迟 2s',
      action: () => _testShouldInterceptRequest(delayMs: 2000),
    );
    await _runCase(
      title: 'shouldInterceptRequest 延迟 3s',
      action: () => _testShouldInterceptRequest(delayMs: 3000),
    );
    await _runCase(title: 'onLoadResourceWithCustomScheme', action: _testCustomScheme);
    await _runCase(title: 'WebViewAssetLoader', action: _testWebViewAssetLoader);
    await _runCase(
      title: '压力测试: 快速刷新 5 次',
      action: _testStressReload,
      timeout: const Duration(seconds: 60),
    );
    _log('全部用例执行完毕。');
  }

  InAppWebViewSettings _settingsForProfile() {
    switch (_profile) {
      case _WebViewProfile.syncIntercept:
        return InAppWebViewSettings(
          isInspectable: kDebugMode,
          clearCache: true,
        );
      case _WebViewProfile.customScheme:
        return InAppWebViewSettings(
          isInspectable: kDebugMode,
          clearCache: true,
          resourceCustomSchemes: [_customScheme],
        );
      case _WebViewProfile.assetLoader:
        return InAppWebViewSettings(
          isInspectable: kDebugMode,
          clearCache: true,
          webViewAssetLoader: WebViewAssetLoader(
            domain: _assetLoaderDomain,
            pathHandlers: [AssetsPathHandler(path: '/assets/')],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T006 SyncCallback 测试'),
      ),
      drawer: myDrawer(context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: InAppWebView(
              key: ValueKey(_profile),
              initialUrlRequest: URLRequest(url: WebUri('about:blank')),
              initialSettings: _settingsForProfile(),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStop: (controller, url) {
                _log('onLoadStop: $url');
              },
              onReceivedError: (controller, request, error) {
                _log('onReceivedError: ${request.url} — ${error.description}');
              },
              shouldInterceptRequest: _profile == _WebViewProfile.syncIntercept
                  ? (controller, request) async {
                      _interceptCallCount++;
                      _log(
                        'shouldInterceptRequest #$_interceptCallCount: ${request.url}',
                      );
                      await Future.delayed(Duration(milliseconds: _interceptDelayMs));
                      return null;
                    }
                  : null,
              onLoadResourceWithCustomScheme:
                  _profile == _WebViewProfile.customScheme
                      ? (controller, request) async {
                          _customSchemeCallCount++;
                          _log(
                            'onLoadResourceWithCustomScheme #$_customSchemeCallCount: ${request.url}',
                          );
                          if (request.url.scheme == _customScheme) {
                            return CustomSchemeResponse(
                              data: _inlineSvgBytes,
                              contentType: 'image/svg+xml',
                              contentEncoding: 'utf-8',
                            );
                          }
                          return null;
                        }
                      : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '平台: $defaultTargetPlatform | 模式: $_profile\n'
              '验证 SyncBaseCallbackResultImpl 同步等待（Atomics + 10s 超时）\n'
              '当前拦截延迟: ${_interceptDelayMs}ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _actionButton('拦截 1s', () => _runCase(
                      title: 'shouldInterceptRequest 延迟 1s',
                      action: () => _testShouldInterceptRequest(delayMs: 1000),
                    )),
                _actionButton('拦截 2s', () => _runCase(
                      title: 'shouldInterceptRequest 延迟 2s',
                      action: () => _testShouldInterceptRequest(delayMs: 2000),
                    )),
                _actionButton('拦截 3s', () => _runCase(
                      title: 'shouldInterceptRequest 延迟 3s',
                      action: () => _testShouldInterceptRequest(delayMs: 3000),
                    )),
                _actionButton('自定义 Scheme', () => _runCase(
                      title: 'onLoadResourceWithCustomScheme',
                      action: _testCustomScheme,
                    )),
                _actionButton('AssetLoader', () => _runCase(
                      title: 'WebViewAssetLoader',
                      action: _testWebViewAssetLoader,
                    )),
                _actionButton('压力刷新', () => _runCase(
                      title: '压力测试: 快速刷新 5 次',
                      action: _testStressReload,
                      timeout: const Duration(seconds: 60),
                    )),
                _actionButton('运行全部', _runAllTests),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('点击按钮运行测试，结果将显示在下方。'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final line = _logs[index];
                      final isPass = line.contains('PASS');
                      final isFail = line.contains('FAIL');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isPass
                                ? Colors.green.shade800
                                : isFail
                                    ? Colors.red.shade800
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Future<void> Function() onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.tonal(
        onPressed: () => onPressed(),
        child: Text(label),
      ),
    );
  }
}
