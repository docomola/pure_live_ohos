part of 'main.dart';

void getAllRemoveCredentials() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTestWidgets(
      'getAllAuthCredentials, removeHttpAuthCredential, removeHttpAuthCredentials',
      (WidgetTester tester) async {
    HttpAuthCredentialDatabase httpAuthCredentialDatabase =
        HttpAuthCredentialDatabase.instance();

    final protectionSpace = URLProtectionSpace(
        host: environment["NODE_SERVER_IP"]!,
        protocol: "http",
        realm: "Node",
        port: 8081);
    final credential =
        URLCredential(username: "USERNAME", password: "PASSWORD");

    await httpAuthCredentialDatabase.clearAllAuthCredentials();
    await httpAuthCredentialDatabase.setHttpAuthCredential(
        protectionSpace: protectionSpace, credential: credential);

    final allCredentials =
        await httpAuthCredentialDatabase.getAllAuthCredentials();
    expect(allCredentials, isNotEmpty);
    expect(
        allCredentials.any((item) =>
            item.protectionSpace?.host == protectionSpace.host &&
            item.credentials?.isNotEmpty == true),
        isTrue);

    await httpAuthCredentialDatabase.removeHttpAuthCredential(
        protectionSpace: protectionSpace, credential: credential);

    var credentials = await httpAuthCredentialDatabase.getHttpAuthCredentials(
        protectionSpace: protectionSpace);
    expect(credentials, isEmpty);

    await httpAuthCredentialDatabase.setHttpAuthCredential(
        protectionSpace: protectionSpace, credential: credential);
    await httpAuthCredentialDatabase.removeHttpAuthCredentials(
        protectionSpace: protectionSpace);

    credentials = await httpAuthCredentialDatabase.getHttpAuthCredentials(
        protectionSpace: protectionSpace);
    expect(credentials, isEmpty);

    await httpAuthCredentialDatabase.clearAllAuthCredentials();
  }, skip: shouldSkip);
}
