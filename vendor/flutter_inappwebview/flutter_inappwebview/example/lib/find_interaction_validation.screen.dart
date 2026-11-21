import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class FindInteractionValidationScreen extends StatefulWidget {
  @override
  State<FindInteractionValidationScreen> createState() =>
      _FindInteractionValidationScreenState();
}

class _FindInteractionValidationScreenState
    extends State<FindInteractionValidationScreen> {
  static const String _searchText = 'InAppWebViewInitialFileTest';
  static const Duration _validationTimeout = Duration(seconds: 5);

  late final FindInteractionController _findInteractionController;

  Completer<int>? _findResultCompleter;
  bool _isRunning = false;
  bool _pageReady = false;
  String _status = '等待页面加载';
  String _futureStatus = '未调用';
  String _message = '这个页面只验证 getActiveFindSession() 会不会一直 pending。';
  int? _eventResultCount;
  int? _sessionResultCount;

  @override
  void initState() {
    super.initState();
    _findInteractionController = FindInteractionController(
      onFindResultReceived: (controller, activeMatchOrdinal, numberOfMatches,
          isDoneCounting) async {
        if (isDoneCounting && _findResultCompleter != null) {
          final completer = _findResultCompleter!;
          if (!completer.isCompleted) {
            completer.complete(numberOfMatches);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _findInteractionController.dispose();
    super.dispose();
  }

  Future<void> _runValidation() async {
    if (_isRunning || !_pageReady) {
      return;
    }

    setState(() {
      _isRunning = true;
      _status = '步骤 1/2：等待搜索完成回调';
      _futureStatus = '未调用';
      _message = '先执行 findAll()，等待最终 onFindResultReceived。';
      _eventResultCount = null;
      _sessionResultCount = null;
    });

    final findResultCompleter = Completer<int>();
    _findResultCompleter = findResultCompleter;

    try {
      await _findInteractionController.findAll(find: _searchText);

      final int eventResultCount = await findResultCompleter.future.timeout(
        _validationTimeout,
        onTimeout: () {
          throw TimeoutException('等待 onFindResultReceived 超时');
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = '步骤 2/2：调用 getActiveFindSession()';
        _futureStatus = '调用中';
        _eventResultCount = eventResultCount;
        _message = '现在真实调用 getActiveFindSession()，检查它会不会一直 pending。';
      });

      final FindSession? session = await _findInteractionController
          .getActiveFindSession()
          .timeout(
        _validationTimeout,
        onTimeout: () {
          throw TimeoutException(
              'getActiveFindSession() 调用超时，说明 Future 仍可能处于 pending');
        },
      );

      if (session == null) {
        throw StateError('getActiveFindSession() 已返回，但结果为 null');
      }

      final bool resultCountMatched = session.resultCount == eventResultCount;

      setState(() {
        _status = resultCountMatched ? '验证通过' : '已返回但结果不一致';
        _futureStatus = '已返回';
        _sessionResultCount = session.resultCount;
        _message = resultCountMatched
            ? '验证通过：getActiveFindSession() 已返回，没有一直 pending。'
            : 'getActiveFindSession() 已返回，但 session.resultCount 和最终回调值不一致。';
      });
    } on TimeoutException catch (e) {
      setState(() {
        _status = '验证失败';
        if (_futureStatus == '调用中') {
          _futureStatus = '超时';
        }
        _message = e.message ?? '超时';
      });
    } catch (e) {
      setState(() {
        _status = '验证失败';
        _message = '异常: $e';
      });
    } finally {
      _findResultCompleter = null;
      setState(() {
        _isRunning = false;
      });
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FindInteraction Validation')),
      drawer: myDrawer(context: context),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: InAppWebView(
                initialFile: 'test_assets/in_app_webview_initial_file_test.html',
                findInteractionController: _findInteractionController,
                initialSettings: InAppWebViewSettings(
                  clearCache: true,
                  isFindInteractionEnabled: true,
                ),
                onLoadStop: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _pageReady = true;
                      _status = '页面已加载';
                      _futureStatus = '未调用';
                      _message = '点击“开始验证”后会真实调用 getActiveFindSession()。';
                    });
                  }
                },
              ),
            ),
            Flexible(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: Colors.blueGrey.shade50,
                      child: const Text(
                        '验证目标：\n'
                        'findAll() -> onFindResultReceived -> getActiveFindSession()\n'
                        '重点看 getActiveFindSession() 会不会一直 pending。',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pageReady && !_isRunning ? _runValidation : null,
                      child: Text(_isRunning ? '验证中...' : '开始验证'),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _buildResultRow('状态', _status),
                            _buildResultRow('Future 状态', _futureStatus),
                            _buildResultRow('搜索词', _searchText),
                            _buildResultRow(
                                '回调匹配数', _eventResultCount?.toString() ?? '-'),
                            _buildResultRow(
                                '会话匹配数', _sessionResultCount?.toString() ?? '-'),
                            const SizedBox(height: 6),
                            SelectableText(_message),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
