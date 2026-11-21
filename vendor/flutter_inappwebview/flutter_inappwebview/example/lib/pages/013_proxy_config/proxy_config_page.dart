/// Demo 13: ProxyConfig
///
/// 功能说明：展示 ProxyController 的 setProxyOverride/clearProxyOverride。
/// 下半部分嵌入 WebView 用于验证代理是否生效。
///
/// 对应接口：
///   - setProxyOverride(settings): Future<void>
///   - clearProxyOverride(): Future<void>

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_ProxyConfig';

class ProxyConfigPage extends StatefulWidget {
  const ProxyConfigPage({super.key});

  @override
  State<ProxyConfigPage> createState() => _ProxyConfigPageState();
}

class _ProxyConfigPageState extends State<ProxyConfigPage> {
  String _status = '';
  int _callCount = 0;
  int _doneCount = 0;
  InAppWebViewController? _controller;

  final _hostController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8888');

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    dev.log('Page disposed', name: _kTag);
    super.dispose();
  }

  Future<void> _applyProxy() async {
    setState(() {
      _callCount++;
      _status = '应用中…';
    });
    try {
      final settings = ProxySettings(
        proxyRules: [
          ProxyRule(
            url: 'http://${_hostController.text}:${_portController.text}',
          ),
        ],
      );
      await ProxyController.instance().setProxyOverride(settings: settings);
      if (!mounted) return;
      setState(() {
        _doneCount++;
        _status = '代理已应用 ${_hostController.text}:${_portController.text}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _clearProxy() async {
    setState(() => _status = '清除中…');
    try {
      await ProxyController.instance().clearProxyOverride();
      if (!mounted) return;
      setState(() => _status = '代理已清除');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _loadTest() async {
    await _controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://www.baidu.com/')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[013] 网络代理配置'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '设置代理后，WebView 流量经代理转发。'
                  '用下方 WebView 验证是否生效。',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: '代理主机',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: '端口',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyProxy,
                        child: const Text('应用代理'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearProxy,
                        child: const Text('清除代理'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('状态: $_status',
                          style: const TextStyle(fontSize: 13)),
                      Text('调用/完成: $_callCount/$_doneCount',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loadTest,
                        icon: const Icon(Icons.open_in_browser, size: 16),
                        label: const Text('加载百度验证'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                        url: WebUri('https://www.baidu.com/')),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                    ),
                    onWebViewCreated: (c) => _controller = c,
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