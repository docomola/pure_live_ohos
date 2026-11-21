/// Demo 34: ChromeSafariBrowser / InAppLocalhostServer
///
/// 功能说明：演示 ChromeSafariBrowser 静态/实例 API 与 InAppLocalhostServer
/// 的 directoryIndex、shared 等配置项。
/// 对应接口：
///   - ChromeSafariBrowser: close, isAvailable, clearWebsiteData, prewarmConnections
///   - InAppLocalhostServer: directoryIndex, shared, start, close, isRunning, port

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_ChromeSafariLocalhost';

class ChromeSafariLocalhostPage extends StatefulWidget {
  const ChromeSafariLocalhostPage({super.key});

  @override
  State<ChromeSafariLocalhostPage> createState() =>
      _ChromeSafariLocalhostPageState();
}

class _ChromeSafariLocalhostPageState extends State<ChromeSafariLocalhostPage> {
  final ChromeSafariBrowser _browser = ChromeSafariBrowser();
  InAppLocalhostServer? _server;
  String _status = '就绪';
  String _detail = '';

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() => _status = '$label ...');
    try {
      await action();
      if (!mounted) return;
      setState(() => _status = '$label 完成');
    } catch (e, stack) {
      dev.log('$label failed', name: _kTag, error: e, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _status = '$label: $e';
        _detail = '错误: $e';
      });
    }
  }

  Future<void> _startLocalhost() async {
    _server?.close();
    _server = InAppLocalhostServer(
      port: 8765,
      directoryIndex: 'index.html',
      documentRoot: './',
      shared: false,
    );
    await _server!.start();
    setState(() {
      _detail = 'port=${_server!.port} directoryIndex=${_server!.directoryIndex} '
          'documentRoot=${_server!.documentRoot} shared=${_server!.shared} '
          'isRunning=${_server!.isRunning()}';
    });
  }

  Widget _buildChromeSafariBrowserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ChromeSafariBrowser',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => _run('isAvailable', () async {
                final v = await ChromeSafariBrowser.isAvailable();
                setState(() => _detail = 'isAvailable=$v');
              }),
              child: const Text('isAvailable'),
            ),
            ElevatedButton(
              onPressed: () => _run('open/close', () async {
                await _browser.open(url: WebUri('https://flutter.cn'));
                await _browser.close();
                setState(() => _detail = 'open + close 完成');
              }),
              child: const Text('open + close'),
            ),
            ElevatedButton(
              onPressed: () => _run('clearWebsiteData', () async {
                await ChromeSafariBrowser.clearWebsiteData();
              }),
              child: const Text('clearWebsiteData'),
            ),
            ElevatedButton(
              onPressed: () => _run('prewarmConnections', () async {
                final token = await ChromeSafariBrowser.prewarmConnections(
                  [WebUri('https://flutter.cn')],
                );
                setState(() => _detail = 'prewarm token=$token');
              }),
              child: const Text('prewarmConnections'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _browser.dispose();
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[033] Localhost')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 24),
            const Text('InAppLocalhostServer',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _run('start localhost', _startLocalhost),
                  child: const Text('start (directoryIndex/shared)'),
                ),
                ElevatedButton(
                  onPressed: () => _run('close localhost', () async {
                    await _server?.close();
                    setState(() => _detail = 'server closed');
                  }),
                  child: const Text('close'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('状态: $_status'),
            const SizedBox(height: 8),
            SelectableText(
              _detail.isEmpty ? '(无详情)' : _detail,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
