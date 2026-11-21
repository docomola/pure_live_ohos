import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

import 'fake_platforms.dart';

FakeInAppWebViewPlatform installFakeInAppWebViewPlatform() {
  final fakePlatform = FakeInAppWebViewPlatform();
  InAppWebViewPlatform.instance = fakePlatform;
  return fakePlatform;
}

void restoreInAppWebViewPlatform(InAppWebViewPlatform? previousPlatform) {
  if (previousPlatform != null) {
    InAppWebViewPlatform.instance = previousPlatform;
  }
}
