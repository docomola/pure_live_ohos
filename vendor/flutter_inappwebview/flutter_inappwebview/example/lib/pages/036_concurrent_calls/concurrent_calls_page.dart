/// Demo 37: 并发调用场景
///
/// 对应用例覆盖度报告：无并发 loadUrl/reload 等并发调用测试。
///
/// 本页演示：
///   - Future.wait 并发 loadUrl + reload + getUrl
///   - 短间隔连发多次 loadUrl
///   - 双 WebView 实例同时操作
///
/// 对应接口：
///   - loadUrl / reload / getUrl / getTitle / evaluateJavascript

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';
import '../../common/test_button.dart';
import '../../common/test_urls.dart';

const String _kTag = 'InAppWebView_ConcurrentCalls';

class ConcurrentCallsPage extends StatefulWidget {
  const ConcurrentCallsPage({super.key});

  @override
  State<ConcurrentCallsPage> createState() => _ConcurrentCallsPageState();
}

class _ConcurrentCallsPageState extends State<ConcurrentCallsPage> {
  final EventLogController _logger = EventLogController();
  InAppWebViewController? _controllerA;
  InAppWebViewController? _controllerB;

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
  }

  @override
  void dispose() {
    _logger.dispose();
    super.dispose();
  }

  Future<Object?> _concurrentSameController() async {
    final c = _controllerA;
    if (c == null) return 'controllerA 未就绪';
    final results = await Future.wait<Object?>([
      c.loadUrl(urlRequest: URLRequest(url: WebUri(kFlutterDevUrl)))
          .then((_) => 'loadUrl ok'),
      c.reload().then((_) => 'reload ok'),
      c.getUrl().then((u) => 'getUrl=$u'),
      c.evaluateJavascript(source: 'document.readyState')
          .then((v) => 'js=$v'),
    ]);
    return results.join(' | ');
  }

  Future<Object?> _burstLoadUrl() async {
    final c = _controllerA;
    if (c == null) return 'controllerA 未就绪';
    final urls = <String>[
      kBlankUrl,
      kHomeUrl,
      kFlutterDevUrl,
      kBlankUrl,
      kHomeUrl,
    ];
    final futures = <Future<String>>[];
    for (var i = 0; i < urls.length; i++) {
      final idx = i;
      final url = urls[i];
      futures.add(
        c
            .loadUrl(urlRequest: URLRequest(url: WebUri(url)))
            .then((_) => '#$idx loadUrl($url) ok')
            .catchError((Object e) => '#$idx loadUrl error: $e'),
      );
    }
    final results = await Future.wait(futures);
    return results.join(' | ');
  }

  Future<Object?> _concurrentTwoWebViews() async {
    final a = _controllerA;
    final b = _controllerB;
    if (a == null || b == null) return '双 WebView 未就绪';
    final results = await Future.wait<Object?>([
      a
          .loadUrl(urlRequest: URLRequest(url: WebUri(kHomeUrl)))
          .then((_) => 'A.loadUrl ok'),
      b
          .loadUrl(urlRequest: URLRequest(url: WebUri(kFlutterDevUrl)))
          .then((_) => 'B.loadUrl ok'),
      a.getTitle().then((t) => 'A.title=$t'),
      b.getTitle().then((t) => 'B.title=$t'),
    ]);
    return results.join(' | ');
  }

  Widget _buildWebView(String label, void Function(InAppWebViewController) onCreated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 100,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(kBlankUrl)),
            initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
            onWebViewCreated: onCreated,
            onLoadStop: (controller, url) {
              _logger.log(_kTag, '$label onLoadStop: $url');
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[036] 并发调用')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  '覆盖报告缺失：并发 loadUrl/reload、多 WebView 并发。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                _buildWebView('WebView A', (c) {
                  _controllerA = c;
                  _logger.log(_kTag, 'WebView A created');
                }),
                const SizedBox(height: 8),
                _buildWebView('WebView B', (c) {
                  _controllerB = c;
                  _logger.log(_kTag, 'WebView B created');
                }),
                const SizedBox(height: 8),
                AsyncTestButton(
                  label: '同 Controller：loadUrl+reload+getUrl+JS 并发',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _concurrentSameController,
                ),
                AsyncTestButton(
                  label: '连发 5 次 loadUrl（Future.wait）',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _burstLoadUrl,
                ),
                AsyncTestButton(
                  label: '双 WebView 同时 loadUrl/getTitle',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _concurrentTwoWebViews,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: EventLogPanel(controller: _logger, height: 180),
          ),
        ],
      ),
    );
  }
}
