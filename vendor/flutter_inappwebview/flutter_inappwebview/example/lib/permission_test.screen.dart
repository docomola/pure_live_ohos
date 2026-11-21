import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// 权限请求测试页面。
///
/// ## 测试步骤
///
/// ### onPermissionRequest 回调验证
/// 1. 点击 WebView 中的「Request Camera」按钮
/// 2. 观察 Dart 层 `onPermissionRequest` 回调是否触发
/// 3. 确认回调收到 `resources: [CAMERA]`
/// 4. 观察系统权限弹框（如有）
///    - 点击"允许" → WebView 页面显示 "GRANTED"
///    - 点击"拒绝" → WebView 页面显示 "DENIED"
///
/// ### onPermissionRequestCanceled 回调验证
/// 1. 点击「Request Camera」或「Request Microphone」
/// 2. 在系统权限弹框出现后，快速点击「刷新」按钮
/// 3. 观察 `onPermissionRequestCanceled` 是否触发
///
/// ## 期望结果
/// | 操作 | 期望回调 | 期望 resources |
/// |------|----------|----------------|
/// | 点击 Request Camera   | onPermissionRequest | [CAMERA] |
/// | 点击 Request Microphone | onPermissionRequest | [MICROPHONE] |
/// | 点击 Request Camera & Microphone | onPermissionRequest | [CAMERA_AND_MICROPHONE] 或 [CAMERA, MICROPHONE] |
/// | 权限请求中刷新页面 | onPermissionRequestCanceled | 同请求的 resources |
class PermissionTestScreen extends StatefulWidget {
  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  InAppWebViewController? _webViewController;
  final List<_PermissionLogEntry> _logs = [];

  void _addLog(String type, List<PermissionResourceType> resources,
      {bool? success}) {
    setState(() {
      _logs.insert(
        0,
        _PermissionLogEntry(
          type: type,
          resources: resources,
          success: success,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _reload() async {
    await _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission 权限测试'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _logs.clear()),
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label: const Text('清空', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      drawer: myDrawer(context: context),
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
                  '1. 点击 WebView 中的权限按钮\n'
                  '2. 观察下方回调日志\n'
                  '3. 系统弹框时: 允许→页面显示 GRANTED / 拒绝→页面显示 DENIED',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
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
              onPermissionRequest:
                  (controller, permissionRequest) async {
                _addLog('onPermissionRequest', permissionRequest.resources,
                    success: true);
                return PermissionResponse(
                  resources: permissionRequest.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onPermissionRequestCanceled:
                  (controller, permissionRequest) {
                _addLog('onPermissionRequestCanceled',
                    permissionRequest.resources,
                    success: true);
              },
            ),
          ),

          // 刷新按钮
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
                // 期望结果参考
                const Text('✅ 期望: [CAMERA] / [MICROPHONE]',
                    style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ),

          const Divider(height: 1),

          // 期望结果表
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('期望结果:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 2),
                Text(
                  'Camera         → onPermissionRequest: [CAMERA]\n'
                  'Microphone     → onPermissionRequest: [MICROPHONE]\n'
                  'Both           → onPermissionRequest: [CAMERA, MICROPHONE]\n'
                  '请求中刷新      → onPermissionRequestCanceled',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
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
                          'resources: [${entry.resources.map((r) => r.toValue()).join(', ')}]  '
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
  final DateTime timestamp;

  _PermissionLogEntry({
    required this.type,
    required this.resources,
    this.success,
    required this.timestamp,
  });

  String _formatTime() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}
