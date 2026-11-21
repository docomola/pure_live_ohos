/// Demo 32: WebAuthenticationSession
/// 鸿蒙端接口不支持
/// 功能说明：演示 WebAuthenticationSession 构造、create、canStart、start、
/// cancel、dispose 及 isAvailable 静态方法。
/// 对应接口：
///   - WebAuthenticationSession(constructor)
///   - create / canStart / start / cancel / dispose / isAvailable

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_WebAuthSession';

class WebAuthenticationSessionPage extends StatefulWidget {
  const WebAuthenticationSessionPage({super.key});

  @override
  State<WebAuthenticationSessionPage> createState() =>
      _WebAuthenticationSessionPageState();
}

class _WebAuthenticationSessionPageState
    extends State<WebAuthenticationSessionPage> {
  WebAuthenticationSession? _session;
  String _status = '未创建';
  String _lastResult = '';
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    _checkAvailable();
  }

  Future<void> _safeRun(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = '$label 失败: $e');
      dev.log('$label error: $e', name: _kTag);
    }
  }

  Future<void> _checkAvailable() async {
    await _safeRun('isAvailable', () async {
      final available = await WebAuthenticationSession.isAvailable();
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
        _status = 'isAvailable: $available';
      });
    });
  }

  Future<void> _createViaConstructor() async {
    await _safeRun('constructor', () async {
      _session?.dispose();
      _session = WebAuthenticationSession();
      if (!mounted) return;
      setState(() {
        _status = 'constructor 创建 id=${_session!.id}';
        _lastResult = 'WebAuthenticationSession() id=${_session!.id}';
      });
      dev.log('constructor session id=${_session!.id}', name: _kTag);
    });
  }

  Future<void> _createViaFactory() async {
    await _safeRun('create', () async {
      await _session?.dispose();
      _session = await WebAuthenticationSession.create(
        url: WebUri('https://example.com/oauth'),
        callbackURLScheme: 'myapp',
        onComplete: (url, error) async {
          dev.log('onComplete url=$url error=$error', name: _kTag);
          if (!mounted) return;
          setState(() {
            _lastResult = 'onComplete url=$url error=$error';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _status = 'create 成功 callbackURLScheme=myapp';
        _lastResult = 'url=${_session!.url.rawValue}';
      });
    });
  }

  Future<void> _startSession() async {
    if (_session == null) {
      setState(() => _status = '请先创建 session');
      return;
    }
    await _safeRun('canStart/start', () async {
      final canStart = await _session!.canStart();
      final started = canStart ? await _session!.start() : false;
      if (!mounted) return;
      setState(() {
        _status = 'canStart=$canStart start=$started';
        _lastResult = 'canStart=$canStart, start=$started';
      });
    });
  }

  Future<void> _cancelSession() async {
    if (_session == null) return;
    await _safeRun('cancel', () async {
      await _session!.cancel();
      if (!mounted) return;
      setState(() {
        _status = 'cancel() 已调用';
        _lastResult = 'session canceled';
      });
    });
  }

  Future<void> _disposeSession() async {
    await _safeRun('dispose', () async {
      await _session?.dispose();
      _session = null;
      if (!mounted) return;
      setState(() {
        _status = 'dispose() 已调用';
        _lastResult = 'session disposed';
      });
    });
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[032] WebAuthenticationSession')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'WebAuthenticationSession 在 OHOS 上通常不可用，'
                  '本页演示 Dart 层 API 调用与生命周期（isAvailable=$_isAvailable）。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _createViaConstructor,
                  child: const Text('constructor'),
                ),
                ElevatedButton(
                  onPressed: _createViaFactory,
                  child: const Text('create'),
                ),
                ElevatedButton(
                  onPressed: _startSession,
                  child: const Text('canStart/start'),
                ),
                ElevatedButton(
                  onPressed: _cancelSession,
                  child: const Text('cancel'),
                ),
                ElevatedButton(
                  onPressed: _disposeSession,
                  child: const Text('dispose'),
                ),
                OutlinedButton(
                  onPressed: _checkAvailable,
                  child: const Text('isAvailable'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('状态: $_status'),
            const SizedBox(height: 8),
            SelectableText(
              _lastResult.isEmpty ? '(无结果)' : _lastResult,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
