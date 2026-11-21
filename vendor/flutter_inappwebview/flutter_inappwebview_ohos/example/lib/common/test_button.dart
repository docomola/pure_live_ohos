/// 通用测试按钮，统一外观，按下时把执行结果（含异常）汇总到 [EventLogController]。
import 'package:flutter/material.dart';

import 'event_log_panel.dart';

/// 异步按钮：按下后调用 [onPressed]，自动 try/catch 并把结果写入日志。
class AsyncTestButton extends StatefulWidget {
  const AsyncTestButton({
    super.key,
    required this.label,
    required this.tag,
    required this.logger,
    required this.onPressed,
  });

  final String label;
  final String tag;
  final EventLogController logger;
  final Future<Object?> Function() onPressed;

  @override
  State<AsyncTestButton> createState() => _AsyncTestButtonState();
}

class _AsyncTestButtonState extends State<AsyncTestButton> {
  bool _busy = false;

  Future<void> _run() async {
    widget.logger.log(widget.tag, '${widget.label}: 调用开始');
    setState(() => _busy = true);
    final stopwatch = Stopwatch()..start();
    try {
      final result = await widget.onPressed();
      stopwatch.stop();
      if (!mounted) return;
      widget.logger.log(widget.tag,
          '${widget.label}: 成功(${stopwatch.elapsedMilliseconds}ms) -> $result');
    } catch (e, stack) {
      stopwatch.stop();
      if (!mounted) return;
      widget.logger.logError(
        widget.tag,
        '${widget.label}: 异常(${stopwatch.elapsedMilliseconds}ms) -> $e',
        error: e,
        stackTrace: stack,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : _run,
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(widget.label),
      ),
    );
  }
}

/// 同步按钮
class SyncTestButton extends StatelessWidget {
  const SyncTestButton({
    super.key,
    required this.label,
    required this.tag,
    required this.logger,
    required this.onPressed,
  });

  final String label;
  final String tag;
  final EventLogController logger;
  final Object? Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          logger.log(tag, '$label: 调用开始');
          try {
            final result = onPressed();
            logger.log(tag, '$label: 成功 -> $result');
          } catch (e, stack) {
            logger.logError(tag, '$label: 异常 -> $e',
                error: e, stackTrace: stack);
          }
        },
        child: Text(label),
      ),
    );
  }
}
