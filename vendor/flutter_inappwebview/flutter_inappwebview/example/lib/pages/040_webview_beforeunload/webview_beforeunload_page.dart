/// Demo 040: beforeunload — Page A（空 handler + 页内链接跳转）
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';
import '../../common/test_urls.dart';

const String _kTag = 'InAppWebView_BeforeUnload';

class WebviewBeforeUnloadPage extends StatefulWidget {
  const WebviewBeforeUnloadPage({super.key});

  @override
  State<WebviewBeforeUnloadPage> createState() => _WebviewBeforeUnloadPageState();
}

class _WebviewBeforeUnloadPageState extends State<WebviewBeforeUnloadPage> {
  final EventLogController _logger = EventLogController();

  @override
  void dispose() {
    _logger.dispose();
    super.dispose();
  }

  Future<JsBeforeUnloadResponse?> _onJsBeforeUnload(
    InAppWebViewController controller,
    JsBeforeUnloadRequest request,
  ) async {
    _logger.log(
      _kTag,
      'onJsBeforeUnload url=${request.url} message="${request.message}"',
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[040] beforeunload')),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: kBeforeUnloadDemoHtml,
                baseUrl: WebUri('https://localhost/'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                isInspectable: true,
              ),
              onLoadStop: (controller, url) =>
                  _logger.log(_kTag, 'onLoadStop: $url'),
              onJsBeforeUnload: _onJsBeforeUnload,
            ),
          ),
          EventLogPanel(controller: _logger, height: 120),
        ],
      ),
    );
  }
}
