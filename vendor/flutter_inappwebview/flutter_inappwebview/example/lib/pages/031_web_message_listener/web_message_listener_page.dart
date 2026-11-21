/// Demo 31: WebMessageListener / WebMessageChannel
///
/// 功能说明：演示 WebMessageListener 与 WebMessageChannel 的构造、
/// jsObjectName、allowedOriginRules、onPostMessage 回调及 dispose。
/// 对应接口：
///   - WebMessageListener(constructor, jsObjectName, allowedOriginRules, onPostMessage, dispose)
///   - WebMessageChannel(constructor, id, port1, port2, dispose)

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_WebMessageListener';

class WebMessageListenerPage extends StatefulWidget {
  const WebMessageListenerPage({super.key});

  @override
  State<WebMessageListenerPage> createState() => _WebMessageListenerPageState();
}

class _WebMessageListenerPageState extends State<WebMessageListenerPage> {
  InAppWebViewController? _controller;
  WebMessageListener? _listener;
  WebMessageChannel? _channel;
  String _log = '';
  String _status = '等待 WebView 创建';

  static const String _testHtml = '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>WebMessage</title></head>
<body>
  <h3>WebMessageListener Demo</h3>
  <button onclick="sendMsg()">postMessage via NativeBridge</button>
  <pre id="out">(等待消息)</pre>
  <script>
    function sendMsg() {
      if (window.NativeBridge && window.NativeBridge.postMessage) {
        window.NativeBridge.postMessage('hello from JS');
        document.getElementById('out').innerText = '已发送 hello from JS';
      } else {
        document.getElementById('out').innerText = 'NativeBridge 不可用';
      }
    }
  </script>
</body>
</html>
''';

  void _appendLog(String line) {
    setState(() => _log = '$_log\n$line'.trim());
  }

  Future<void> _registerListener() async {
    final controller = _controller;
    if (controller == null) return;

    _listener?.dispose();
    // 用带时间戳的 jsObjectName 避免重复添加同名对象断言失败
    final name = 'NativeBridge_${DateTime.now().millisecondsSinceEpoch}';
    _listener = WebMessageListener(
      jsObjectName: name,
      allowedOriginRules: {'https://localhost', 'http://localhost'},
      onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
        dev.log('onPostMessage: $message from $sourceOrigin', name: _kTag);
        _appendLog(
          'onPostMessage: data=$message origin=$sourceOrigin mainFrame=$isMainFrame',
        );
        replyProxy.postMessage(WebMessage(data: 'ack from Dart'));
      },
    );
    await controller.addWebMessageListener(_listener!);
    // 注入一个 bridge 函数让按钮代码不依赖具体的 jsObjectName
    await controller.evaluateJavascript(source: '''
      window.NativeBridge = window['$name'];
    ''');
    setState(() => _status = 'WebMessageListener 已注册 ($name)');
  }

  Future<void> _createChannel() async {
    final controller = _controller;
    if (controller == null) return;

    _channel?.dispose();
    final created = await controller.createWebMessageChannel();
    if (created == null) {
      setState(() => _status = 'createWebMessageChannel 返回 null');
      return;
    }
    _channel = created;
    _appendLog(
      'WebMessageChannel id=${created.id} port1=${created.port1.hashCode} port2=${created.port2.hashCode}',
    );
    setState(() => _status = 'WebMessageChannel 已创建');
  }

  void _disposeListener() {
    _listener?.dispose();
    _listener = null;
    _controller?.evaluateJavascript(source: 'window.NativeBridge = undefined;');
    setState(() {
      _status = 'WebMessageListener 已 dispose';
      _log = '';
    });
  }

  void _disposeChannel() {
    _channel?.dispose();
    _channel = null;
    setState(() {
      _status = 'WebMessageChannel 已 dispose';
      _log = '';
    });
  }

  @override
  void dispose() {
    _listener?.dispose();
    _channel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[031] WebMessageListener')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('状态: $_status'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _registerListener,
                      child: const Text('注册 WebMessageListener'),
                    ),
                    ElevatedButton(
                      onPressed: _createChannel,
                      child: const Text('createWebMessageChannel'),
                    ),
                    OutlinedButton(
                      onPressed: _disposeListener,
                      child: const Text('listener.dispose()'),
                    ),
                    OutlinedButton(
                      onPressed: _disposeChannel,
                      child: const Text('channel.dispose()'),
                    ),
                  ],
                ),
                if (_log.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[100],
                    child: SelectableText(
                      _log,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: _testHtml,
                baseUrl: WebUri('https://localhost/'),
              ),
              initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
              onWebViewCreated: (c) {
                _controller = c;
                dev.log('onWebViewCreated', name: _kTag);
              },
            ),
          ),
        ],
      ),
    );
  }
}
