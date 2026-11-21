import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

const String _kAssetRoot = 'assets/vite_spa_demo/';
final String _kLoaderDomain = WebViewAssetLoader.DEFAULT_DOMAIN;
final String _kEntryUrl = 'https://$_kLoaderDomain/public/index.html';

/// Issue #327：CustomPathHandler 经 WebViewAssetLoader 加载 Vite-like SPA + SVG。
class CustomPathHandlerViteSpaScreen extends StatefulWidget {
  const CustomPathHandlerViteSpaScreen({super.key});

  @override
  State<CustomPathHandlerViteSpaScreen> createState() =>
      _CustomPathHandlerViteSpaScreenState();
}

class _CustomPathHandlerViteSpaScreenState
    extends State<CustomPathHandlerViteSpaScreen> {
  InAppWebViewController? _controller;
  int _reloadKey = 0;
  double _progress = 0;

  final List<String> _handlerLogs = [];
  String _verifyResult = '等待页面加载…';
  bool _verifyOk = false;

  late final _ViteSpaCustomPathHandler _pathHandler = _ViteSpaCustomPathHandler(
    path: '/public/',
    assetRoot: _kAssetRoot,
    onHandled: _onResourceHandled,
  );

  void _onResourceHandled(String subPath, int bytes, String mime) {
    final line = mime == '404'
        ? '404 $subPath'
        : '$subPath ($mime, ${bytes}B)';
    setState(() {
      _handlerLogs.insert(0, line);
      if (_handlerLogs.length > 20) _handlerLogs.removeLast();
    });
  }

  Future<void> _verifyPage() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final mounted = await controller.evaluateJavascript(
        source: 'window.__VITE_SPA_DEMO__?.mounted === true',
      );
      final logoWidth = await controller.evaluateJavascript(
        source: 'document.getElementById("logo")?.naturalWidth ?? 0',
      );
      final appHtml = await controller.evaluateJavascript(
        source: 'document.getElementById("app")?.innerHTML ?? ""',
      );
      final demoJson = await controller.evaluateJavascript(
        source: 'JSON.stringify(window.__VITE_SPA_DEMO__ ?? null)',
      );

      final ok = mounted == true && (logoWidth is num ? logoWidth > 0 : false);
      setState(() {
        _verifyOk = ok;
        _verifyResult = ok
            ? '通过：SPA 已挂载，SVG 已渲染 (logo ${logoWidth}px)\n$demoJson'
            : '失败：mounted=$mounted logoWidth=$logoWidth\napp=$appHtml\n$demoJson';
      });
    } catch (e) {
      setState(() {
        _verifyOk = false;
        _verifyResult = '校验异常：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomPathHandler Vite SPA'),
        actions: [
          IconButton(
            tooltip: '重新加载',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _reloadKey++;
              _verifyResult = '重新加载中…';
              _verifyOk = false;
              _handlerLogs.clear();
            }),
          ),
        ],
      ),
      drawer: myDrawer(context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_progress < 1.0) LinearProgressIndicator(value: _progress),
          Container(
            color: _verifyOk ? Colors.green.shade50 : Colors.orange.shade50,
            padding: const EdgeInsets.all(10),
            child: Text(
              _verifyResult,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'URL: $_kEntryUrl',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
          if (_handlerLogs.isNotEmpty)
            Container(
              height: 72,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListView(
                children: _handlerLogs
                    .map((e) => Text(e, style: const TextStyle(fontSize: 11)))
                    .toList(),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: InAppWebView(
              key: ValueKey('vite_spa_$_reloadKey'),
              initialUrlRequest: URLRequest(url: WebUri(_kEntryUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                allowFileAccess: false,
                allowContentAccess: false,
                allowFileAccessFromFileURLs: false,
                allowUniversalAccessFromFileURLs: false,
                webViewAssetLoader: WebViewAssetLoader(
                  domain: _kLoaderDomain,
                  httpAllowed: true,
                  pathHandlers: [_pathHandler],
                ),
              ),
              onWebViewCreated: (c) => _controller = c,
              onProgressChanged: (_, p) => setState(() => _progress = p / 100),
              onLoadStop: (_, __) => _verifyPage(),
              onConsoleMessage: (_, msg) {
                debugPrint('[vite-spa-demo] ${msg.message}');
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame != true) return;
                setState(() {
                  _verifyOk = false;
                  _verifyResult =
                      '主框架错误：${request.url} | ${error.description}';
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ViteSpaCustomPathHandler extends CustomPathHandler {
  _ViteSpaCustomPathHandler({
    required super.path,
    required this.assetRoot,
    this.onHandled,
  });

  final String assetRoot;
  final void Function(String subPath, int bytes, String mime)? onHandled;

  @override
  Future<WebResourceResponse?> handle(String path) async {
    var subPath = path.startsWith('/') ? path.substring(1) : path;
    if (subPath.isEmpty) subPath = 'index.html';

    final assetPath = '$assetRoot$subPath';
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final mime = _guessMimeType(subPath);
      onHandled?.call(subPath, bytes.length, mime);
      return WebResourceResponse(
        contentType: mime,
        contentEncoding: _isTextLike(mime) ? 'utf-8' : null,
        data: Uint8List.fromList(bytes),
      );
    } catch (_) {
      onHandled?.call(subPath, 0, '404');
      return WebResourceResponse(
        contentType: 'text/plain',
        statusCode: 404,
        data: null,
      );
    }
  }
}

bool _isTextLike(String mime) {
  final lower = mime.toLowerCase();
  return lower.startsWith('text/') ||
      lower.contains('javascript') ||
      lower.contains('json') ||
      lower.contains('xml') ||
      lower.contains('svg');
}

String _guessMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'html' => 'text/html',
    'js' => 'application/javascript',
    'css' => 'text/css',
    'svg' => 'image/svg+xml',
    'json' => 'application/json',
    'png' => 'image/png',
    'woff2' => 'font/woff2',
    _ => 'application/octet-stream',
  };
}
