import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('InAppLocalhostServer', () {
    late FakePlatformInAppLocalhostServer fake;
    late InAppLocalhostServer server;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      fake = FakePlatformInAppLocalhostServer();
      server = InAppLocalhostServer.fromPlatform(fake);
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should create server through platform factory', () {
      final configured = InAppLocalhostServer(
        port: 3000,
        directoryIndex: 'home.html',
        documentRoot: '/www',
        shared: true,
      );

      expect(configured.port, 3000);
      expect(configured.directoryIndex, 'home.html');
      expect(configured.documentRoot, '/www');
      expect(configured.shared, isTrue);
    });

    test('fromPlatform should expose port and document settings', () {
      expect(server.port, 9090);
      expect(server.directoryIndex, 'main.html');
      expect(server.documentRoot, '/assets');
      expect(server.shared, isTrue);
      expect(server.isRunning(), isFalse);
      expect(server.platform, same(fake));
    });

    test('fromPlatformCreationParams should create server through factory',
        () {
      final configured = InAppLocalhostServer.fromPlatformCreationParams(
        const PlatformInAppLocalhostServerCreationParams(
          port: 4000,
          directoryIndex: 'app.html',
          documentRoot: '/www',
          shared: false,
        ),
      );

      expect(configured.port, 4000);
      expect(configured.directoryIndex, 'app.html');
      expect(configured.documentRoot, '/www');
      expect(configured.shared, isFalse);
    });

    test('start should mark server as running', () async {
      await server.start();

      expect(fake.startCalled, isTrue);
      expect(server.isRunning(), isTrue);
    });

    test('close should stop running server', () async {
      await server.start();
      await server.close();

      expect(fake.closeCalled, isTrue);
      expect(server.isRunning(), isFalse);
    });
  });
}
