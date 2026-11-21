import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class CookieDeleteValidationScreen extends StatefulWidget {
  @override
  State<CookieDeleteValidationScreen> createState() =>
      _CookieDeleteValidationScreenState();
}

class _CookieDeleteValidationScreenState
    extends State<CookieDeleteValidationScreen> {
  static final WebUri _testUrl = WebUri('https://flutter.cn/');
  static const String _cookieName = 'ohos_cookie_delete_demo';

  final CookieManager _cookieManager = CookieManager.instance();
  final List<String> _logs = <String>[];

  InAppWebViewController? _controller;
  int _seq = 0;
  int _webViewVersion = 0;
  bool _pageReady = false;
  String _status = '等待页面加载';
  String _cookieSummary = '未读取';

  void _appendLog(String tag, String message) {
    final String time = DateTime.now().toIso8601String().split('T').last;
    setState(() {
      _logs.insert(0, '[${_seq++}][$time][$tag] $message');
      if (_logs.length > 80) {
        _logs.removeRange(80, _logs.length);
      }
    });
  }

  Future<void> _setCookie() async {
    final String value = DateTime.now().millisecondsSinceEpoch.toString();
    await _cookieManager.setCookie(
      url: _testUrl,
      name: _cookieName,
      value: value,
      path: '/',
    );
    _appendLog('set', '$_cookieName=$value');
    await _refreshCookies();
  }

  Future<void> _readCookie() async {
    await _refreshCookies();
  }

  Future<void> _deleteCookie() async {
    final bool result = await _cookieManager.deleteCookie(
      url: _testUrl,
      name: _cookieName,
      path: '/',
    );
    _appendLog('delete', 'deleteCookie result=$result');
    await _refreshCookies();
  }

  Future<void> _deleteCookies() async {
    final bool result = await _cookieManager.deleteCookies(
      url: _testUrl,
      path: '/',
    );
    _appendLog('deleteAllVisible', 'deleteCookies result=$result');
    await _refreshCookies();
  }

  Future<void> _refreshCookies() async {
    final Cookie? cookie = await _cookieManager.getCookie(
      url: _testUrl,
      name: _cookieName,
    );
    final List<Cookie> cookies = await _cookieManager.getCookies(url: _testUrl);
    final bool exists = cookie != null;
    final String values = cookies
        .map((item) => '${item.name}=${item.value}')
        .take(8)
        .join('; ');
    setState(() {
      _cookieSummary = exists
          ? '目标 cookie 存在: ${cookie.name}=${cookie.value}'
          : '目标 cookie 不存在';
      _status = '当前 URL 共 ${cookies.length} 个 cookie';
    });
    _appendLog(
      'read',
      '${exists ? 'found' : 'missing'}; all=${values.isEmpty ? '(empty)' : values}',
    );
  }

  Future<void> _reloadWebView() async {
    await _controller?.reload();
    _appendLog('reload', 'reload requested');
  }

  Future<void> _recreateWebView() async {
    setState(() {
      _pageReady = false;
      _status = '正在重建 WebView';
      _webViewVersion++;
    });
    _appendLog('recreate', 'webViewVersion=$_webViewVersion');
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilledButton.tonal(
        onPressed: _pageReady ? onPressed : null,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cookie Delete Validation')),
      drawer: myDrawer(context: context),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '建议步骤：Set Cookie -> Read Cookie -> Delete Cookie -> Read Cookie -> Recreate WebView -> Read Cookie',
                  ),
                  const SizedBox(height: 8),
                  Text('测试 URL: ${_testUrl.toString()}'),
                  const SizedBox(height: 4),
                  Text('状态: $_status'),
                  const SizedBox(height: 4),
                  Text('结果: $_cookieSummary'),
                  const SizedBox(height: 12),
                  Wrap(
                    children: <Widget>[
                      _buildActionButton('Set Cookie', _setCookie),
                      _buildActionButton('Read Cookie', _readCookie),
                      _buildActionButton('Delete Cookie', _deleteCookie),
                      _buildActionButton('Delete Cookies', _deleteCookies),
                      _buildActionButton('Reload WebView', _reloadWebView),
                    ],
                  ),
                  Wrap(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: FilledButton(
                          onPressed: _recreateWebView,
                          child: const Text('Recreate WebView'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: InAppWebView(
                key: ValueKey<int>(_webViewVersion),
                initialUrlRequest: URLRequest(url: _testUrl),
                initialSettings: InAppWebViewSettings(clearCache: true),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _pageReady = true;
                    _status = '页面加载完成: ${url?.toString() ?? _testUrl.toString()}';
                  });
                  _appendLog('load', 'onLoadStop ${url?.toString() ?? _testUrl.toString()}');
                  await _refreshCookies();
                },
              ),
            ),
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无日志',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
