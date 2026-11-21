/// Demo 20: InAppBrowser
///
/// 功能说明：展示 InAppBrowser 的独立浏览器窗口控制能力。
/// OHOS 上 InAppBrowser 为系统级窗口，会覆盖整个页面。点「打开」后，
/// 浏览器会弹出覆盖一切；从屏幕底部上滑回桌面再重新进入 app 即可
/// 回到控制页面，此时状态区实时显示浏览器运行状态。
///
/// 对应接口：
///   - openUrlRequest/show/hide/close/setSettings/getSettings
///   - isHidden/isOpened
///   - 回调: onBrowserCreated/onLoadStart/onLoadStop/onReceivedError/onExit

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_InAppBrowser';

class InappBrowserPage extends StatefulWidget {
  const InappBrowserPage({super.key});

  @override
  State<InappBrowserPage> createState() => _InappBrowserPageState();
}

class _InappBrowserPageState extends State<InappBrowserPage> {
  bool _isOpened = false;
  String _status = '未打开';
  String _lastUrl = '';
  int _loadCount = 0;
  String _title = '';
  int _progress = 0;

  late final _MyInAppBrowser _browser;
  final _urlController = TextEditingController(text: 'https://flutter.cn');

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
    _browser = _MyInAppBrowser(
      onStatusChanged: (open, url, loadCount) {
        if (!mounted) return;
        setState(() {
          _isOpened = open;
          if (url != null) _lastUrl = url;
          if (loadCount != null) _loadCount = loadCount;
        });
      },
      onTitle: (title) {
        if (!mounted) return;
        setState(() => _title = title ?? '');
      },
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _progress = p);
      },
    );
  }

  @override
  void dispose() {
    _browser.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _openUrl() async {
    setState(() => _status = '打开中（后台）');
    try {
      await _browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri(_urlController.text)),
        settings: InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(hidden: true),
        ),
      );
      if (!mounted) return;
      setState(() {
        _isOpened = _browser.isOpened();
        _status = '后台运行中（hidden=true）';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _close() async {
    try {
      await _browser.close();
      if (!mounted) return;
      setState(() {
        _isOpened = false;
        _status = '已关闭';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _setSettings() async {
    try {
      await _browser.setSettings(
        settings: InAppBrowserClassSettings(
          webViewSettings: InAppWebViewSettings(javaScriptEnabled: false),
        ),
      );
      setState(() => _status = 'setSettings: javaScriptEnabled=false');
    } catch (e) {
      setState(() => _status = 'setSettings: $e');
    }
  }

  Future<void> _getSettings() async {
    try {
      final s = await _browser.getSettings();
      setState(() => _status = 'getSettings: ${s?.toString() ?? "null"}');
    } catch (e) {
      setState(() => _status = 'getSettings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[020] 独立浏览器窗口')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                        Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'OHOS 上 InAppBrowser 以系统级窗口打开后会覆盖全屏无法返回。'
                  '本页用 hidden=true 模式：浏览器后台运行，状态区实时显示回调。'
                  '点「打开」→ 观察回调 → 点「关闭」销毁。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: '目标 URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                    onPressed: _openUrl, child: const Text('打开（后台）')),
                ElevatedButton(
                    onPressed: _isOpened ? _close : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: const Text('关闭',
                        style: TextStyle(color: Colors.white))),
                ElevatedButton(
                    onPressed: _isOpened ? _setSettings : null,
                    child: const Text('setSettings(会触发显示浏览器窗口)')),
                ElevatedButton(
                    onPressed: _isOpened ? _getSettings : null,
                    child: const Text('getSettings')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('状态: $_status'),
                  Text('已打开: $_isOpened'),
                  Text('最近URL: $_lastUrl'),
                  Text('加载次数: $_loadCount'),
                  Text('标题: $_title'),
                  Text('进度: $_progress'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyInAppBrowser extends InAppBrowser {
  _MyInAppBrowser({
    required this.onStatusChanged,
    required this.onTitle,
    required this.onProgress,
  });

  final void Function(
    bool isOpened,
    String? lastUrl,
    int? loadCount,
  ) onStatusChanged;
  final void Function(String? title) onTitle;
  final void Function(int progress) onProgress;

  int _loadCount = 0;

  @override
  void onBrowserCreated() {
    onStatusChanged(true, null, _loadCount);
  }

  @override
  void onLoadStart(WebUri? url) {
    _loadCount++;
    onStatusChanged(true, url?.toString(), _loadCount);
  }

  @override
  void onLoadStop(WebUri? url) {
    onStatusChanged(true, url?.toString(), _loadCount);
  }

  @override
  void onProgressChanged(int progress) {
    onProgress(progress);
  }

  @override
  void onTitleChanged(String? title) {
    onTitle(title);
  }

  @override
  void onExit() {
    _loadCount = 0;
    onStatusChanged(false, null, 0);
  }
}