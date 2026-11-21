import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../util.dart';

part 'get_available_version.dart';
part 'compare_browser_versions.dart';
part 'dispose_environment.dart';

void main() {
  final shouldSkip = kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.windows &&
          defaultTargetPlatform != TargetPlatform.ohos);

  skippableGroup('WebViewEnvironment', () {
    getAvailableVersion();
    compareBrowserVersions();
    disposeEnvironment();
  }, skip: shouldSkip);
}
