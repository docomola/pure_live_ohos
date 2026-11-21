/// Demo 38: 边界场景
///
/// 对应用例覆盖度报告：
///   - InAppWebViewSettings 极端配置（极大 textZoom、多 ContentBlocker）
///   - canGoBack() 在无历史时的边界
///   - getContentHeight() 在空白/短页时的返回值
///
/// 对应接口：
///   - setSettings/getSettings、canGoBack、getContentHeight、getContentWidth、clearHistory

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';
import '../../common/test_button.dart';
import '../../common/test_urls.dart';

const String _kTag = 'InAppWebView_BoundaryScenarios';

class BoundaryScenariosPage extends StatefulWidget {
  const BoundaryScenariosPage({super.key});

  @override
  State<BoundaryScenariosPage> createState() => _BoundaryScenariosPageState();
}

class _BoundaryScenariosPageState extends State<BoundaryScenariosPage> {
  final EventLogController _logger = EventLogController();
  InAppWebViewController? _controller;

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

  Future<Object?> _queryNoHistory() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.loadUrl(urlRequest: URLRequest(url: WebUri(kBlankUrl)));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await c.clearHistory();
    final canBack = await c.canGoBack();
    final canForward = await c.canGoForward();
    return 'clearHistory 后 canGoBack=$canBack, canGoForward=$canForward';
  }

  Future<Object?> _queryBlankContentSize() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.loadUrl(urlRequest: URLRequest(url: WebUri(kBlankUrl)));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final h = await c.getContentHeight();
    final w = await c.getContentWidth();
    return 'about:blank contentHeight=$h, contentWidth=$w';
  }

  Future<Object?> _extremeTextZoom() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.setSettings(
      settings: InAppWebViewSettings(
        javaScriptEnabled: true,
        textZoom: 500,
      ),
    );
    final settings = await c.getSettings();
    return 'textZoom=500 已设置，读回 textZoom=${settings?.textZoom}';
  }

  Future<Object?> _manyContentBlockers() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    final blockers = <ContentBlocker>[];
    for (var i = 0; i < 30; i++) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: '.*ads-block-demo-$i\\.example\\.com.*',
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }
    await c.setSettings(
      settings: InAppWebViewSettings(
        javaScriptEnabled: true,
        contentBlockers: blockers,
      ),
    );
    return 'contentBlockers 数量=${blockers.length}（期望 30）';
  }

  Future<Object?> _zeroTextZoom() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.setSettings(
      settings: InAppWebViewSettings(
        javaScriptEnabled: true,
        textZoom: 1,
      ),
    );
    final settings = await c.getSettings();
    return 'textZoom=1 读回=${settings?.textZoom}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[037] 边界场景')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  '覆盖报告缺失：极端 Settings、无历史 canGoBack、空白页内容尺寸。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: InAppWebView(
                    initialData: InAppWebViewInitialData(
                      data:
                          '<html><body style="font-size:16px">边界场景测试页<br>短内容</body></html>',
                    ),
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
                AsyncTestButton(
                  label: '无历史：clearHistory 后 canGoBack',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _queryNoHistory,
                ),
                AsyncTestButton(
                  label: '空白页 getContentHeight / getContentWidth',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _queryBlankContentSize,
                ),
                AsyncTestButton(
                  label: '极端 textZoom=500',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _extremeTextZoom,
                ),
                AsyncTestButton(
                  label: '极小 textZoom=1',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _zeroTextZoom,
                ),
                AsyncTestButton(
                  label: '30 条 ContentBlocker 列表',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _manyContentBlockers,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: EventLogPanel(controller: _logger, height: 280),
          ),
        ],
      ),
    );
  }
}
