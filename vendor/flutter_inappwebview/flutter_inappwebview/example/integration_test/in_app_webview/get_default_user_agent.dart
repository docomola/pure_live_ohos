part of 'main.dart';

void getDefaultUserAgent() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTest('getDefaultUserAgent', () async {
    expect(await InAppWebViewController.getDefaultUserAgent(), isNotNull);
  }, skip: shouldSkip);
}
