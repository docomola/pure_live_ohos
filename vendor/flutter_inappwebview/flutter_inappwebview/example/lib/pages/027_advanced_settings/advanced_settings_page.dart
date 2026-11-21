/// Demo 27: 高级设置项
///
/// 功能说明：集中演示 InAppWebViewSettings 中 OHOS 支持的设置项。
/// 内嵌测试页专门为「肉眼可见对照」设计：
///   - blockNetworkImage：开启后网络图片不再显示；
///   - minimumFontSize：调大后原本 6px 的小字会被强制放大；
///   - initialScale：改变后整页缩放比例可见变化；
///   - preferredContentMode：切换移动/桌面 UA。
/// 「应用设置」后自动 reload 使其生效，并可「读取当前设置」回读确认。
///  ArkWeb 内核升级到 M132 版本后因内核废弃 Web SQL，对 Web SQL 数据库的管理失效。
/// OHOS 不支持的设置已移除：
///   - databaseEnabled：ArkWeb M132+ 废弃 Web SQL，openDatabase() 不存在
///   - hardwareAcceleration / layoutAlgorithm / clearCache（ETS 无对应字段）
///   - needInitialFocus / javaScriptCanOpenWindowsAutomatically（ETS 无对应字段）

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_AdvancedSettings';

/// AdvancedSettingsPage - 高级设置项演示
class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  InAppWebViewController? _controller;

  // WebView 重建计数器：部分设置仅在构建时生效（如 blockNetworkImage），
  // 修改后递增此值以强制 WebView 重建。
  int _webViewKey = 0;

  // 开关类设置
  bool _blockNetworkImage = false;
  bool _blockNetworkLoads = false;
  bool _allowFileAccessFromFileURLs = false;
  bool _allowUniversalAccessFromFileURLs = false;

  // 数值类设置
  int _minimumFontSize = 8;
  int _minimumLogicalFontSize = 8;
  int _initialScale = 0;

  // 枚举类设置
  int _mixedContentModeIdx = 0;
  int _preferredContentModeIdx = 0;

  String _statusText = '调整下方设置后点「应用设置 + 重载」，观察 WebView 变化';
  bool _statusIsError = false;
  String _readbackText = '';

  /// 测试页 HTML：为每个可见设置准备对照元素
  static const String _testHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: sans-serif; padding: 16px; }
    .row { padding:10px; margin:8px 0; border-radius:8px; background:#f5f5f5; }
    .tag { font-weight:bold; color:#1976d2; }
    img { width: 90px; height:90px; margin-top:6px; border:1px solid #ccc; }
    .tiny { font-size:6px; color:#333; }
    .db-result { margin-top:6px; padding:6px; border-radius:4px;
                 background:#eee; font-size:13px; }
    button { padding:8px 12px; border:none; border-radius:5px;
             background:#388e3c; color:#fff; font-size:14px; }
  </style>
</head>
<body>
  <div class="row">
    <span class="tag">blockNetworkImage</span> —— 下面这张网络图片，开启后应消失：
    <br><img src="https://placehold.co/90x90/1976d2/fff?text=IMG">
  </div>
  <div class="row">
    <span class="tag">minimumFontSize</span> —— 下面这行是 6px 小字，调大后会被放大：
    <p class="tiny">这是 6px 的极小文字 tiny text 12345 tiny text</p>
  </div>
  <div class="row">
    <span class="tag">initialScale</span> —— 改变缩放后整页比例会变化。
  </div>
  <div class="row">
    <span class="tag">preferredContentMode</span> —— 当前 UA：
    <div class="db-result" id="ua-area"></div>
  </div>
  <script>
    document.getElementById('ua-area').innerText = navigator.userAgent;
  </script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
  }

  @override
  void dispose() {
    dev.log('Page disposed', name: _kTag);
    super.dispose();
  }

  void _setStatus(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
      _statusIsError = isError;
    });
  }

  // ─── 核心功能方法 ────────────────────────────────────────────────────────

  InAppWebViewSettings _buildSettings() {
    final mixedContentModes = [
      MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
    ];
    final contentModes = [
      UserPreferredContentMode.RECOMMENDED,
      UserPreferredContentMode.MOBILE,
      UserPreferredContentMode.DESKTOP,
    ];
    return InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      blockNetworkImage: _blockNetworkImage,
      blockNetworkLoads: _blockNetworkLoads,
      minimumFontSize: _minimumFontSize,
      minimumLogicalFontSize: _minimumLogicalFontSize,
      initialScale: _initialScale,
      mixedContentMode: mixedContentModes[_mixedContentModeIdx],
      allowFileAccessFromFileURLs: _allowFileAccessFromFileURLs,
      allowUniversalAccessFromFileURLs: _allowUniversalAccessFromFileURLs,
      preferredContentMode: contentModes[_preferredContentModeIdx],
    );
  }

  Future<void> _applySettings() async {
    dev.log('_applySettings called (rebuild)', name: _kTag);
    // blockNetworkImage / initialScale 等仅在 OhosWebView 构建时生效，
    // 因此通过 initialSettings + ValueKey 强制重建 WebView。
    setState(() {
      _webViewKey++;
    });
    _setStatus('设置已应用（WebView 重建），观察各对照区变化');
  }

  Future<void> _getSettings() async {
    dev.log('_getSettings called', name: _kTag);
    final s = _buildSettings();
    if (!mounted) return;
    setState(() {
      _readbackText = '当前 local initialSettings:\n'
          'blockNetworkImage=${s.blockNetworkImage}\n'
          'blockNetworkLoads=${s.blockNetworkLoads}\n'
          'minimumFontSize=${s.minimumFontSize}\n'
          'minimumLogicalFontSize=${s.minimumLogicalFontSize}\n'
          'initialScale=${s.initialScale}\n'
          'mixedContentMode=${s.mixedContentMode?.toNativeValue()}\n'
          'preferredContentMode=${s.preferredContentMode?.toNativeValue()}\n'
          'allowFileAccessFromFileURLs=${s.allowFileAccessFromFileURLs}\n'
          'allowUniversalAccess=${s.allowUniversalAccessFromFileURLs}';
    });
    _setStatus('已读取当前设置（见下方回读区）');
  }

  // ─── UI 构建 ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[027] 高级设置项')),
      body: Column(
        children: [
          _hintBanner(
            'WebView 里每块灰色区域对应一个设置项。调整下方控件后点「应用设置'
            ' + 重载」，即可看到图片消失、小字放大、缩放变化、UA'
            ' 变化等直观效果。',
          ),
          // 设置控制区
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('可见效果设置'),
                  _switchTile('blockNetworkImage（屏蔽网络图片）',
                      _blockNetworkImage,
                      (v) => setState(() => _blockNetworkImage = v)),
                  _sliderTile('minimumFontSize（最小字号）',
                      _minimumFontSize, 0, 40,
                      (v) => setState(() => _minimumFontSize = v.round())),
                  _sliderTile('initialScale（初始缩放 %）',
                      _initialScale, 0, 200,
                      (v) => setState(() => _initialScale = v.round())),
                  _dropdownTile('preferredContentMode',
                      ['RECOMMENDED', 'MOBILE', 'DESKTOP'],
                      _preferredContentModeIdx,
                      (v) => setState(() => _preferredContentModeIdx = v)),
                  const Divider(),
                  _sectionTitle('其它设置'),
                  _switchTile('blockNetworkLoads', _blockNetworkLoads,
                      (v) => setState(() => _blockNetworkLoads = v)),
                  _switchTile('allowFileAccessFromFileURLs',
                      _allowFileAccessFromFileURLs,
                      (v) => setState(
                          () => _allowFileAccessFromFileURLs = v)),
                  _switchTile('allowUniversalAccessFromFileURLs',
                      _allowUniversalAccessFromFileURLs,
                      (v) => setState(
                          () => _allowUniversalAccessFromFileURLs = v)),
                  _sliderTile('minimumLogicalFontSize',
                      _minimumLogicalFontSize, 0, 40,
                      (v) =>
                          setState(() => _minimumLogicalFontSize = v.round())),
                  _dropdownTile('mixedContentMode',
                      ['ALWAYS_ALLOW', 'NEVER_ALLOW', 'COMPATIBILITY'],
                      _mixedContentModeIdx,
                      (v) => setState(() => _mixedContentModeIdx = v)),
                ],
              ),
            ),
          ),
          // 操作按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applySettings,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('应用设置 + 重载'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getSettings,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('读取当前设置'),
                  ),
                ),
              ],
            ),
          ),
          // 状态 + 回读
          _resultPanel(),
          const Divider(height: 1),
          // WebView 区域
          Expanded(
            child: InAppWebView(
              key: ValueKey('adv_$_webViewKey'),
              initialData: InAppWebViewInitialData(data: _testHtml),
              initialSettings: _buildSettings(),
              onWebViewCreated: (controller) {
                _controller = controller;
                dev.log('onWebViewCreated', name: _kTag);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxHeight: 110),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(_statusIsError ? Icons.error : Icons.info_outline,
                  size: 16,
                  color: _statusIsError ? Colors.red : Colors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_statusText,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _statusIsError
                            ? Colors.red
                            : Colors.black87)),
              ),
            ]),
            if (_readbackText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_readbackText,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.teal)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hintBanner(String text) {
    return Container(
      width: double.infinity,
      color: Colors.blue[50],
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4)),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(t,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.indigo)),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _sliderTile(String label, int value, int min, int max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 170,
            child: Text('$label: $value',
                style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            min: min.toDouble(),
            max: max.toDouble(),
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _dropdownTile(String label, List<String> options, int valueIdx,
      ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 170,
            child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: DropdownButton<int>(
            isExpanded: true,
            value: valueIdx,
            items: List.generate(
                options.length,
                (i) => DropdownMenuItem(
                    value: i,
                    child: Text(options[i],
                        style: const TextStyle(fontSize: 12)))),
            onChanged: (v) => onChanged(v ?? 0),
          ),
        ),
      ],
    );
  }
}
