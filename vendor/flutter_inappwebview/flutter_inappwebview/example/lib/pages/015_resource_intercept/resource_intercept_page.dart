/// Demo 15: 资源加载拦截
///
/// 功能说明：
///   1. shouldInterceptRequest — 加载百度时拦截 .png 子资源，开关开=替换成
///      自定义 SVG，关=放行加载原图；
///   2. shouldInterceptAjaxRequest — 拦截 XHR。
///
/// 对应接口：
///   - shouldInterceptRequest(controller, request): Future<WebResourceResponse?>
///   - shouldInterceptAjaxRequest(controller, ajaxRequest): Future<AjaxRequest?>
/// 
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_ResourceIntercept';

class ResourceInterceptPage extends StatefulWidget {
  const ResourceInterceptPage({super.key});
  @override
  State<ResourceInterceptPage> createState() => _ResourceInterceptPageState();
}

class _ResourceInterceptPageState extends State<ResourceInterceptPage> {
  InAppWebViewController? _controller;

  bool _replaceImage = true;
  int _interceptCount = 0;
  int _ajaxCount = 0;
  final List<String> _log = [];
  int _rebuildKey = 0;

  @override
  void dispose() {
    dev.log('Page disposed', name: _kTag);
    super.dispose();
  }

  void _logLine(String s) {
    dev.log(s, name: _kTag);
    if (!mounted) return;
    setState(() {
      _log.insert(0, s);
      if (_log.length > 30) _log.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[015] 资源加载拦截'),
        actions: [
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() {
              _interceptCount = 0;
              _ajaxCount = 0;
              _log.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            dense: true,
            title: const Text('拦截 .png 图片请求'),
            subtitle: const Text(
                '开：拦截百度页面中的 .png → 替换为绿色 SVG；关：放行',
                style: TextStyle(fontSize: 11)),
            value: _replaceImage,
            onChanged: (v) => setState(() {
              _replaceImage = v;
              _rebuildKey++;
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              _chip('拦截', _interceptCount, Colors.blue),
              const SizedBox(width: 10),
              _chip('AJAX', _ajaxCount, Colors.orange),
            ]),
          ),
          _logPanel(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              Text(
                '模式：${_replaceImage ? "替换 .png" : "放行"}',
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                  onPressed: () => setState(() => _rebuildKey++),
                  child: const Text('刷新页面')),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: InAppWebView(
              key: ValueKey('webview_$_rebuildKey'),
              initialUrlRequest: URLRequest(
                url: WebUri('https://www.baidu.com/'),
              ),
              initialSettings: InAppWebViewSettings(
                useShouldInterceptRequest: true,
                useShouldInterceptAjaxRequest: true,
                javaScriptEnabled: true,
                domStorageEnabled: true,
              ),
              onWebViewCreated: (c) => _controller = c,
              shouldInterceptRequest: (controller, request) async {
                final url = request.url.toString();
                if (!url.endsWith('.png')) return null;
                _interceptCount++;
                if (_replaceImage) {
                  _logLine('替换: ${url.substring(0, 60)}...');
                  final svg = '<svg xmlns="http://www.w3.org/2000/svg" width="100" '
                      'height="100"><rect width="100%" height="100%" fill="#4caf50"/>'
                      '<text x="10" y="55" fill="white" font-size="16">Dart</text></svg>';
                  return WebResourceResponse(
                    contentType: 'image/svg+xml',
                    contentEncoding: 'utf-8',
                    data: Uint8List.fromList(svg.codeUnits),
                  );
                }
                _logLine('放行: ${url.substring(0, 60)}...');
                return null;
              },
              shouldInterceptAjaxRequest: (controller, ajaxRequest) async {
                _ajaxCount++;
                _logLine('AJAX拦截: ${ajaxRequest.url}');
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: count > 0 ? color.withOpacity(0.12) : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: count > 0 ? color : Colors.grey[300]!, width: 1.5),
        ),
        child: Text('$label $count',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: count > 0 ? color : Colors.grey[600])),
      );

  Widget _logPanel() => SizedBox(
        height: 100,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _log.isEmpty
              ? const Center(
                  child: Text('(暂无日志)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)))
              : ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    color: i == 0 ? Colors.amber[100] : null,
                    child: Text(_log[i],
                        style: TextStyle(
                            fontFamily: 'monospace', fontSize: 11)),
                  ),
                ),
        ),
      );
}

