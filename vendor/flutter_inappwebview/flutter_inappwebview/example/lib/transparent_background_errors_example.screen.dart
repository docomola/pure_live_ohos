import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// Manual verification for [transparentBackground], [onReceivedError], and
/// [onReceivedHttpError] on OHOS. Uses local assets or localhost only.
class TransparentBackgroundErrorsExampleScreen extends StatefulWidget {
  @override
  State<TransparentBackgroundErrorsExampleScreen> createState() =>
      _TransparentBackgroundErrorsExampleScreenState();
}

enum _TestVerdict { pending, pass, fail }

class _TransparentBackgroundErrorsExampleScreenState
    extends State<TransparentBackgroundErrorsExampleScreen> {
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _controller;

  late final InAppLocalhostServer _localhostServer =
      InAppLocalhostServer(documentRoot: 'test_assets');

  bool _serverReady = false;
  String _statusLine = 'Starting local server…';
  String _lastCallback = 'No callback yet — tap a test button';

  /// One row per manual test; updated to [pass] only when the WebView callback fires.
  final Map<String, _TestVerdict> _checklist = {
    '1. Transparent page': _TestVerdict.pending,
    '2. Scheme error (onReceivedError)': _TestVerdict.pending,
    '3. Local HTTP 404 (onReceivedHttpError)': _TestVerdict.pending,
  };

  /// Unsupported scheme — triggers [onReceivedError] without Internet.
  static final WebUri _unsupportedSchemeUrl =
      WebUri('unknownscheme://local-error-test');

  WebUri get _http404Url => WebUri(
        'http://127.0.0.1:${_localhostServer.port}/__ohos_manual_404_test__.html',
      );

  @override
  void initState() {
    super.initState();
    _startLocalServer();
  }

  Future<void> _startLocalServer() async {
    try {
      if (!_localhostServer.isRunning()) {
        await _localhostServer.start();
      }
      if (mounted) {
        setState(() {
          _serverReady = true;
          _statusLine =
              'Local server: http://127.0.0.1:${_localhostServer.port} (test_assets/)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusLine = 'Local server failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    if (_localhostServer.isRunning()) {
      _localhostServer.close();
    }
    super.dispose();
  }

  void _setChecklist(String key, _TestVerdict verdict) {
    if (_checklist[key] == verdict) return;
    setState(() {
      _checklist[key] = verdict;
    });
  }

  void _markCallback(String text) {
    setState(() {
      _lastCallback = text;
    });
    debugPrint('[TransparentBackgroundErrors] $text');
  }

  Future<void> _loadTransparentPage() async {
    _setChecklist('1. Transparent page', _TestVerdict.pending);
    await _controller?.loadFile(
      assetFilePath:
          'test_assets/in_app_webview_transparent_background_test.html',
    );
  }

  Future<void> _triggerReceivedError() async {
    _setChecklist('2. Scheme error (onReceivedError)', _TestVerdict.pending);
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: _unsupportedSchemeUrl),
    );
  }

  Future<void> _triggerReceivedHttpError() async {
    if (!_serverReady) {
      _setChecklist('3. Local HTTP 404 (onReceivedHttpError)', _TestVerdict.fail);
      _markCallback('Local server not ready');
      return;
    }
    _setChecklist('3. Local HTTP 404 (onReceivedHttpError)', _TestVerdict.pending);
    await _controller?.loadUrl(urlRequest: URLRequest(url: _http404Url));
  }

  Future<void> _toggleTransparentBackground() async {
    final settings = await _controller?.getSettings();
    final enabled = !(settings?.transparentBackground ?? false);
    await _controller?.setSettings(
      settings: InAppWebViewSettings(transparentBackground: enabled),
    );
    _markCallback('transparentBackground = $enabled');
  }

  int get _checklistPassCount =>
      _checklist.values.where((v) => v == _TestVerdict.pass).length;
  int get _checklistFailCount =>
      _checklist.values.where((v) => v == _TestVerdict.fail).length;
  bool get _allChecklistPassed =>
      _checklist.values.every((v) => v == _TestVerdict.pass);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TransparentBackground & Errors'),
      ),
      drawer: myDrawer(context: context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7B1FA2),
              Color(0xFFE91E63),
              Color(0xFFFF9800),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusBanner(),
              _buildSummaryCard(),
              _buildChecklist(),
              _buildLastCallbackBox(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InAppWebView(
                    key: _webViewKey,
                    initialSettings: InAppWebViewSettings(
                      transparentBackground: true,
                      javaScriptEnabled: true,
                    ),
                    initialFile:
                        'test_assets/in_app_webview_transparent_background_test.html',
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    onLoadStop: (controller, url) {
                      _setChecklist('1. Transparent page', _TestVerdict.pass);
                      _markCallback('✓ onLoadStop\n${url ?? "(null)"}');
                    },
                    onReceivedError: (controller, request, error) {
                      _setChecklist(
                          '2. Scheme error (onReceivedError)', _TestVerdict.pass);
                      _markCallback(
                        '✓ onReceivedError\n${error.type} — ${error.description}\n'
                        'url: ${request.url}',
                      );
                    },
                    onReceivedHttpError:
                        (controller, request, errorResponse) {
                      final code = errorResponse.statusCode ?? 0;
                      final pass = code == 404;
                      _setChecklist(
                        '3. Local HTTP 404 (onReceivedHttpError)',
                        pass ? _TestVerdict.pass : _TestVerdict.fail,
                      );
                      _markCallback(
                        '${pass ? "✓" : "✗"} onReceivedHttpError\n'
                        'HTTP $code ${errorResponse.reasonPhrase ?? ""}\n'
                        'url: ${request.url}',
                      );
                    },
                  ),
                ),
              ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _loadTransparentPage,
                      child: const Text('1. Transparent page'),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: _triggerReceivedError,
                      child: const Text('2. Scheme error'),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed:
                          _serverReady ? _triggerReceivedHttpError : null,
                      child: Text(
                        _serverReady ? '3. Local HTTP 404' : '3. Waiting for server…',
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _toggleTransparentBackground,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text('Toggle transparent'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bg;
    IconData icon;
    String title;
    if (_allChecklistPassed) {
      bg = Colors.green.shade700;
      icon = Icons.verified;
      title = 'All 3 tests passed — OHOS implementation OK';
    } else if (_checklistFailCount > 0) {
      bg = Colors.red.shade700;
      icon = Icons.error_outline;
      title =
          '$_checklistFailCount failed — see checklist / last callback below';
    } else if (_checklistPassCount > 0) {
      bg = Colors.teal.shade700;
      icon = Icons.pending_actions;
      title =
          '$_checklistPassCount / ${_checklist.length} passed — run remaining tests';
    } else {
      bg = Colors.blue.shade700;
      icon = Icons.play_circle_outline;
      title = 'Run tests 1 → 2 → 3 on OHOS device';
    }
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _serverReady ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: _serverReady ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_statusLine, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Visual: gradient behind WebView = transparentBackground. '
              'Green checklist = callback received.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                'Test checklist',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            ..._checklist.entries.map((e) => _buildChecklistRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String label, _TestVerdict verdict) {
    late final Color color;
    late final IconData icon;
    late final String status;
    switch (verdict) {
      case _TestVerdict.pass:
        color = Colors.green;
        icon = Icons.check_circle;
        status = 'PASS';
        break;
      case _TestVerdict.fail:
        color = Colors.red;
        icon = Icons.cancel;
        status = 'FAIL';
        break;
      default:
        color = Colors.grey;
        icon = Icons.radio_button_unchecked;
        status = 'TODO';
    }
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLastCallbackBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last WebView callback',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _lastCallback,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
