part of 'main.dart';

void compareBrowserVersions() {
  skippableTest('compareBrowserVersions', () async {
    final version = await WebViewEnvironment.getAvailableVersion();
    expect(version, isNotNull);

    final comparison = await WebViewEnvironment.compareBrowserVersions(
        version1: version!, version2: version);
    expect(comparison, 0);

    final lowerComparison = await WebViewEnvironment.compareBrowserVersions(
        version1: '0.0.0.0', version2: version);
    expect(lowerComparison, lessThan(0));
  });
}
