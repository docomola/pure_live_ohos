import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

/// 重定向测试服务主机地址（全文件唯一需要按环境修改的地方）：
/// - 真机测试：改成电脑的局域网 IP（电脑和手机需在同一网络），如 '10.50.80.44'
/// - 电脑浏览器 / 模拟器：可用 'localhost'
const String kRedirectTestHost = '10.50.80.44';

/// 重定向场景测试页面
/// 测试URL: test_node_server/public/redirect_start.html（本地测试服务 8085 端口，
/// 由 test_node_server 目录下 `node index.8085.standalone.js` 提供；
/// 正式集成后 public/ 下的页面也可由 index.js 的 8082 端口 express.static 服务）。
///
/// 测试步骤：
/// 1. 启动本地测试服务：cd test_node_server && node index.8085.standalone.js
/// 2. 进入本页面，自动加载 Page A（redirect_start.html）
/// 3. 点击 Page A 上的按钮，自动经过 B1 → B2 → B3 连续 3 次
///    window.location.replace 重定向，落到 Page C（redirect_end.html）
/// 4. 在 Page C 上点击底部「返回」按钮（goBack）：
///    - 直接回到 Page A → 行为正确
///    - 落在任意 B 页（B1/B2/B3）→ 说明 location.replace 未正确替换历史记录，存在 bug
///
/// 用于验证goBack在重定向场景下是否能正确返回到上一层页面
class RedirectTestScreen extends StatefulWidget {
  @override
  _RedirectTestScreenState createState() => _RedirectTestScreenState();
}

class _RedirectTestScreenState extends State<RedirectTestScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  String currentUrl = "";
  double progress = 0;
  List<String> navigationHistory = [];
  final ScrollController _historyScrollController = ScrollController();

  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  @override
  void initState() {
    super.initState();
  }

  void _addToHistory(String event, [String? url]) {
    setState(() {
      final timestamp = DateTime.now().toString().split('.').first;
      final entry = "[$timestamp] $event${url != null ? ': $url' : ''}";
      navigationHistory.insert(0, entry);
      // Keep only last 50 entries
      if (navigationHistory.length > 50) {
        navigationHistory = navigationHistory.sublist(0, 50);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("重定向测试"),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                navigationHistory.clear();
              });
            },
            tooltip: "清空日志",
          ),
        ],
      ),
      drawer: myDrawer(context: context),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // URL显示区域
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentUrl.isEmpty ? "未加载" : currentUrl,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 进度条
            progress < 1.0
                ? LinearProgressIndicator(value: progress)
                : Container(height: 4),
            // WebView
            Expanded(
              flex: 2,
              child: InAppWebView(
                key: webViewKey,
                webViewEnvironment: webViewEnvironment,
                initialUrlRequest: URLRequest(
                    url: WebUri('http://$kRedirectTestHost:8085/redirect_start.html')),
                initialSettings: settings,
                onWebViewCreated: (controller) async {
                  webViewController = controller;
                  _addToHistory("WebView创建");
                },
                onLoadStart: (controller, url) async {
                  final urlStr = url.toString();
                  setState(() {
                    currentUrl = urlStr;
                  });
                  _addToHistory("开始加载", urlStr);
                },
                onLoadStop: (controller, url) async {
                  final urlStr = url.toString();
                  setState(() {
                    currentUrl = urlStr;
                  });
                  _addToHistory("加载完成", urlStr);
                },
                onReceivedError: (controller, request, error) {
                  _addToHistory("加载错误", "${error.type}: ${error.description}");
                  if (request.isForMainFrame == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('当前url不可用，请更换url'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    this.progress = progress / 100;
                  });
                },
                onUpdateVisitedHistory: (controller, url, isReload) {
                  final urlStr = url.toString();
                  setState(() {
                    currentUrl = urlStr;
                  });
                  _addToHistory("历史更新", "$urlStr (isReload: $isReload)");
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url.toString();
                  _addToHistory("URL拦截", url);
                  return NavigationActionPolicy.ALLOW;
                },
                onConsoleMessage: (controller, consoleMessage) {
                  _addToHistory("Console", consoleMessage.message);
                },
              ),
            ),
            // 导航历史日志
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                color: Colors.black87,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.grey[800],
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 14, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          "导航日志",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _historyScrollController,
                      padding: EdgeInsets.all(4),
                      itemCount: navigationHistory.length,
                      itemBuilder: (context, index) {
                        final entry = navigationHistory[index];
                        Color textColor = Colors.white;
                        if (entry.contains("开始加载")) {
                          textColor = Colors.yellow;
                        } else if (entry.contains("加载完成")) {
                          textColor = Colors.green;
                        } else if (entry.contains("错误")) {
                          textColor = Colors.red;
                        } else if (entry.contains("URL拦截")) {
                          textColor = Colors.cyan;
                        }
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            entry,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 控制按钮
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                color: Colors.grey[100],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton.icon(
                    icon: Icon(Icons.arrow_back, size: 18),
                    label: Text("返回"),
                    onPressed: () async {
                      final canBack =
                          await webViewController?.canGoBack() ?? false;
                      _addToHistory("goBack调用", "canGoBack: $canBack");
                      if (canBack) {
                        webViewController?.goBack();
                      } else {
                        _addToHistory("无法返回", "已到历史栈底部");
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.arrow_forward, size: 18),
                    label: Text("前进"),
                    onPressed: () async {
                      final canForward =
                          await webViewController?.canGoForward() ?? false;
                      _addToHistory("goForward调用", "canGoForward: $canForward");
                      if (canForward) {
                        webViewController?.goForward();
                      } else {
                        _addToHistory("无法前进", "已到历史栈顶部");
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, size: 18),
                    label: Text("刷新"),
                    onPressed: () {
                      _addToHistory("reload调用");
                      webViewController?.reload();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
