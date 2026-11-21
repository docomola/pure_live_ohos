/// 通用 Demo 脚手架：提供带日志面板的 Scaffold。
import 'package:flutter/material.dart';

import 'event_log_panel.dart';

class TestScaffold extends StatelessWidget {
  const TestScaffold({
    super.key,
    required this.title,
    required this.logger,
    required this.children,
    this.topWidget,
    this.logHeight = 220,
  });

  final String title;
  final EventLogController logger;
  final List<Widget> children;
  final Widget? topWidget;
  final double logHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topWidget != null) topWidget!,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final w in children) ...[
                      w,
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: EventLogPanel(controller: logger, height: logHeight),
            ),
          ],
        ),
      ),
    );
  }
}
