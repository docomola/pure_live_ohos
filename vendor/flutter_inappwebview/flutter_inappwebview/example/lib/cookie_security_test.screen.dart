import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// Manual tests for [MyCookieManager] RFC 6265 validation on OpenHarmony.
class CookieSecurityTestScreen extends StatefulWidget {
  @override
  State<CookieSecurityTestScreen> createState() =>
      _CookieSecurityTestScreenState();
}

class _CookieSecurityTestScreenState extends State<CookieSecurityTestScreen> {
  static const String _testDescription = '''
测试步骤：
1. 设置合法 Cookie, name="sessionId", value="abc123", path="/"
2. 设置含非法字符的 name, name="sess;ionId", value="abc123", path="/"
3. 设置含非法字符的 value, name="token", value="val;ue=hack", path="/"
4. 设置含非法字符的 path, name="token", value="abc", path="/;admin"
5. 设置含非法 domain, domain="exam;ple.com"
6. 设置非法 sameSite, sameSite="Invalid"
7. 设置合法 sameSite, sameSite="Strict"

预期结果：
1. 返回 true，Cookie 写入成功，可通过 getCookies 读取。
2–6. 返回 false，Cookie 未写入，不产生异常或注入 Cookie。
7. 返回 true，Cookie 正常写入。

实际结果：
1. 返回 true，Cookie 写入成功，可通过 getCookies 读取。
2–6. 返回 false，Cookie 未写入，不产生异常或注入 Cookie。
7. 返回 true，Cookie 正常写入。
''';

  static const MethodChannel _cookieChannel = MethodChannel(
    'com.pichillilorenzo/flutter_inappwebview_cookiemanager',
  );

  final CookieManager _cookieManager = CookieManager.instance();
  final WebUri _testUrl = WebUri('https://flutter.cn');
  final List<String> _logs = [];

  Future<bool> _invokeSetCookieRaw(Map<String, dynamic> args) async {
    final result = await _cookieChannel.invokeMethod<bool>('setCookie', args);
    return result ?? false;
  }

  Map<String, dynamic> _baseSetCookieArgs({
    String name = 'token',
    String value = 'abc',
    String path = '/',
  }) {
    return <String, dynamic>{
      'url': _testUrl.toString(),
      'name': name,
      'value': value,
      'path': path,
    };
  }

  void _log(String message) {
    setState(() {
      _logs.insert(0, message);
    });
  }

  Future<void> _runCase({
    required String title,
    required bool expected,
    required Future<bool> Function() action,
    Future<void> Function(bool result)? verify,
  }) async {
    try {
      final result = await action();
      final passed = result == expected;
      if (passed && verify != null) {
        await verify(result);
      }
      _log(
        '${passed ? "PASS" : "FAIL"} — $title\n'
        '  期望: $expected，实际: $result',
      );
    } catch (e) {
      _log('FAIL — $title\n  异常: $e');
    }
  }

  Future<void> _testStep1ValidCookie() async {
    await _runCase(
      title: '1. 合法 Cookie (sessionId=abc123, path=/)',
      expected: true,
      action: () => _cookieManager.setCookie(
        url: _testUrl,
        name: 'sessionId',
        value: 'abc123',
        path: '/',
      ),
      verify: (result) async {
        if (!result) return;
        final cookies = await _cookieManager.getCookies(url: _testUrl);
        final found = cookies.any(
          (c) => c.name == 'sessionId' && c.value == 'abc123',
        );
        if (!found) {
          _log('FAIL — 1. getCookies 未读取到 sessionId=abc123');
        }
      },
    );
  }

  Future<void> _testStep2InvalidName() async {
    await _runCase(
      title: '2. 非法 name 含 ";" (sess;ionId)',
      expected: false,
      action: () => _cookieManager.setCookie(
        url: _testUrl,
        name: 'sess;ionId',
        value: 'abc123',
        path: '/',
      ),
    );
  }

  Future<void> _testStep3InvalidValue() async {
    await _runCase(
      title: '3. 非法 value 含 ";" (val;ue=hack)',
      expected: false,
      action: () => _cookieManager.setCookie(
        url: _testUrl,
        name: 'token',
        value: 'val;ue=hack',
        path: '/',
      ),
    );
  }

  Future<void> _testStep4InvalidPath() async {
    await _runCase(
      title: '4. 非法 path 含 ";" (/;admin)',
      expected: false,
      action: () => _cookieManager.setCookie(
        url: _testUrl,
        name: 'token',
        value: 'abc',
        path: '/;admin',
      ),
    );
  }

  Future<void> _testStep5InvalidDomain() async {
    await _runCase(
      title: '5. 非法 domain 含 ";" (exam;ple.com)',
      expected: false,
      action: () => _cookieManager.setCookie(
        url: _testUrl,
        name: 'token',
        value: 'abc',
        path: '/',
        domain: 'exam;ple.com',
      ),
    );
  }

  Future<void> _testStep6InvalidSameSite() async {
    await _runCase(
      title: '6. 非法 sameSite (Invalid)',
      expected: false,
      action: () => _invokeSetCookieRaw(
        _baseSetCookieArgs()..['sameSite'] = 'Invalid',
      ),
    );
  }

  Future<void> _testStep7ValidSameSite() async {
    await _runCase(
      title: '7. 合法 sameSite (Strict)',
      expected: true,
      action: () => _cookieManager.setCookie(
        url: _testUrl,
        name: 'token',
        value: 'abc',
        path: '/',
        sameSite: HTTPCookieSameSitePolicy.STRICT,
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() => _logs.clear());
    _log('开始运行全部用例…');
    await _testStep1ValidCookie();
    await _testStep2InvalidName();
    await _testStep3InvalidValue();
    await _testStep4InvalidPath();
    await _testStep5InvalidDomain();
    await _testStep6InvalidSameSite();
    await _testStep7ValidSameSite();
    _log('全部用例执行完毕。');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cookie RFC6265 测试'),
      ),
      drawer: myDrawer(context: context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topMaxHeight = constraints.maxHeight * 0.26;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: topMaxHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          '测试说明',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '平台: $defaultTargetPlatform',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        initiallyExpanded: false,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '仅 OHOS 原生层实现了 RFC 6265 校验；'
                              '非法字符应返回 false。\n'
                              'sameSite 注入用例通过 MethodChannel 直调原生。\n\n'
                              '$_testDescription',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _actionButton('1. 合法 Cookie', _testStep1ValidCookie),
                          _actionButton('2. 非法 name', _testStep2InvalidName),
                          _actionButton('3. 非法 value', _testStep3InvalidValue),
                          _actionButton('4. 非法 path', _testStep4InvalidPath),
                          _actionButton('5. 非法 domain', _testStep5InvalidDomain),
                          _actionButton('6. 非法 sameSite', _testStep6InvalidSameSite),
                          _actionButton('7. 合法 sameSite', _testStep7ValidSameSite),
                          _actionButton('运行全部', _runAllTests),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  '测试结果',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.35),
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text('点击按钮运行测试，结果将显示在下方。'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final line = _logs[index];
                            final isPass = line.startsWith('PASS');
                            final isFail = line.startsWith('FAIL');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: isPass
                                      ? Colors.green.shade800
                                      : isFail
                                          ? Colors.red.shade800
                                          : null,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionButton(String label, Future<void> Function() onPressed) {
    return FilledButton.tonal(
      onPressed: () => onPressed(),
      child: Text(label),
    );
  }
}
