part of 'main.dart';

void getAvailableVersion() {
  skippableTest('getAvailableVersion', () async {
    final version = await WebViewEnvironment.getAvailableVersion();
    expect(version, isNotNull);
    expect(version, isNotEmpty);
  });
}
