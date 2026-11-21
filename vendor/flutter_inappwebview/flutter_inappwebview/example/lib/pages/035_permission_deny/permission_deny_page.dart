/// Demo 36: 权限请求拒绝（DENY）
///
/// 对应用例覆盖度报告：onPermissionRequest 仅有 GRANT 场景，缺少 DENY 后行为验证。
///
/// 步骤：
///   1. 切换「拒绝权限」开关为开（默认 DENY）或关（GRANT）
///   2. 点击 WebView 内 Request Camera / Microphone
///   3. 观察 onPermissionRequest 日志与页面结果文案
///
/// 对应接口：
///   - onPermissionRequest / PermissionResponse(action: DENY|GRANT)
///   - onPermissionRequestCanceled

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_PermissionDeny';

class PermissionDenyPage extends StatefulWidget {
  const PermissionDenyPage({super.key});

  @override
  State<PermissionDenyPage> createState() => _PermissionDenyPageState();
}

class _PermissionDenyPageState extends State<PermissionDenyPage> {
  InAppWebViewController? _webViewController;
  final List<_PermissionLogEntry> _logs = [];
  bool _deny = true;

  void _addLog(String type, List<PermissionResourceType> resources,
      {bool? success, String? detail}) {
    setState(() {
      _logs.insert(
        0,
        _PermissionLogEntry(
          type: type,
          resources: resources,
          success: success,
          detail: detail,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _reload() async {
    await _webViewController?.reload();
  }

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[035] 权限请求 DENY'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _logs.clear()),
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label: const Text('清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 平台 + 步骤说明
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('平台: $defaultTargetPlatform',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  '步骤:\n'
                  '1. 下方开关选择 DENY（拒绝）或 GRANT（允许）\n'
                  '2. 点击 WebView 中的权限按钮\n'
                  '3. 观察 onPermissionRequest 回调日志',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // DENY/GRANT 开关
          SwitchListTile(
            dense: true,
            title: Text(
              _deny ? '当前模式：DENY（回绝权限）' : '当前模式：GRANT（授予权限）',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _deny ? Colors.red : Colors.green,
              ),
            ),
            subtitle: const Text('开=返回 DENY；关=返回 GRANT',
                style: TextStyle(fontSize: 11)),
            value: _deny,
            onChanged: (v) => setState(() => _deny = v),
          ),

          // WebView
          Expanded(
            flex: 3,
            child: InAppWebView(
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              initialFile: 'test_assets/in_app_webview_permission_test.html',
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onPermissionRequest: (controller, permissionRequest) async {
                final action = _deny
                    ? PermissionResponseAction.DENY
                    : PermissionResponseAction.GRANT;
                _addLog(
                  'onPermissionRequest',
                  permissionRequest.resources,
                  success: !_deny,
                  detail: '返回: $action',
                );
                return PermissionResponse(
                  resources: permissionRequest.resources,
                  action: action,
                );
              },
              onPermissionRequestCanceled: (controller, permissionRequest) {
                _addLog(
                  'onPermissionRequestCanceled',
                  permissionRequest.resources,
                  success: true,
                  detail: '已取消',
                );
              },
            ),
          ),

          // 操作按钮栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新 (测试 onPermissionRequestCanceled)'),
                ),
                Text(
                  _deny ? '期望页面显示 DENIED' : '期望页面显示 GRANTED',
                  style: TextStyle(
                    fontSize: 11,
                    color: _deny ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 期望结果表
          Container(
            color: _deny ? Colors.red.shade50 : Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('期望回调:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _deny
                      ? 'onPermissionRequest → DENY\n'
                          '页面应显示 DENIED (NotAllowedError)'
                      : 'onPermissionRequest → GRANT\n'
                          '页面应显示 GRANTED',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          // 回调日志
          Expanded(
            flex: 2,
            child: _logs.isEmpty
                ? const Center(
                    child: Text('点击 WebView 中的按钮开始测试',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final entry = _logs[index];
                      final isSuccess =
                          entry.success == null || entry.success!;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.type == 'onPermissionRequest'
                              ? Icons.security
                              : Icons.cancel_outlined,
                          color: isSuccess ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        title: Row(
                          children: [
                            Text(entry.type,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            Text(
                              isSuccess ? '✅' : '❌',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'resources: [${entry.resources.map((r) => r.toValue()).join(', ')}]'
                          '${entry.detail != null ? '  detail: ${entry.detail}' : ''}  '
                          '${entry._formatTime()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        tileColor:
                            index % 2 == 0 ? Colors.grey.shade50 : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PermissionLogEntry {
  final String type;
  final List<PermissionResourceType> resources;
  final bool? success;
  final String? detail;
  final DateTime timestamp;

  _PermissionLogEntry({
    required this.type,
    required this.resources,
    this.success,
    this.detail,
    required this.timestamp,
  });

  String _formatTime() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}
