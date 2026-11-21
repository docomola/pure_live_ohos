part of 'main.dart';

void disposeEnvironment() {
  skippableTest('dispose', () async {
    final environment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: 'test_env'));
    expect(environment.id, isNotEmpty);
    await expectLater(environment.dispose(), completes);
  });
}
