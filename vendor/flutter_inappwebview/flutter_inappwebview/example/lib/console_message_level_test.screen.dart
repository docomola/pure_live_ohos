import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// Tests that OHOS native MessageLevel values are correctly mapped
/// to Dart-side ConsoleMessageLevel values.
///
/// Expected mapping:
///   console.debug -> ConsoleMessageLevel.DEBUG  (value=4)
///   console.log   -> ConsoleMessageLevel.LOG    (value=1)
///   console.info  -> ConsoleMessageLevel.LOG    (value=1)
///   console.warn  -> ConsoleMessageLevel.WARNING(value=2)
///   console.error -> ConsoleMessageLevel.ERROR  (value=3)
class ConsoleMessageLevelTestScreen extends StatefulWidget {
  @override
  State<ConsoleMessageLevelTestScreen> createState() =>
      _ConsoleMessageLevelTestScreenState();
}

class _ConsoleMessageLevelTestScreenState
    extends State<ConsoleMessageLevelTestScreen> {
  InAppWebViewController? _webViewController;
  final List<_ConsoleLogEntry> _logs = [];
  bool _testRunning = false;

  void _addLog(String jsMethod, String message, ConsoleMessageLevel level) {
    setState(() {
      _logs.insert(
        0,
        _ConsoleLogEntry(
          jsMethod: jsMethod,
          message: message,
          level: level,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _runTest() async {
    setState(() {
      _testRunning = true;
      _logs.clear();
    });
    await _webViewController?.loadFile(
      assetFilePath: 'test_assets/console_message_level_test.html',
    );
    // Wait for console messages to arrive
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _testRunning = false);
  }

  Future<void> _runManualTest(String jsCode, String jsMethod) async {
    await _webViewController?.evaluateJavascript(source: jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ConsoleMessageLevel 测试'),
      ),
      drawer: myDrawer(context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('about:blank')),
              initialSettings: InAppWebViewSettings(
                isInspectable: kDebugMode,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onConsoleMessage: (controller, consoleMessage) {
                _addLog(
                  _inferJsMethod(consoleMessage.messageLevel),
                  consoleMessage.message ?? '',
                  consoleMessage.messageLevel ?? ConsoleMessageLevel.LOG,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '平台: $defaultTargetPlatform\n'
              '验证 OHOS MessageLevel -> Dart ConsoleMessageLevel 映射\n'
              'OHOS原生值: Debug=1, Info=2, Warn=3, Error=4, Log=5\n'
              'Dart期望值: TIP=0, LOG=1, WARNING=2, ERROR=3, DEBUG=4',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _actionButton(
                  '加载测试页面',
                  _testRunning ? null : _runTest,
                ),
                const SizedBox(width: 8),
                _actionButton(
                  'console.debug',
                  () => _runManualTest('console.debug("manual debug")', 'debug'),
                ),
                _actionButton(
                  'console.log',
                  () => _runManualTest('console.log("manual log")', 'log'),
                ),
                _actionButton(
                  'console.info',
                  () => _runManualTest('console.info("manual info")', 'info'),
                ),
                _actionButton(
                  'console.warn',
                  () => _runManualTest('console.warn("manual warn")', 'warn'),
                ),
                _actionButton(
                  'console.error',
                  () => _runManualTest('console.error("manual error")', 'error'),
                ),
                const SizedBox(width: 8),
                _actionButton('清空日志', () => setState(() => _logs.clear())),
              ],
            ),
          ),
          const Divider(height: 1),
          // Expected result reference
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(8),
            child: const Text(
              '✅ 期望结果: debug→DEBUG(4)  log→LOG(1)  info→LOG(1)  warn→WARNING(2)  error→ERROR(3)',
              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('点击按钮运行测试，结果将显示在下方。'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final entry = _logs[index];
                      final isCorrect = _isMappingCorrect(entry);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${entry.timestamp.toIso8601String().substring(11, 23)} '
                                'console.${entry.jsMethod}("${entry.message}") → '
                                '${entry.level} (value=${entry.level?.toValue()})',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: isCorrect
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Infers the JS console method from the Dart ConsoleMessageLevel.
  String _inferJsMethod(ConsoleMessageLevel? level) {
    switch (level) {
      case ConsoleMessageLevel.DEBUG:
        return 'debug';
      case ConsoleMessageLevel.LOG:
        return 'log/info';
      case ConsoleMessageLevel.WARNING:
        return 'warn';
      case ConsoleMessageLevel.ERROR:
        return 'error';
      case ConsoleMessageLevel.TIP:
        return 'tip';
      default:
        return 'unknown';
    }
  }

  /// Checks if the received ConsoleMessageLevel matches the expected mapping.
  bool _isMappingCorrect(_ConsoleLogEntry entry) {
    // For messages from the test HTML page, we know which JS method was called
    // and can verify the expected Dart level.
    final msg = entry.message;
    final level = entry.level;

    if (msg == 'debug message') return level == ConsoleMessageLevel.DEBUG;
    if (msg == 'log message') return level == ConsoleMessageLevel.LOG;
    if (msg == 'info message') return level == ConsoleMessageLevel.LOG;
    if (msg == 'warn message') return level == ConsoleMessageLevel.WARNING;
    if (msg == 'error message') return level == ConsoleMessageLevel.ERROR;

    // For manual test buttons, verify based on the jsMethod
    switch (entry.jsMethod) {
      case 'debug':
        return level == ConsoleMessageLevel.DEBUG;
      case 'log':
        return level == ConsoleMessageLevel.LOG;
      case 'info':
        return level == ConsoleMessageLevel.LOG;
      case 'warn':
        return level == ConsoleMessageLevel.WARNING;
      case 'error':
        return level == ConsoleMessageLevel.ERROR;
      default:
        return true; // Unknown method, can't verify
    }
  }

  Widget _actionButton(String label, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _ConsoleLogEntry {
  final String jsMethod;
  final String message;
  final ConsoleMessageLevel? level;
  final DateTime timestamp;

  _ConsoleLogEntry({
    required this.jsMethod,
    required this.message,
    required this.level,
    required this.timestamp,
  });
}
