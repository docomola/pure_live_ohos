import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class ScrollClampValidationScreen extends StatefulWidget {
  @override
  State<ScrollClampValidationScreen> createState() =>
      _ScrollClampValidationScreenState();
}

class _ScrollClampValidationScreenState
    extends State<ScrollClampValidationScreen> {
  static const String _testHtml = '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 3000px;
        height: 5000px;
        overflow: auto;
        font-family: Arial, sans-serif;
      }
      body {
        background:
          linear-gradient(180deg, #f8fafc 0%, #dbeafe 50%, #cbd5e1 100%);
      }
      .badge {
        position: sticky;
        top: 0;
        left: 0;
        display: inline-block;
        margin: 12px;
        padding: 12px 16px;
        border-radius: 12px;
        background: rgba(15, 23, 42, 0.86);
        color: #fff;
        font-size: 24px;
        z-index: 10;
      }
      .marker {
        position: absolute;
        padding: 12px 16px;
        border-radius: 12px;
        color: #0f172a;
        font-size: 30px;
        font-weight: bold;
        background: rgba(255, 255, 255, 0.9);
        box-shadow: 0 6px 24px rgba(15, 23, 42, 0.12);
      }
      #topLeft { top: 80px; left: 40px; }
      #topRight { top: 80px; right: 40px; }
      #center { top: 2400px; left: 1400px; }
      #bottomLeft { bottom: 80px; left: 40px; }
      #bottomRight { bottom: 80px; right: 40px; }
    </style>
  </head>
  <body>
    <div class="badge">Generic flutter_inappwebview clamp validation page</div>
    <div id="topLeft" class="marker">TOP LEFT</div>
    <div id="topRight" class="marker">TOP RIGHT</div>
    <div id="center" class="marker">CENTER</div>
    <div id="bottomLeft" class="marker">BOTTOM LEFT</div>
    <div id="bottomRight" class="marker">BOTTOM RIGHT</div>
  </body>
</html>
''';

  final List<String> _logs = <String>[];
  InAppWebViewController? _controller;
  int _seq = 0;
  int _lastX = 0;
  int _lastY = 0;
  bool _lastClampedX = false;
  bool _lastClampedY = false;
  double _progress = 0;

  void _appendLog(String tag, String message) {
    final String time = DateTime.now().toIso8601String().split('T').last;
    setState(() {
      _logs.insert(0, '[${_seq++}][$time][$tag] $message');
      if (_logs.length > 80) {
        _logs.removeRange(80, _logs.length);
      }
    });
  }

  Future<void> _scrollTo({required int x, required int y}) async {
    await _controller?.scrollTo(x: x, y: y, animated: false);
    _appendLog('action', 'scrollTo(x: $x, y: $y)');
  }

  Future<void> _scrollToTop() async {
    await _scrollTo(x: 0, y: 0);
  }

  Future<void> _scrollToBottom() async {
    await _scrollTo(x: 0, y: 999999);
  }

  Future<void> _scrollToLeft() async {
    await _scrollTo(x: 0, y: _lastY);
  }

  Future<void> _scrollToRight() async {
    await _scrollTo(x: 999999, y: _lastY);
  }

  Future<void> _scrollToCenter() async {
    await _scrollTo(x: 1400, y: 2400);
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scroll Clamp Validation')),
      drawer: myDrawer(context: context),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '验证方法：先点 Center，再手动拖到四个边界并继续过滚，观察 over 日志中的 clampedX/clampedY。',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: <Widget>[
                      _buildActionButton('Center', _scrollToCenter),
                      _buildActionButton('Top', _scrollToTop),
                      _buildActionButton('Bottom', _scrollToBottom),
                      _buildActionButton('Left', _scrollToLeft),
                      _buildActionButton('Right', _scrollToRight),
                      _buildActionButton('Clear Logs', () {
                        setState(() {
                          _logs.clear();
                          _seq = 0;
                        });
                      }),
                      _buildActionButton('Reload', () {
                        _controller?.reload();
                        _appendLog('action', 'reload()');
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'last scroll=($_lastX, $_lastY), last clamp=(x=$_lastClampedX, y=$_lastClampedY), progress=${(_progress * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Stack(
                children: <Widget>[
                  InAppWebView(
                    initialSettings: InAppWebViewSettings(
                      isInspectable: kDebugMode,
                      overScrollMode: OverScrollMode.ALWAYS,
                    ),
                    initialData: InAppWebViewInitialData(
                      data: _testHtml,
                      baseUrl: WebUri('https://example.com/'),
                      historyUrl: WebUri('https://example.com/'),
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      _appendLog('lifecycle', 'onWebViewCreated');
                    },
                    onLoadStart: (controller, url) {
                      _appendLog('load', 'onLoadStart url=$url');
                    },
                    onLoadStop: (controller, url) {
                      _appendLog('load', 'onLoadStop url=$url');
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onScrollChanged: (controller, x, y) {
                      setState(() {
                        _lastX = x;
                        _lastY = y;
                      });
                      _appendLog('scroll', 'x=$x y=$y');
                    },
                    onOverScrolled: (controller, x, y, clampedX, clampedY) {
                      setState(() {
                        _lastX = x;
                        _lastY = y;
                        _lastClampedX = clampedX;
                        _lastClampedY = clampedY;
                      });
                      _appendLog(
                        'over',
                        'x=$x y=$y clampedX=$clampedX clampedY=$clampedY',
                      );
                    },
                  ),
                  if (_progress < 1.0)
                    LinearProgressIndicator(value: _progress),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                color: const Color(0xFFF8FAFC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Event Logs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text('滚动或点击快捷按钮后，这里会显示事件日志。'),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _logs[index],
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
