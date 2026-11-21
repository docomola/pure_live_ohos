import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// 验证 Web 组件默认 `WebKeyboardAvoidMode.RESIZE_VISUAL`。
class KeyboardAvoidModeTestScreen extends StatefulWidget {
  const KeyboardAvoidModeTestScreen({super.key});

  @override
  State<KeyboardAvoidModeTestScreen> createState() =>
      _KeyboardAvoidModeTestScreenState();
}

class _KeyboardAvoidModeTestScreenState
    extends State<KeyboardAvoidModeTestScreen> {
  InAppWebViewController? _controller;
  String _viewportInfo = '点击输入框测试键盘弹起/收起';
  String _keyboardState = '未知';

  static const String _testHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: sans-serif;
      background: #e2e8f0;
      padding: 16px;
    }
    .hint {
      padding: 10px;
      margin-bottom: 12px;
      border-radius: 8px;
      background: #1e293b;
      color: #fff;
      font-size: 14px;
      line-height: 1.5;
    }
    .section {
      margin-bottom: 12px;
      padding: 16px;
      border-radius: 8px;
      color: #fff;
      font-weight: 600;
      text-align: center;
    }
    .s1 { background: #2563eb; min-height: 120px; }
    .s2 { background: #7c3aed; min-height: 120px; }
    .s3 { background: #059669; min-height: 120px; }
    .field {
      margin-bottom: 12px;
      padding: 12px;
      background: #fff;
      border-radius: 8px;
      border: 2px solid #334155;
    }
    label { display: block; margin-bottom: 8px; font-weight: 600; color: #334155; }
    input, textarea {
      width: 100%;
      font-size: 16px;
      padding: 10px;
      border: 1px solid #94a3b8;
      border-radius: 8px;
    }
    textarea { min-height: 72px; resize: vertical; }
  </style>
</head>
<body>
  <div class="hint">先点顶部输入框，再滚动点底部输入框，观察键盘弹起/收起时页面与视口数据。</div>
  <div class="field">
    <label>顶部输入框</label>
    <input type="text" placeholder="点击弹起键盘" onfocus="reportViewport('focus-top')" onblur="reportViewport('blur-top')">
  </div>
  <div class="section s1">可滚动区域 1</div>
  <div class="section s2">可滚动区域 2</div>
  <div class="section s3">可滚动区域 3</div>
  <div class="field">
    <label>底部输入框（需先滚动到底）</label>
    <textarea placeholder="点击弹起键盘" onfocus="reportViewport('focus-bottom')" onblur="reportViewport('blur-bottom')"></textarea>
  </div>
  <script>
    var baseInnerHeight = window.innerHeight;
    function reportViewport(eventName) {
      var vv = window.visualViewport;
      var vh = vv ? vv.height : window.innerHeight;
      var keyboardOpen = vh < baseInnerHeight * 0.85;
      var text = 'event: ' + eventName
        + '\\nkeyboard: ' + (keyboardOpen ? 'open' : 'closed')
        + '\\nlayout innerHeight: ' + window.innerHeight
        + '\\nvisual height: ' + (vv ? vv.height : 'N/A')
        + '\\nvisual offsetTop: ' + (vv ? vv.offsetTop : 'N/A');
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('viewportInfo', text, keyboardOpen);
      }
    }
    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', function() {
        reportViewport('visual-resize');
      });
    }
    reportViewport('page-loaded');
  </script>
</body>
</html>
''';

  void _registerHandler() {
    _controller?.addJavaScriptHandler(
      handlerName: 'viewportInfo',
      callback: (args) {
        if (!mounted || args.isEmpty) return null;
        final open = args.length > 1 && args[1] == true;
        setState(() {
          _viewportInfo = '${args[0]}';
          _keyboardState = open ? '弹起' : '收起';
        });
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('软键盘避让 RESIZE_VISUAL')),
      drawer: myDrawer(context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.all(10),
            child: const Text(
              '键盘收起正常：橙色栏不动，innerHeight 稳定，visual height 恢复变大。',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(data: _testHtml),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                _registerHandler();
              },
              onLoadStop: (_, __) => _registerHandler(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '键盘状态：$_keyboardState',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _viewportInfo,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
