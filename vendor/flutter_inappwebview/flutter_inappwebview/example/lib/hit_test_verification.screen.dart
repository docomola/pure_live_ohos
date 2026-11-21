import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// OHOS HitTest API 验证页面。
///
/// 测试步骤：
///   1. 长按 "This is a test link" 链接
///   2. 点 requestFocusNodeHref → 应返回 url=https://example.com/link1
///   3. 长按图片
///   4. 点 requestImageRef → 应返回图片 URL
///   5. 点 getHitTestResult → 验证同步 API
///
/// 说明：title 字段在 OHOS 原生 API (WebContextMenuParam) 中不提供，
/// 与 Android（引擎内置）和 iOS（JS DOM 遍历）不同，属平台限制。
class HitTestVerificationScreen extends StatefulWidget {
  @override
  _HitTestVerificationScreenState createState() =>
      _HitTestVerificationScreenState();
}

class _HitTestVerificationScreenState extends State<HitTestVerificationScreen> {
  InAppWebViewController? _controller;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  bool _hasTouched = false;

  static const String _testHtml = '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>HitTest Verification</title></head>
<body style="font-family: sans-serif; padding: 16px;">
  <h2>HitTest Verification Page</h2>
  <p><b>Instructions:</b> Long-press each element, then press test buttons.</p>

  <h3>1. Plain Anchor (SRC_ANCHOR_TYPE)</h3>
  <a href="https://example.com/link1" id="link1">This is a test link</a>

  <h3>2. Plain Image (IMAGE_TYPE)</h3>
  <img src="https://via.placeholder.com/200x100.png?text=Test+Image"
       alt="Test Image Alt Text" id="img1" style="border: 2px solid blue; margin: 8px;"/>

  <h3>3. Image wrapped in Anchor (SRC_IMAGE_ANCHOR_TYPE)</h3>
  <a href="https://example.com/wrapped" id="wrapped-link">
    <img src="https://via.placeholder.com/200x80.png?text=Wrapped+Image"
         alt="Wrapped Image" id="wrapped-img" style="border: 2px solid green;"/>
  </a>
</body>
</html>
''';

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    setState(() => _logs.add('[$ts] $msg'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(
          _logScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _testGetHitTestResult() async {
    _log('--- getHitTestResult ---');
    try {
      final result = await _controller?.getHitTestResult();
      if (result != null) {
        _log('  type  = ${result.type?.toString() ?? 'null'}');
        _log('  extra = ${result.extra ?? 'null'}');
      } else {
        _log('  result is null');
      }
    } catch (e) {
      _log('  ERROR: $e');
    }
    _log('--- done ---');
  }

  Future<void> _testRequestFocusNodeHref() async {
    _log('--- requestFocusNodeHref ---');
    if (!_hasTouched) {
      _log('  >> TIP: Long-press a LINK first! <<');
    }
    try {
      final result = await _controller?.requestFocusNodeHref();
      if (result != null) {
        _log('  url = ${result.url ?? 'null'}');
        _log('  src = ${result.src ?? 'null'}');
        if (result.url == null) {
          _log('  (null: no long-press data available)');
        }
      } else {
        _log('  result is null');
      }
    } catch (e) {
      _log('  ERROR: $e');
    }
    _log('--- done ---');
  }

  Future<void> _testRequestImageRef() async {
    _log('--- requestImageRef ---');
    if (!_hasTouched) {
      _log('  >> TIP: Long-press an IMAGE first! <<');
    }
    try {
      final result = await _controller?.requestImageRef();
      if (result != null) {
        _log('  url = ${result.url ?? 'null'}');
        if (result.url == null) {
          _log('  (null: no long-press data available)');
        }
      } else {
        _log('  result is null');
      }
    } catch (e) {
      _log('  ERROR: $e');
    }
    _log('--- done ---');
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _hasTouched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HitTest Verification')),
      drawer: myDrawer(context: context),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Container(
              padding: EdgeInsets.all(10),
              color: _hasTouched ? Colors.green.shade50 : Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(_hasTouched ? Icons.check_circle : Icons.warning_amber,
                      size: 16,
                      color: _hasTouched ? Colors.green : Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasTouched
                          ? '✓ Touch detected. Press test buttons below.'
                          : 'STEP 1: Long-press a link or image in the WebView above.',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              flex: 3,
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _testHtml,
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                ),
                initialSettings: InAppWebViewSettings(
                  isInspectable: true,
                  javaScriptEnabled: true,
                ),
                contextMenu: ContextMenu(
                  settings: ContextMenuSettings(
                    hideDefaultSystemContextMenuItems: false,
                  ),
                  onCreateContextMenu: (hitTestResult) {
                    _hasTouched = true;
                    _log('>>> LONG-PRESS DETECTED <<<');
                    _log('  type  = ${hitTestResult.type?.toString() ?? 'null'}');
                    _log('  extra = ${hitTestResult.extra ?? 'null'}');
                  },
                  onHideContextMenu: () => _log('onHideContextMenu'),
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  _log('WebView ready. Long-press a link/image to start.');
                },
              ),
            ),
            // Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey.shade100,
              child: Wrap(spacing: 8, runSpacing: 4, children: [
                _buildButton(
                    'getHitTestResult', Icons.touch_app, Colors.blue.shade100,
                    _testGetHitTestResult),
                _buildButton('requestFocusNodeHref', Icons.link,
                    Colors.green.shade100, _testRequestFocusNodeHref),
                _buildButton(
                    'requestImageRef', Icons.image, Colors.orange.shade100,
                    _testRequestImageRef),
                _buildButton(
                    'Clear Logs', Icons.clear_all, Colors.grey.shade300,
                    _clearLogs),
              ]),
            ),
            // Log area
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey.shade900,
                width: double.infinity,
                child: ListView.builder(
                  controller: _logScrollController,
                  padding: EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) => Text(
                    _logs[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.greenAccent.shade100,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
    );
  }
}
