import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// Content Blocker 示例（Android / iOS / macOS / OpenHarmony）。
///
/// 运行：侧栏 → **Content Blocker Demo**
class ContentBlockerExampleScreen extends StatefulWidget {
  const ContentBlockerExampleScreen({super.key});

  @override
  State<ContentBlockerExampleScreen> createState() =>
      _ContentBlockerExampleScreenState();
}

class _ContentBlockerExampleScreenState extends State<ContentBlockerExampleScreen> {
  // 用 initialData + baseUrl 加载，使页面走 HTTP 协议；
  // loadFile 走 WebViewAssetLoader 本地协议，ContentBlocker 不会拦截。
  static const String _demoHtml = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Content Blocker Demo</title>
  <style>
    body { font-family: system-ui, sans-serif; padding: 16px; line-height: 1.5; }
    section { margin-bottom: 24px; padding: 12px; border: 1px solid #ccc; border-radius: 8px; }
    h2 { margin-top: 0; font-size: 1.1rem; }
    .ad-banner {
      background: #ffeb3b;
      padding: 16px;
      text-align: center;
      font-weight: bold;
    }
    img { max-width: 100%; height: auto; margin-top: 8px; border: 1px solid #ddd; }
    .ok { color: #2e7d32; font-weight: bold; }
    .fail { color: #c62828; font-weight: bold; }
    .hint { color: #666; font-size: 0.9rem; }
  </style>
</head>
<body>
  <h1>Content Blocker 演示页</h1>

  <section id="section-block">
    <h2>1. BLOCK — 拦截图片</h2>
    <p class="hint">网络图片，ContentBlocker 可拦截。</p>
    <img id="block-image" alt="block demo"
         src="https://placehold.co/60x60/1976d2/fff.png?text=LOGO"
         height="60" width="60"
         onload="document.getElementById('block-status').innerHTML='<span class=ok>✓ 图片已加载</span>'"
         onerror="document.getElementById('block-status').innerHTML='<span class=fail>✗ 图片被拦截，加载失败</span>'">
    <p id="block-status">等待加载…</p>
    <p class="hint">预期：<b>BLOCK 开</b> → 加载失败；<b>关</b> → 可见蓝色图。</p>
  </section>

  <section id="section-css">
    <h2>2. CSS_DISPLAY_NONE — 隐藏广告条</h2>
    <p>规则匹配 <code>.ad-banner</code> 时，黄色区域应不可见：</p>
    <div class="ad-banner">我是模拟广告横幅，CSS 规则会隐藏我</div>
    <p class="hint">预期：<b>CSS 开</b> → 黄色条消失；<b>关</b> → 可见黄色条。</p>
  </section>

  <section id="section-https">
    <h2>3. MAKE_HTTPS — HTTP 升级</h2>
    <p class="hint">通过 <code>http://</code> 加载百度 favicon（需 MAKE_HTTPS 升级为 https）。</p>
    <img id="http-image" alt="http favicon"
         src="http://www.baidu.com/favicon.ico"
         onload="document.getElementById('https-status').innerHTML='<span class=ok>✓ HTTP 资源已加载</span>'"
         onerror="document.getElementById('https-status').innerHTML='<span class=fail>✗ HTTP 资源加载失败</span>'">
    <p id="https-status">等待加载…</p>
    <p class="hint">预期：<b>MAKE_HTTPS 开</b> → 图片可见；<b>关</b> → 往往失败。</p>
  </section>
</body>
</html>
''';

  bool _blockImages = true;
  bool _hideAds = true;
  bool _upgradeHttp = true;

  InAppWebViewController? _controller;
  double _progress = 1;
  String _status = '等待 WebView 创建…';

  bool get _contentBlockerSupported {
    if (kIsWeb) return false;
    return {
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.ohos,
    }.contains(defaultTargetPlatform);
  }

  List<ContentBlocker> _buildContentBlockers() {
    final blockers = <ContentBlocker>[];

    // MAKE_HTTPS 须在 BLOCK 之前（否则 http 的 .ico/.png 会先被 BLOCK 掉）
    if (_upgradeHttp) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(urlFilter: r"^http://"),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.MAKE_HTTPS,
          ),
        ),
      );
    }

    if (_blockImages) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: r".*\.(png|jpg|jpeg|gif|webp|svg|ico)(\?.*)?$",
            resourceType: [ContentBlockerTriggerResourceType.IMAGE],
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.BLOCK,
          ),
        ),
      );
    }

    if (_hideAds) {
      blockers.add(
        ContentBlocker(
          trigger: ContentBlockerTrigger(
            urlFilter: r".*",
            resourceType: [ContentBlockerTriggerResourceType.DOCUMENT],
          ),
          action: ContentBlockerAction(
            type: ContentBlockerActionType.CSS_DISPLAY_NONE,
            selector: '.ad-banner',
          ),
        ),
      );
    }

    return blockers;
  }

  InAppWebViewSettings _buildSettings() {
    return InAppWebViewSettings(
      isInspectable: kDebugMode,
      javaScriptEnabled: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      contentBlockers: _buildContentBlockers(),
    );
  }

  String get _activeRulesLabel {
    final parts = <String>[];
    if (_upgradeHttp) parts.add('HTTPS');
    if (_blockImages) parts.add('BLOCK');
    if (_hideAds) parts.add('CSS');
    return parts.isEmpty ? '无规则' : parts.join(' + ');
  }

  Future<void> _applyRules({required String reason}) async {
    setState(() {
      _progress = 0;
      _status = '$reason → 应用规则 [$_activeRulesLabel]';
    });

    final controller = _controller;
    if (controller != null) {
      await controller.setSettings(settings: _buildSettings());
      await controller.reload();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('规则: [$_activeRulesLabel]'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onRuleChanged(bool value, void Function(bool) setter, String label) {
    setter(value);
    _applyRules(reason: '已切换 $label');
  }

  Future<void> _applyDemoCss(InAppWebViewController controller) async {
    if (_hideAds) {
      await controller.evaluateJavascript(source: '''
(function() {
  var id = 'flutter-inappwebview-css-display-none-style';
  if (!document.getElementById(id)) {
    var c = document.createElement('style');
    c.id = id;
    c.innerHTML = '.ad-banner { display: none !important; }';
    (document.head || document.documentElement).appendChild(c);
  }
  document.querySelectorAll('.ad-banner').forEach(function(el) {
    el.style.setProperty('display', 'none', 'important');
  });
})();
''');
    } else {
      await controller.evaluateJavascript(source: '''
(function() {
  var el = document.getElementById('flutter-inappwebview-css-display-none-style');
  if (el) el.remove();
  document.querySelectorAll('.ad-banner').forEach(function(node) {
    node.style.removeProperty('display');
  });
})();
''');
    }
  }

  Widget _buildControlPanel() {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('操作说明', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '切换开关会通过 setSettings 更新规则并重新加载，不重建 WebView。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
            if (defaultTargetPlatform == TargetPlatform.ohos)
              Text(
                '平台: OpenHarmony · 规则: $_activeRulesLabel',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('BLOCK 图片'),
              subtitle: const Text('拦截 .png/.jpg/.ico 等'),
              value: _blockImages,
              onChanged: (v) =>
                  _onRuleChanged(v, (x) => _blockImages = x, 'BLOCK'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('隐藏 .ad-banner'),
              subtitle: const Text('CSS_DISPLAY_NONE'),
              value: _hideAds,
              onChanged: (v) =>
                  _onRuleChanged(v, (x) => _hideAds = x, '隐藏广告'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('MAKE_HTTPS'),
              subtitle: const Text('http 子资源 → https'),
              value: _upgradeHttp,
              onChanged: (v) =>
                  _onRuleChanged(v, (x) => _upgradeHttp = x, 'MAKE_HTTPS'),
            ),
            FilledButton.icon(
              onPressed: () => _applyRules(reason: '手动刷新'),
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载演示页'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialSettings: _buildSettings(),
      initialData: InAppWebViewInitialData(
        data: _demoHtml,
        baseUrl: WebUri('https://localhost/'),
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        if (mounted) {
          setState(() => _status = 'WebView 已创建，加载中…');
        }
      },
      onProgressChanged: (controller, progress) {
        if (!mounted) return;
        setState(() => _progress = progress / 100);
      },
      onLoadStart: (controller, url) {
        if (!mounted) return;
        setState(() => _status = '加载中: $url');
      },
      onLoadStop: (controller, url) async {
        await _applyDemoCss(controller);
        if (!mounted) return;
        setState(() {
          _progress = 1;
          _status = '加载完成 [$_activeRulesLabel] — ①图 ②黄条 ③HTTP图';
        });
      },
      onReceivedError: (controller, request, error) {
        if (!mounted) return;
        setState(() =>
            _status = '资源: ${request.url} — ${error.description}');
      },
    );
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_contentBlockerSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('Content Blocker Demo')),
        drawer: myDrawer(context: context),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '当前平台不支持 Content Blocker。\n'
              '请在 Android、iOS、macOS 或 OpenHarmony 设备上运行。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Blocker Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '测试说明',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('如何验证'),
                  content: const SingleChildScrollView(
                    child: Text(
                      '1. BLOCK：下方本地 logo 应加载失败或空白。\n'
                      '2. CSS_DISPLAY_NONE：黄色「模拟广告」应消失（需开启 JS）。\n'
                      '3. MAKE_HTTPS：http://www.baidu.com/favicon.ico 尝试走 HTTPS。\n\n'
                      '切换开关后页面会重新加载，WebView 实例保持不变。',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: myDrawer(context: context),
      body: Column(
        children: [
          SizedBox(
            height: 280,
            child: _buildControlPanel(),
          ),
          if (_progress < 1) const LinearProgressIndicator(),
          Expanded(child: _buildWebView()),
        ],
      ),
    );
  }
}
