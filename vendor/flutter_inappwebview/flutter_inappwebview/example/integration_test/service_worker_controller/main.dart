import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import '../constants.dart';
import '../util.dart';

part 'set_service_worker_client.dart';
part 'should_intercept_request.dart';
part 'cache_mode_settings.dart';

void main() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableGroup('Service Worker Controller', () {
    shouldInterceptRequest();
    setServiceWorkerClient();
    cacheModeSettings();
  }, skip: shouldSkip);
}
