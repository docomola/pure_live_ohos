/// Demo 11: WebstorageManager
///
/// 功能说明：展示 WebStorageManager 跨来源管理 Web Storage 数据。
/// 页面下半部分嵌入 WebView 自动写入 localStorage，上半部分查询/删除。
///
/// 对应接口：
///   - getOrigins(): Future<List<WebStorageOrigin>>
///   - deleteAllData(): Future<void>
///   - deleteOrigin(origin): Future<void>
///   - getQuotaForOrigin(origin): Future<int>
///   - getUsageForOrigin(origin): Future<int>

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_WebstorageManager';

class WebstorageManagerPage extends StatefulWidget {
  const WebstorageManagerPage({super.key});

  @override
  State<WebstorageManagerPage> createState() => _WebstorageManagerPageState();
}

class _WebstorageManagerPageState extends State<WebstorageManagerPage> {
  List<WebStorageOrigin> _origins = [];
  int? _quota;
  int? _usage;
  String _status = '点下方查询按钮获取来源数据';
  String _selectedOrigin = '';

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

  Future<void> _getOrigins() async {
    try {
      final origins = await WebStorageManager.instance().getOrigins();
      if (!mounted) return;
      setState(() {
        _origins = origins;
        _status =
            origins.isEmpty ? '无来源（点「写入数据」后再查询）' : '查询到 ${origins.length} 个来源';
        if (origins.isNotEmpty && _selectedOrigin.isEmpty) {
          _selectedOrigin = origins.first.origin ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _getQuota() async {
    if (_selectedOrigin.isEmpty) {
      setState(() => _status = '请先查询来源');
      return;
    }
    try {
      final quota = await WebStorageManager.instance()
          .getQuotaForOrigin(origin: _selectedOrigin);
      if (!mounted) return;
      setState(() {
        _quota = quota;
        _status = '$_selectedOrigin 配额: $quota';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _getUsage() async {
    if (_selectedOrigin.isEmpty) {
      setState(() => _status = '请先查询来源');
      return;
    }
    try {
      final usage = await WebStorageManager.instance()
          .getUsageForOrigin(origin: _selectedOrigin);
      if (!mounted) return;
      setState(() {
        _usage = usage;
        _status = '$_selectedOrigin 用量: $usage';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _deleteOrigin() async {
    if (_selectedOrigin.isEmpty) {
      setState(() => _status = '请先查询来源');
      return;
    }
    try {
      await WebStorageManager.instance()
          .deleteOrigin(origin: _selectedOrigin);
      if (!mounted) return;
      setState(() {
        _status = '已删除 $_selectedOrigin';
        _origins =
            _origins.where((o) => o.origin != _selectedOrigin).toList();
        _selectedOrigin = _origins.isNotEmpty ? _origins.first.origin! : '';
        _quota = null;
        _usage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  Future<void> _deleteAllData() async {
    try {
      await WebStorageManager.instance().deleteAllData();
      if (!mounted) return;
      setState(() {
        _origins = [];
        _selectedOrigin = '';
        _quota = null;
        _usage = null;
        _status = '已清空所有数据';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '错误：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[011] WebStorageManager存储管理'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                        onPressed: _getOrigins,
                        child: const Text('查询来源')),
                    ElevatedButton(
                        onPressed: _getQuota,
                        child: const Text('查询配额')),
                    ElevatedButton(
                        onPressed: _getUsage,
                        child: const Text('查询用量')),
                    ElevatedButton(
                        onPressed: _deleteOrigin,
                        child: const Text('删除指定来源')),
                    ElevatedButton(
                        onPressed: _deleteAllData,
                        child: const Text('删除所有数据')),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_status, style: const TextStyle(fontSize: 13)),
                if (_quota != null) Text('配额: $_quota', style: const TextStyle(fontSize: 13)),
                if (_usage != null) Text('用量: $_usage', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                const Text('来源列表:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (_origins.isEmpty)
                  const Text('  (空)', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ..._origins.map((o) => ListTile(
                        dense: true,
                        title: Text(
                          'origin=${o.origin}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: o.origin == _selectedOrigin
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: o.origin == _selectedOrigin
                                  ? Colors.blue
                                  : null),
                        ),
                        subtitle: Text(
                            'quota=${o.quota}, usage=${o.usage}',
                            style: const TextStyle(fontSize: 11)),
                        onTap: () =>
                            setState(() => _selectedOrigin = o.origin ?? ''),
                      )),
              ],
            ),
          ),
          const Divider(height: 1),
          // 内嵌 WebView，自动写入 localStorage 数据，为查询提供数据源
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: '''
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{font-family:sans-serif;display:flex;align-items:center;
justify-content:center;height:100vh;margin:0;background:#f5f5f5;
flex-direction:column;text-align:center}
p{color:#666;font-size:13px;margin-top:8px}
button{font-size:15px;padding:10px 24px;background:#1976d2;color:#fff;
border:none;border-radius:8px;margin-top:12px}
</style></head>
<body>
  <h3>WebView (数据源)</h3>
  <p>下方按钮向当前 origin (<span id="origin"></span>) 写入 localStorage。</p>
  <button onclick="writeData()">写入数据</button>
  <p id="msg"></p>
  <script>
    document.getElementById('origin').textContent = location.origin || '(opaque)';
    function writeData() {
      localStorage.setItem('test_key_1', 'hello_world');
      localStorage.setItem('test_key_2', 'foo_bar_' + Date.now());
      document.getElementById('msg').textContent =
        '已写入 ' + localStorage.length + ' 条数据';
    }
  </script>
</body></html>
''',
                baseUrl: WebUri('https://www.baidu.com/'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}