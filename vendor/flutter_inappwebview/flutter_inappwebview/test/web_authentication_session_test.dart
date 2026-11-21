import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('WebAuthenticationSession', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should create platform-backed session', () {
      final session = WebAuthenticationSession();
      expect(session.id, isNotEmpty);
      expect(session.platform, isA<FakePlatformWebAuthenticationSession>());
    });

    test('create should initialize session with auth parameters', () async {
      WebUri? completedUrl;
      final session = await WebAuthenticationSession.create(
        url: WebUri('https://example.com/login'),
        callbackURLScheme: 'myapp',
        initialSettings: WebAuthenticationSessionSettings(
          prefersEphemeralWebBrowserSession: true,
        ),
        onComplete: (url, error) async {
          completedUrl = url;
        },
      );

      expect(session.url.rawValue, 'https://example.com/login');
      expect(session.callbackURLScheme, 'myapp');
      expect(session.initialSettings?.prefersEphemeralWebBrowserSession, isTrue);
      expect(await session.canStart(), isTrue);
      expect(await session.start(), isTrue);
      await session.onComplete?.call(WebUri('myapp://callback'), null);
      expect(completedUrl?.rawValue, 'myapp://callback');
      await session.cancel();
      await session.dispose();
    });

    test('isAvailable should delegate to platform static implementation', () async {
      expect(await WebAuthenticationSession.isAvailable(), isTrue);
    });

    test('fromPlatform should expose wrapped platform session', () {
      final fake = FakePlatformWebAuthenticationSession(
        url: WebUri('https://auth.example.com'),
        callbackURLSchemeValue: 'callback',
      );
      final session = WebAuthenticationSession.fromPlatform(platform: fake);

      expect(session.id, 'fake-auth-session');
      expect(session.url.rawValue, 'https://auth.example.com');
      expect(session.callbackURLScheme, 'callback');
    });
  });
}
