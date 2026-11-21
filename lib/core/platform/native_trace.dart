import 'dart:async';

import 'package:media_core_avplayer/media_core_avplayer.dart';

/// Writes a line to the platform log (`hilog`, tag `AvPlayerDart`).
///
/// This exists because Dart's `print` does not reach `hilog` on the HarmonyOS
/// embedding: without it a playback failure is completely invisible from
/// outside the app — no logs, no stack trace, only a spinner. It is a port
/// aid, cheap enough (one channel call) to keep for diagnosing field issues.
void nativeTrace(String message) {
  unawaited(AvPlayerChannel.instance.log(message));
}
