/// Demo 33: Inject / UserScript / Controller APIs
///
/// 功能说明：演示 InAppWebViewController 的注入与用户脚本 API，以及
/// fromPlatform、addWebMessageListener、isInFullscreen、createPdf。
/// 对应接口：
///   - injectJavascriptFileFromUrl / injectJavascriptFileFromAsset
///   - injectCSSCode / injectCSSFileFromUrl / injectCSSFileFromAsset
///   - addUserScript / removeUserScript / removeAllUserScripts
///   - InAppWebViewController.fromPlatform / isInFullscreen / createPdf

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String _kTag = 'InAppWebView_InjectUserScript';

class InjectUserscriptPage extends StatefulWidget {
  const InjectUserscriptPage({super.key});

  @override
  State<InjectUserscriptPage> createState() => _InjectUserscriptPageState();
}

class _InjectUserscriptPageState extends State<InjectUserscriptPage> {
  InAppWebViewController? _controller;
  String _status = '等待 WebView';
  UserScript? _userScript;

  static const String _testHtml = '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Inject Demo</title></head>
<body>
  <h1 id="title">Inject Demo</h1>
  <p id="hint">等待 Dart 注入脚本/CSS</p>
</body>
</html>
''';

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() => _status = '$label ...');
    try {
      await action();
      if (!mounted) return;
      setState(() => _status = '$label 完成');
    } catch (e, stack) {
      dev.log('$label failed', name: _kTag, error: e, stackTrace: stack);
      if (!mounted) return;
      setState(() => _status = '$label 失败: $e');
    }
    print("222 = '$_status'");
  }

  Future<void> _demoFromPlatform() async {
    final c = _controller;
    if (c == null) return;
    final wrapped = InAppWebViewController.fromPlatform(platform: c.platform);
    setState(() => _status = 'fromPlatform id=${wrapped.hashCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[033] 注入与用户脚本')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('状态: $_status', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _btn('fromPlatform', _demoFromPlatform),
                    _btn('injectCSSCode', () => _run('injectCSSCode', () async {
                          await _controller?.injectCSSCode(
                            source: 'body { background: #fffde7; }',
                          );
                        })),
                    _btn('injectJavascriptFileFromAsset', () =>
                        _run('injectJavascriptFileFromAsset', () async {
                          await _controller?.injectJavascriptFileFromAsset(
                            assetFilePath: 'assets/js/test.js',
                          );
                        })),
                    _btn('injectCSSFileFromAsset', () =>
                        _run('injectCSSFileFromAsset', () async {
                          await _controller?.injectCSSFileFromAsset(
                            assetFilePath: 'assets/css/test.css',
                          );
                        })),
                    _btn('injectJavascriptFileFromUrl', () =>
                        _run('injectJavascriptFileFromUrl', () async {
                          await _controller?.injectJavascriptFileFromUrl(
                            urlFile: WebUri('https://example.com/app.js'),
                          );
                        })),
                    _btn('injectCSSFileFromUrl', () =>
                        _run('injectCSSFileFromUrl', () async {
                          await _controller?.injectCSSFileFromUrl(
                            urlFile: WebUri('https://example.com/app.css'),
                          );
                        })),
                    _btn('addUserScript', () => _run('addUserScript', () async {
                          _userScript = UserScript(
                            source:
                                "document.getElementById('hint').innerText='UserScript injected';",
                            injectionTime:
                                UserScriptInjectionTime.AT_DOCUMENT_END,
                          );
                          await _controller?.addUserScript(
                            userScript: _userScript!,
                          );
                        })),
                    _btn('removeUserScript', () =>
                        _run('removeUserScript', () async {
                          if (_userScript != null) {
                            await _controller?.removeUserScript(
                              userScript: _userScript!,
                            );
                          }
                        })),
                    _btn('removeAllUserScripts', () =>
                        _run('removeAllUserScripts', () async {
                          await _controller?.removeAllUserScripts();
                        })),
                    _btn('addWebMessageListener', () async {
                      final listener = WebMessageListener(
                        jsObjectName: 'InjectBridge',
                        allowedOriginRules: {'*'},
                      );
                      await _controller?.addWebMessageListener(listener);
                      setState(() => _status = 'addWebMessageListener 完成');
                    }),
                    _btn('isInFullscreen', () async {
                      final v = await _controller?.isInFullscreen();
                      setState(() => _status = 'isInFullscreen=$v');
                    }),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(data: _testHtml),
              initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
              onWebViewCreated: (c) => _controller = c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        textStyle: const TextStyle(fontSize: 11),
      ),
      child: Text(label),
    );
  }
}
