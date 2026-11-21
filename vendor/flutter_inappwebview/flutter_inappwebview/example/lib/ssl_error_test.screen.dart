import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// 测试 onReceivedSslErrorEventReceive 两个分支:
/// 1. 有 channelDelegate 时 → onReceivedServerTrustAuthRequest 回调触发 (if 分支)
/// 2. 无 channelDelegate 时 → handler.handleCancel() 拒绝 SSL 连接 (else 分支，本次修复)
class SslErrorTestScreen extends StatefulWidget {
  @override
  _SslErrorTestScreenState createState() => _SslErrorTestScreenState();
}

class _SslErrorTestScreenState extends State<SslErrorTestScreen> {
  // 测试1: 有回调 (if 分支)
  final GlobalKey _key1 = GlobalKey();
  InAppWebViewController? _controller1;
  String _result1 = ""; // "pass" / "fail" / ""

  // 测试2: 无回调 (else 分支，本次修复核心)
  final GlobalKey _key2 = GlobalKey();
  InAppWebViewController? _controller2;
  String _result2 = "";

  void _runTest1() {
    setState(() => _result1 = "");
    _controller1?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://self-signed.badssl.com/')),
    );
  }

  void _runTest2() {
    setState(() => _result2 = "");
    _controller2?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://self-signed.badssl.com/')),
    );
  }

  Widget _buildResult(String result) {
    if (result == "pass") {
      return Column(children: [
        Icon(Icons.check_circle, color: Colors.green, size: 40),
        Text("通过", style: TextStyle(color: Colors.green, fontSize: 16)),
      ]);
    } else if (result == "fail") {
      return Column(children: [
        Icon(Icons.cancel, color: Colors.red, size: 40),
        Text("失败", style: TextStyle(color: Colors.red, fontSize: 16)),
      ]);
    }
    return Text("待测试", style: TextStyle(color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SSL Error Test")),
      drawer: myDrawer(context: context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 测试1: 有 channelDelegate (if 分支)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("测试1: 有回调 (if 分支)", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("验证 onReceivedServerTrustAuthRequest 回调触发",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 8),
                    Row(children: [
                      ElevatedButton(onPressed: _runTest1, child: Text("测试")),
                      SizedBox(width: 16),
                      _buildResult(_result1),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            // 测试2: 无 channelDelegate (else 分支，本次修复)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("测试2: 无回调 (else 分支 - 本次修复)", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("验证无 channelDelegate 时 SSL 连接被拒绝",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 8),
                    Row(children: [
                      ElevatedButton(onPressed: _runTest2, child: Text("测试")),
                      SizedBox(width: 16),
                      _buildResult(_result2),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 隐藏的 WebView
      bottomSheet: SizedBox(
        height: 1,
        child: Row(children: [
          // WebView1: 设置了 onReceivedServerTrustAuthRequest 回调 → channelDelegate != null → if 分支
          Expanded(
            child: InAppWebView(
              key: _key1,
              initialUrlRequest: URLRequest(url: WebUri('about:blank')),
              onWebViewCreated: (controller) => _controller1 = controller,
              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                // 回调触发 → if 分支正常工作
                setState(() => _result1 = "pass");
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
              },
              onLoadStop: (controller, url) {
                // 页面加载成功但回调未触发 → if 分支异常
                if (url.toString().contains('badssl.com') && _result1.isEmpty) {
                  setState(() => _result1 = "fail");
                }
              },
            ),
          ),
          // WebView2: 不设置 onReceivedServerTrustAuthRequest → channelDelegate == null → else 分支
          Expanded(
            child: InAppWebView(
              key: _key2,
              initialUrlRequest: URLRequest(url: WebUri('about:blank')),
              onWebViewCreated: (controller) => _controller2 = controller,
              // 故意不设置 onReceivedServerTrustAuthRequest，使 channelDelegate 为 null
              onReceivedError: (controller, request, error) {
                // SSL 被拒绝 → 加载报错 → else 分支 handleCancel() 生效
                if (request.url.toString().contains('badssl.com') && _result2.isEmpty) {
                  setState(() => _result2 = "pass");
                }
              },
              onLoadStop: (controller, url) {
                // 页面加载成功 → SSL 未被拒绝 → else 分支失效
                if (url.toString().contains('badssl.com') && _result2.isEmpty) {
                  setState(() => _result2 = "fail");
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}
