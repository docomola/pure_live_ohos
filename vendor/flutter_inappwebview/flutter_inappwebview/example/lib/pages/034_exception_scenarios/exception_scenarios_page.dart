/// Demo 35: 异常场景（参数 / 状态 / 超时）
///
/// 对应用例覆盖度报告「场景覆盖缺失」：
///   - 参数异常：无效 URL 的 loadUrl、空字符串 / 超长脚本 evaluateJavascript
///   - 状态异常：controller.dispose() 后再调用 getUrl / reload
///   - 超时异常：异步方法挂 timeout，观察超时或正常返回
///
/// 对应接口：
///   - InAppWebViewController.loadUrl / evaluateJavascript / getUrl / reload / dispose

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';
import '../../common/test_button.dart';
import '../../common/test_urls.dart';

const String _kTag = 'InAppWebView_ExceptionScenarios';

class ExceptionScenariosPage extends StatefulWidget {
  const ExceptionScenariosPage({super.key});

  @override
  State<ExceptionScenariosPage> createState() => _ExceptionScenariosPageState();
}

class _ExceptionScenariosPageState extends State<ExceptionScenariosPage> {
  final EventLogController _logger = EventLogController();
  InAppWebViewController? _controller;
  bool _disposed = false;

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

  Future<Object?> _loadInvalidUrl() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    // 故意使用非法 URL，观察平台侧是否抛错或被吞掉
    await c.loadUrl(urlRequest: URLRequest(url: WebUri('ht!tp://bad url')));
    return 'loadUrl(无效 URL) 已调用';
  }

  Future<Object?> _evalEmptyScript() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    final result = await c.evaluateJavascript(source: '');
    return 'evaluateJavascript("") -> $result';
  }

  Future<Object?> _evalHugeScript() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    final huge = 'var x="";' + ('x+="a";' * 20000) + 'x.length;';
    final result = await c.evaluateJavascript(source: huge);
    return 'evaluateJavascript(超长脚本) -> $result';
  }

  Future<Object?> _disposeThenCall() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    c.dispose();
    setState(() {
      _disposed = true;
      _controller = null;
    });
    _logger.log(_kTag, 'controller.dispose() 已调用，随后尝试 getUrl/reload');
    try {
      final url = await c.getUrl();
      _logger.log(_kTag, 'dispose 后 getUrl -> $url');
    } catch (e, s) {
      _logger.logError(_kTag, 'dispose 后 getUrl 异常 -> $e',
          error: e, stackTrace: s);
    }
    try {
      await c.reload();
      _logger.log(_kTag, 'dispose 后 reload 完成（未抛异常）');
    } catch (e, s) {
      _logger.logError(_kTag, 'dispose 后 reload 异常 -> $e',
          error: e, stackTrace: s);
    }
    return '状态异常场景已执行，请查看日志（需重建 WebView 才能继续测）';
  }

  Future<Object?> _timeoutEvaluate() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    try {
      final result = await c
          .evaluateJavascript(source: '1+1')
          .timeout(const Duration(milliseconds: 500));
      return 'timeout(500ms) 内返回 -> $result';
    } on TimeoutException catch (e) {
      return 'TimeoutException: $e';
    }
  }

  Future<Object?> _timeoutLoadUrl() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    try {
      await c
          .loadUrl(urlRequest: URLRequest(url: WebUri(kFlutterDevUrl)))
          .timeout(const Duration(milliseconds: 1));
      return 'timeout(1ms) 内 loadUrl 完成（极少见）';
    } on TimeoutException catch (e) {
      return 'TimeoutException(预期可能触发): $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[034] 异常场景(参数/状态/超时)')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  '覆盖报告缺失场景：参数异常、dispose 后调用、异步 timeout。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: _disposed
                      ? const Center(
                          child: Text('Controller 已 dispose，请返回后重新进入本页'))
                      : InAppWebView(
                          initialUrlRequest:
                              URLRequest(url: WebUri(kBlankUrl)),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                          ),
                          onWebViewCreated: (controller) {
                            _controller = controller;
                            _logger.log(_kTag, 'onWebViewCreated');
                          },
                          onLoadStop: (controller, url) {
                            _logger.log(_kTag, 'onLoadStop: $url');
                          },
                        ),
                ),
                const SizedBox(height: 8),
                const Text('参数异常',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                AsyncTestButton(
                  label: 'loadUrl(无效 URL)',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _loadInvalidUrl,
                ),
                AsyncTestButton(
                  label: 'evaluateJavascript("")',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _evalEmptyScript,
                ),
                AsyncTestButton(
                  label: 'evaluateJavascript(超长脚本)',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _evalHugeScript,
                ),
                const SizedBox(height: 8),
                const Text('状态异常',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                AsyncTestButton(
                  label: 'dispose() 后调用 getUrl/reload',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _disposeThenCall,
                ),
                const SizedBox(height: 8),
                const Text('超时异常',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                AsyncTestButton(
                  label: 'evaluateJavascript.timeout(500ms)',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _timeoutEvaluate,
                ),
                AsyncTestButton(
                  label: 'loadUrl.timeout(1ms)',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _timeoutLoadUrl,
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
