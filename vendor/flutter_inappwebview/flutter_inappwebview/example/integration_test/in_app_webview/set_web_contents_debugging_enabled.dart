part of 'main.dart';

void setWebContentsDebuggingEnabled() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTest('setWebContentsDebuggingEnabled', () async {
    expect(
        InAppWebViewController.setWebContentsDebuggingEnabled(true), completes);
  }, skip: shouldSkip);
}
