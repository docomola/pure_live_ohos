/// Demo 029: WebView JS Prompt 回调丢失与销毁兜底
///
/// 功能说明：验证 onJsPrompt 回调在 WebView 销毁时的兜底机制。
/// 对应修复：InAppWebViewClient 维护 pendingJsDialogs 注册表，dispose 时
/// forceCancel 所有未 resolve 的 JsResult，避免 JS 线程永久挂起。
///
/// 压力测试：50 次 prompt 连发 + 立即 dispose WebView，验证兜底机制。
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';
import '../../common/test_button.dart';
import '../../common/test_urls.dart';

const String _kTag = 'InAppWebView_JsPromptStress';

class WebviewJsPromptPage extends StatefulWidget {
  const WebviewJsPromptPage({super.key});

  @override
  State<WebviewJsPromptPage> createState() => _WebviewJsPromptPageState();
}

class _WebviewJsPromptPageState extends State<WebviewJsPromptPage> {
  final EventLogController _logger = EventLogController();
  InAppWebViewController? _controller;
  // 实时计数
  int _sentCount = 0;
  int _completedCount = 0;
  // WebView 是否就绪（用于重建）
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
  }

  @override
  void dispose() {
    dev.log('Page disposed', name: _kTag);
    _logger.dispose();
    _controller = null;
    super.dispose();
  }

  void _resetCounters() {
    _sentCount = 0;
    _completedCount = 0;
  }

  /// 发送一次 prompt 并等待 JS 返回（confirm/cancel 模式下 JS 会立即返回，
  /// neverReply 模式下 JS 线程会阻塞直到销毁兜底 forceCancel）。
  Future<void> _sendOnePrompt() async {
    final c = _controller;
    if (c == null) {
      _logger.log(_kTag, 'controller 为空，跳过');
      return;
    }
    _sentCount++;
    _updateCounters();
    try {
      await c.evaluateJavascript(
          source:
              "console.log('prompt result=' + prompt('msg#$_sentCount', 'default'))");
      _completedCount++;
      _updateCounters();
      _logger.log(_kTag, 'prompt #$_sentCount 完成');
    } catch (e) {
      _logger.logError(_kTag, 'prompt #$_sentCount 异常', error: e);
    }
  }

  /// 压力测试：连发 50 次 prompt 后立即 dispose WebView。
  Future<Object?> _stressTest() async {
    _logger.log(_kTag, '=== 压力测试开始: 50 次 prompt + 立即 dispose ===');
    for (int i = 0; i < 50; i++) {
      _sendOnePrompt();
    }
    await Future.delayed(const Duration(milliseconds: 50));
    await _disposeWebView();
    _logger.log(_kTag,
        '=== 压力测试结束: sent=$_sentCount completed=$_completedCount (pending=${_sentCount - _completedCount}) ===');
    return 'sent=$_sentCount, completed=$_completedCount, pending=${_sentCount - _completedCount}';
  }

  /// 重建 WebView：dispose 后重新创建，验证资源清理后可正常复用。
  Future<Object?> _rebuildWebView() async {
    await _disposeWebView();
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _webViewReady = false;
      _resetCounters();
    });
    _logger.log(_kTag, 'WebView 已重建，可继续测试');
    return 'WebView rebuilt';
  }

  Future<void> _disposeWebView() async {
    final c = _controller;
    if (c == null) {
      return;
    }
    try {
      await c.evaluateJavascript(source: '');
    } catch (_) {
      // ignore: WebView 可能已不可用
    }
    // 调用 dispose 触发 InAppWebViewClient.dispose() 兜底
    // 注意：InAppWebViewController 没有 public dispose，这里通过重建 Key 让 Widget 重建。
    setState(() {
      _controller = null;
      _webViewReady = false;
    });
    _logger.log(_kTag, 'WebView 已销毁 (pending=${_sentCount - _completedCount})');
  }

  void _updateCounters() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[029] JS Prompt 回调丢失/销毁兜底')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                children: [
                  _counterChip('发送', _sentCount, Colors.blue),
                  const SizedBox(width: 8),
                  _counterChip('完成', _completedCount, Colors.green),
                  const SizedBox(width: 8),
                  _counterChip(
                      'pending', _sentCount - _completedCount, Colors.orange),
                ],
              ),
            ),
            // WebView 区域
            SizedBox(
              height: 200,
              child: _webViewReady
                  ? InAppWebView(
                      key: ValueKey('wv_$_sentCount'),
                      initialData: InAppWebViewInitialData(data: kSampleHtml),
                      initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true, isInspectable: true),
                      onWebViewCreated: (c) {
                        _controller = c;
                        _logger.log(_kTag, 'onWebViewCreated');
                      },
                      onConsoleMessage: (controller, msg) {
                        _logger.log(_kTag,
                            'console: ${msg.message} (level=${msg.messageLevel})');
                      },
                      onJsPrompt: (controller, req) async {
                        _logger.log(_kTag,
                            'onJsPrompt: ${req.message} (default=${req.defaultValue})');
                        return JsPromptResponse(
                          handledByClient: true,
                          value: 'replied-#$_sentCount',
                          action: JsPromptResponseAction.CONFIRM,
                        );
                      },
                    )
                  : Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _webViewReady = true),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('创建 WebView'),
                      ),
                    ),
            ),
            // 操作按钮
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  _btn('发送一次 prompt', _sendOnePrompt),
                  _btn('50 次 prompt + 立即 dispose (压力测试)', _stressTest),
                  _btn('重建 WebView', _rebuildWebView),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: EventLogPanel(controller: _logger, height: 160),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterChip(String label, int value, Color color) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.4)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _btn(String l, Future<Object?> Function() fn) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: AsyncTestButton(
            label: l, tag: _kTag, logger: _logger, onPressed: fn),
      );
}
