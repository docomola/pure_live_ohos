import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class CallAsyncJavaScriptExampleScreen extends StatefulWidget {
  @override
  _CallAsyncJavaScriptExampleScreenState createState() =>
      _CallAsyncJavaScriptExampleScreenState();
}

class _CallAsyncJavaScriptExampleScreenState
    extends State<CallAsyncJavaScriptExampleScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  String resultText = '';
  bool isLoading = false;
  bool isWebViewReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('callAsyncJavaScript Demo')),
      drawer: myDrawer(context: context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri('about:blank')),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  // about:blank 会立即加载完成，直接设置 ready 状态
                  setState(() {
                    isWebViewReady = true;
                  });
                },
                onLoadStop: (controller, url) {
                  // 页面加载完成
                  setState(() {
                    isWebViewReady = true;
                  });
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isWebViewReady)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Waiting for WebView to be ready...',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ],
                        ),
                      ),
                    if (isWebViewReady)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Text(
                              'WebView is ready!',
                              style: TextStyle(color: Colors.green[900]),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 12),
                    Text(
                      'Test callAsyncJavaScript',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: (isLoading || !isWebViewReady)
                          ? null
                          : () async {
                              await _testResolveCase();
                            },
                      child: Text('Test Promise Resolve'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (isLoading || !isWebViewReady)
                          ? null
                          : () async {
                              await _testRejectCase();
                            },
                      child: Text('Test Promise Reject'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (isLoading || !isWebViewReady)
                          ? null
                          : () async {
                              await _testContentWorldCase();
                            },
                      child: Text('Test ContentWorld Isolation'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (isLoading || !isWebViewReady)
                          ? null
                          : () async {
                              await _testComplexPromise();
                            },
                      child: Text('Test Complex Promise Chain'),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Result:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(minHeight: 100),
                      child: SingleChildScrollView(
                        child: Text(
                          resultText.isEmpty
                              ? 'Run a test to see result...'
                              : resultText,
                          style: TextStyle(fontFamily: 'monospace'),
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

  Future<void> _testResolveCase() async {
    setState(() {
      isLoading = true;
      resultText = 'Running Promise Resolve test...';
    });

    try {
      final String functionBody = """
        var p = new Promise(function (resolve, reject) {
           window.setTimeout(function() {
             if (x >= 0) {
               resolve(x);
             } else {
               reject(y);
             }
           }, 1000);
        });
        await p;
        return p;
      """;

      var result = await webViewController?.callAsyncJavaScript(
        functionBody: functionBody,
        arguments: {'x': 49, 'y': 'error message'},
      );

      setState(() {
        resultText = 'Test: Promise Resolve\n'
            'Arguments: x=49, y="error message"\n'
            'Result:\n'
            '  value: ${result?.value}\n'
            '  error: ${result?.error}\n'
            '  isError: ${result?.error != null}\n\n'
            'Expected: value=49, error=null\n'
            'Status: ${result?.value == 49 && result?.error == null ? '✅ PASSED' : '❌ FAILED'}';
      });
    } catch (e, stackTrace) {
      setState(() {
        resultText = 'Error: $e\n\nStack trace:\n$stackTrace';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _testRejectCase() async {
    setState(() {
      isLoading = true;
      resultText = 'Running Promise Reject test...';
    });

    try {
      final String functionBody = """
        var p = new Promise(function (resolve, reject) {
           window.setTimeout(function() {
             if (x >= 0) {
               resolve(x);
             } else {
               reject(y);
             }
           }, 1000);
        });
        await p;
        return p;
      """;

      var result = await webViewController?.callAsyncJavaScript(
        functionBody: functionBody,
        arguments: {'x': -49, 'y': 'error message'},
      );

      setState(() {
        resultText = 'Test: Promise Reject\n'
            'Arguments: x=-49, y="error message"\n'
            'Result:\n'
            '  value: ${result?.value}\n'
            '  error: ${result?.error}\n'
            '  isError: ${result?.error != null}\n\n'
            'Expected: value=null, error="error message"\n'
            'Status: ${result?.value == null && result?.error == 'error message' ? '✅ PASSED' : '❌ FAILED'}';
      });
    } catch (e, stackTrace) {
      setState(() {
        resultText = 'Error: $e\n\nStack trace:\n$stackTrace';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _testContentWorldCase() async {
    setState(() {
      isLoading = true;
      resultText = 'Running ContentWorld Isolation test...';
    });

    try {
      // 在自定义 content world 中设置变量
      await webViewController?.callAsyncJavaScript(
        functionBody: "window.foo = 49;",
        contentWorld: ContentWorld.world(name: "custom-world"),
      );

      // 在默认 world 中尝试获取变量
      var resultDefault = await webViewController?.callAsyncJavaScript(
        functionBody: "return window.foo;",
      );

      // 在自定义 world 中获取变量
      var resultCustom = await webViewController?.callAsyncJavaScript(
        functionBody: "return window.foo;",
        contentWorld: ContentWorld.world(name: "custom-world"),
      );

      setState(() {
        resultText = 'Test: ContentWorld Isolation\n\n'
            'Step 1: Set window.foo = 49 in "custom-world"\n'
            'Step 2: Read window.foo from default world\n'
            '  Result: ${resultDefault?.value}\n\n'
            'Step 3: Read window.foo from "custom-world"\n'
            '  Result: ${resultCustom?.value}\n\n'
            'Expected: Default world=null, Custom world=49\n'
            'Status: ${resultDefault?.value == null && resultCustom?.value == 49 ? '✅ PASSED' : '❌ FAILED'}';
      });
    } catch (e, stackTrace) {
      setState(() {
        resultText = 'Error: $e\n\nStack trace:\n$stackTrace';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _testComplexPromise() async {
    setState(() {
      isLoading = true;
      resultText = 'Running Complex Promise Chain test...';
    });

    try {
      final String functionBody = """
        // 复杂的 Promise 链式调用
        async function complexCalculation() {
          const step1 = await new Promise(resolve => {
            setTimeout(() => resolve(a * 2), 500);
          });

          const step2 = await new Promise(resolve => {
            setTimeout(() => resolve(step1 + b), 500);
          });

          const step3 = await new Promise(resolve => {
            setTimeout(() => resolve(step2 * c), 500);
          });

          return {
            steps: ['a*2', 'step1+b', 'step2*c'],
            values: [step1, step2, step3],
            final: step3
          };
        }

        return await complexCalculation();
      """;

      var result = await webViewController?.callAsyncJavaScript(
        functionBody: functionBody,
        arguments: {'a': 10, 'b': 5, 'c': 3},
      );

      setState(() {
        resultText = 'Test: Complex Promise Chain\n\n'
            'Arguments: a=10, b=5, c=3\n'
            'Calculation: (a * 2 + b) * c = (10 * 2 + 5) * 3 = 75\n\n'
            'Result:\n'
            '  steps: ${result?.value['steps']}\n'
            '  values: ${result?.value['values']}\n'
            '  final: ${result?.value['final']}\n\n'
            'Expected: final=75\n'
            'Status: ${result?.value['final'] == 75 ? '✅ PASSED' : '❌ FAILED'}';
      });
    } catch (e, stackTrace) {
      setState(() {
        resultText = 'Error: $e\n\nStack trace:\n$stackTrace';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
