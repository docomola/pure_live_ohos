import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

const String kTestHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebMessageChannel Test</title>
</head>
<body style="font-size:18px; padding:10px;">
    <h3>WebMessageChannel 测试页面</h3>
    <input id="input" type="text" value="Hello from JS" />
    <br/><br/>
    <button onclick="sendToNative()">JS→Native 发消息</button>
    <p id="reply" style="color:green; font-weight:bold;"></p>
    <p id="status" style="color:blue;"></p>

    <script>
      var port;
      window.addEventListener('message', function(event) {
          if (event.data == 'capturePort') {
              if (event.ports[0] != null) {
                  port = event.ports[0];
                  document.getElementById('status').textContent = '端口已接收!';
                  port.onmessage = function (event) {
                      document.getElementById('reply').textContent =
                          'Native 回复: ' + event.data;
                      console.log('REPLY_FROM_NATIVE:' + event.data);
                  };
              } else {
                  document.getElementById('status').textContent = '错误: ports[0] 为 null';
              }
          }
      }, false);

      function sendToNative() {
          if (port) {
              port.postMessage(input.value);
              document.getElementById('status').textContent = '已发送: ' + input.value;
          } else {
              document.getElementById('status').textContent = '错误: port 未初始化!';
          }
      }
    </script>
</body>
</html>
''';

class WebMessageChannelTestScreen extends StatefulWidget {
  @override
  _WebMessageChannelTestScreenState createState() =>
      _WebMessageChannelTestScreenState();
}

class _WebMessageChannelTestScreenState
    extends State<WebMessageChannelTestScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  WebMessageChannel? _webMessageChannel;
  WebMessagePort? _port1;
  WebMessagePort? _port2;
  bool _isWebViewReady = false;
  String _status = "等待页面加载...";
  String _receivedMessage = "";
  Color _statusColor = Colors.grey;
  List<String> _logs = [];

  void _addLog(String msg) {
    setState(() {
      _logs.add(msg);
      print('webmessage = $msg');
      if (_logs.length > 30) _logs.removeAt(0);
    });
  }

  bool get _isChannelReady => _port1 != null;

  @override
  void dispose() {
    _disposeChannel();
    webViewController = null;
    super.dispose();
  }

  void _disposeChannel() {
    // 注意：不调用 close()，避免原生端口被关闭后导致 postMessage 失败
    // 旧 Channel 会在 WebView dispose 时由 InAppWebView.disposeWebMessageChannels() 统一清理
    _port1 = null;
    _port2 = null;
    _webMessageChannel = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WebMessageChannel 验证")),
      drawer: myDrawer(context: context),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: _statusColor.withOpacity(0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("状态: $_status",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _statusColor)),
                if (_receivedMessage.isNotEmpty)
                  Text("收到消息: $_receivedMessage",
                      style: TextStyle(fontSize: 14, color: Colors.green)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isWebViewReady ? _testWebMessageChannel : null,
                  child: Text("测试"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isChannelReady ? _sendFromNative : null,
                  child: Text("Native→JS"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearStatus,
                  child: Text("清除"),
                ),
              ],
            ),
          ),
          Container(
            height: 150,
            color: Colors.black12,
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (_, i) => Text(_logs[i],
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ),
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
                _addLog("onWebViewCreated");
                controller.loadData(
                    data: kTestHtml,
                    mimeType: "text/html",
                    encoding: "utf-8",
                    baseUrl: WebUri("https://localhost/"));
              },
              onConsoleMessage: (controller, consoleMessage) {
                if (consoleMessage.message.contains('REPLY_FROM_NATIVE:')) {
                  setState(() {
                    _receivedMessage = consoleMessage.message
                        .replaceAll('REPLY_FROM_NATIVE:', '')
                        .trim();
                  });
                }
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isWebViewReady = true;
                  _status = "页面已就绪，点击测试按钮";
                  _statusColor = Colors.blue;
                });
              },
              onLoadError: (controller, url, code, message) {
                _addLog("onLoadError: $code $message");
                setState(() {
                  _status = "加载失败: $message";
                  _statusColor = Colors.red;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testWebMessageChannel() async {
    if (webViewController == null) return;

    // 释放旧 Channel
    _disposeChannel();

    _addLog(">> createWebMessageChannel()");
    setState(() {
      _status = "创建 WebMessageChannel...";
      _statusColor = Colors.orange;
    });

    try {
      _webMessageChannel = await webViewController!.createWebMessageChannel();

      if (_webMessageChannel == null) {
        setState(() { _status = "创建失败!"; _statusColor = Colors.red; });
        _addLog("<< null ❌");
        return;
      }

      _addLog("<< id=${_webMessageChannel!.id} ✅");
      _port1 = _webMessageChannel!.port1;
      _port2 = _webMessageChannel!.port2;

      // port1 注册回调
      await _port1!.setWebMessageCallback((message) async {
        _addLog("<< 收到JS消息: ${message?.data}");
        setState(() {
          _status = "✅ 收到JS消息: ${message?.data}";
          _statusColor = Colors.green;
        });
        await _port1!.postMessage(
            WebMessage(data: "${message?.data} -> Native已收到!"));
        _addLog(">> 回复JS");
      });
      _addLog("setWebMessageCallback ✅");

      // 将 port2 发送给 JS
      await webViewController!.postWebMessage(
          message: WebMessage(data: "capturePort", ports: [_port2!]),
          targetOrigin: WebUri("*"));
      _addLog("postWebMessage ✅");

      await Future.delayed(Duration(milliseconds: 300));

      var portStatus = await webViewController!.evaluateJavascript(
          source: "port != null ? 'port_ready' : 'port_null'");
      _addLog("JS port: $portStatus");

      setState(() {
        _status = "✅ Channel 就绪，JS port=$portStatus";
        _statusColor = Colors.green;
      });

    } catch (e) {
      _addLog("❌ $e");
      setState(() { _status = "出错: $e"; _statusColor = Colors.red; });
    }
  }

  Future<void> _sendFromNative() async {
    if (_port1 == null) return;
    try {
      await _port1!.postMessage(WebMessage(data: "Hello from Native!"));
      _addLog(">> port1.postMessage('Hello from Native!') ✅");
    } catch (e) {
      _addLog("❌ $e");
    }
  }

  void _clearStatus() {
    setState(() {
      _status = "等待操作...";
      _receivedMessage = "";
      _statusColor = Colors.grey;
      _logs.clear();
    });
  }
}
