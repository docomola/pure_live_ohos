/// Demo 039: Issue #322 keep-alive 后台回前台切换崩溃复现
///
/// 复现路径（见 CPF-Flutter/flutter_inappwebview#322）：
/// 1. keep-alive WebView 打开页面 A
/// 2. 应用长时间后台（ArkUI 渲染层回收，进程未杀）
/// 3. 回前台（ArkUI initialRender 重建）
/// 4. 在重建窗口内 disposeKeepAlive(旧) + 新建 InAppWebViewKeepAlive 打开页面 B
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';

const String _kTag = 'KeepAliveSwitchCrash';

const String _htmlPageA = '''
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{margin:0;font-family:sans-serif;background:#ffcdd2;padding:24px}
h1{color:#b71c1c}</style></head>
<body><h1>Page A (keep-alive)</h1><p>后台回来后在重建窗口内点「Issue 复现切换」。</p></body></html>
''';

const String _htmlPageB = '''
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{margin:0;font-family:sans-serif;background:#bbdefb;padding:24px}
h1{color:#0d47a1}</style></head>
<body><h1>Page B (new keep-alive)</h1><p>切换成功则未崩溃。</p></body></html>
''';

/// KeepaliveSwitchCrashPage - #322 崩溃复现
class KeepaliveSwitchCrashPage extends StatefulWidget {
  const KeepaliveSwitchCrashPage({super.key});

  @override
  State<KeepaliveSwitchCrashPage> createState() =>
      _KeepaliveSwitchCrashPageState();
}

class _KeepaliveSwitchCrashPageState extends State<KeepaliveSwitchCrashPage>
    with WidgetsBindingObserver {
  final EventLogController _logger = EventLogController();

  InAppWebViewKeepAlive _keepAlive = InAppWebViewKeepAlive();
  Key _webViewKey = UniqueKey();
  bool _isPageB = false;
  bool _autoSwitchOnResume = true;
  bool _switchInFlight = false;
  bool _wasInBackground = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _log('start Page A, keepAlive=${_keepAlive.hashCode}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logger.dispose();
    super.dispose();
  }

  void _log(String message) {
    _logger.log(_kTag, message);
  }

  /// Issue #322 顺序：先 disposeKeepAlive(旧)，再创建新 KeepAlive + WebView。
  Future<void> _issueReproSwitch() async {
    if (_switchInFlight) {
      _log('switch skipped (already running)');
      return;
    }
    _switchInFlight = true;
    final oldKeepAlive = _keepAlive;
    final toPageB = !_isPageB;

    try {
      _log('disposeKeepAlive(old=${oldKeepAlive.hashCode}) …');
      await InAppWebViewController.disposeKeepAlive(oldKeepAlive);
      _log('disposeKeepAlive done');

      if (!mounted) return;

      setState(() {
        _keepAlive = InAppWebViewKeepAlive();
        _isPageB = toPageB;
        _webViewKey = UniqueKey();
      });
      _log(
        'new keepAlive=${_keepAlive.hashCode} → Page ${toPageB ? "B" : "A"}',
      );
    } catch (e, st) {
      _logger.logError(_kTag, 'switch failed: $e', error: e, stackTrace: st);
    } finally {
      _switchInFlight = false;
    }
  }

  /// 对照：前台直接切换（通常不崩）。
  Future<void> _foregroundSwitch() async {
    _log('foreground switch (same repro order, no background)');
    await _issueReproSwitch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
      _pausedAt = DateTime.now();
      _log('lifecycle → $state');
      return;
    }

    if (state != AppLifecycleState.resumed || !_wasInBackground) {
      return;
    }

    final pausedMs = _pausedAt == null
        ? '?'
        : '${DateTime.now().difference(_pausedAt!).inSeconds}s';
    _log('lifecycle → resumed (background ~$pausedMs)');
    _wasInBackground = false;

    if (!_autoSwitchOnResume) {
      _log('auto switch OFF — tap「Issue 复现切换」 manually');
      return;
    }

    _log('auto switch scheduled (post-frame, #322 rebuild window)');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _issueReproSwitch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageLabel = _isPageB ? 'B' : 'A';
    final pageColor = _isPageB ? Colors.blue : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('[039] KeepAlive 切换崩溃复现'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '【手动】1. 确认当前为 Page A（红底）\n'
                  '2. Home 键退后台，等待 ≥10 分钟（越长越容易触发 ArkUI 重建）\n'
                  '3. 回前台；若开启「回前台自动切换」会在首帧自动执行 #322 路径\n'
                  '4. 或回前台后立即点「Issue 复现切换」\n\n'
                  '崩溃：TypeError getController of null\n'
                  '修复验证：br_v6.1.5_ohos_dev_Crash_fix (b28c7011)',
                  style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.grey.shade800),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Chip(
                  label: Text(
                    '当前 Page $pageLabel',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: pageColor.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'keepAlive=${_keepAlive.hashCode}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InAppWebView(
                  key: _webViewKey,
                  keepAlive: _keepAlive,
                  initialSettings: InAppWebViewSettings(
                    useHybridComposition: true,
                    javaScriptEnabled: true,
                  ),
                  initialData: InAppWebViewInitialData(
                    data: _isPageB ? _htmlPageB : _htmlPageA,
                    mimeType: 'text/html',
                    encoding: 'utf-8',
                  ),
                  onWebViewCreated: (controller) {
                    _log('onWebViewCreated viewId=${controller.getViewId()}');
                  },
                  onLoadStop: (controller, url) {
                    _log('onLoadStop Page $pageLabel');
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _issueReproSwitch,
                  child: const Text('Issue 复现切换 (dispose旧 → 新KeepAlive)'),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: _foregroundSwitch,
                  child: const Text('前台对照切换（通常不崩）'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('回前台自动切换', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    'resume 后首帧自动走 #322 路径',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _autoSwitchOnResume,
                  onChanged: (v) => setState(() => _autoSwitchOnResume = v),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: EventLogPanel(controller: _logger, height: 130),
          ),
        ],
      ),
    );
  }
}
