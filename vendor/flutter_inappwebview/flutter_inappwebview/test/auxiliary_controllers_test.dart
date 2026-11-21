import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/test_platform.dart';

void main() {
  group('FindInteractionController', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor and methods should delegate to platform', () async {
      var callbackInvoked = false;
      final controller = FindInteractionController(
        onFindResultReceived: (_, active, total, done) {
          callbackInvoked = true;
          expect(active, 1);
          expect(total, 2);
          expect(done, isTrue);
        },
      );

      expect(controller.platform, isA<FakePlatformFindInteractionController>());
      expect(controller.onFindResultReceived, isNotNull);
      await controller.findAll(find: 'hello');
      await controller.findNext(forward: true);
      await controller.clearMatches();
      await controller.setSearchText('hello');
      expect(await controller.getSearchText(), 'hello');
      expect(await controller.isFindNavigatorVisible(), isFalse);
      await controller.updateResultCount();
      await controller.presentFindNavigator();
      await controller.dismissFindNavigator();
      expect(await controller.getActiveFindSession(), isNull);

      controller.onFindResultReceived?.call(
        FakePlatformFindInteractionController(
          const PlatformFindInteractionControllerCreationParams(),
        ),
        1,
        2,
        true,
      );
      expect(callbackInvoked, isTrue);
      controller.dispose();
    });

    test('fromPlatformCreationParams and fromPlatform should create controller',
        () {
      final fromParams = FindInteractionController.fromPlatformCreationParams(
        params: const PlatformFindInteractionControllerCreationParams(),
      );
      expect(fromParams.platform, isA<FakePlatformFindInteractionController>());

      final fromPlatform = FindInteractionController.fromPlatform(
        platform: FakePlatformFindInteractionController(
          const PlatformFindInteractionControllerCreationParams(),
        ),
      );
      expect(fromPlatform.platform, isA<FakePlatformFindInteractionController>());
    });
  });

  group('PullToRefreshController', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor and methods should delegate to platform', () async {
      var refreshed = false;
      final controller = PullToRefreshController(
        onRefresh: () => refreshed = true,
        settings: PullToRefreshSettings(enabled: true),
      );

      expect(controller.onRefresh, isNotNull);
      expect(controller.settings.enabled, isTrue);
      expect(controller.platform, isA<FakePlatformPullToRefreshController>());
      await controller.setEnabled(true);
      expect(await controller.isEnabled(), isTrue);
      await controller.beginRefreshing();
      expect(await controller.isRefreshing(), isTrue);
      await controller.endRefreshing();
      expect(await controller.isRefreshing(), isFalse);
      await controller.setColor(const Color(0xFF0000FF));
      await controller.setBackgroundColor(const Color(0xFFFFFFFF));
      await controller.setDistanceToTriggerSync(120);
      await controller.setSlingshotDistance(80);
      expect(await controller.getDefaultSlingshotDistance(), 64);
      await controller.setIndicatorSize(PullToRefreshSize.DEFAULT);
      await controller.setStyledTitle(AttributedString(string: 'Pull'));
      controller.onRefresh?.call();
      expect(refreshed, isTrue);
      controller.dispose();
    });

    test('fromPlatformCreationParams and fromPlatform should create controller',
        () {
      final fromParams = PullToRefreshController.fromPlatformCreationParams(
        params: PlatformPullToRefreshControllerCreationParams(
          onRefresh: () {},
          settings: PullToRefreshSettings(enabled: true),
        ),
      );
      expect(fromParams.platform, isA<FakePlatformPullToRefreshController>());

      final fromPlatform = PullToRefreshController.fromPlatform(
        platform: FakePlatformPullToRefreshController(
          PlatformPullToRefreshControllerCreationParams(
            onRefresh: () {},
          ),
        ),
      );
      expect(fromPlatform.onRefresh, isNotNull);
    });
  });

  group('HttpAuthCredentialDatabase', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('instance and methods should delegate to platform', () async {
      final db = HttpAuthCredentialDatabase.instance();
      expect(identical(db, HttpAuthCredentialDatabase.instance()), isTrue);

      final protectionSpace = URLProtectionSpace(
        host: 'example.com',
        protocol: 'https',
        port: 443,
      );
      final credential = URLCredential(username: 'user', password: 'pass');

      expect(await db.getAllAuthCredentials(), isEmpty);
      await db.setHttpAuthCredential(
        protectionSpace: protectionSpace,
        credential: credential,
      );
      expect(await db.getHttpAuthCredentials(protectionSpace: protectionSpace),
          isEmpty);
      await db.removeHttpAuthCredential(
        protectionSpace: protectionSpace,
        credential: credential,
      );
      await db.removeHttpAuthCredentials(protectionSpace: protectionSpace);
      await db.clearAllAuthCredentials();
    });

    test('dispose should delegate to platform', () {
      final fake = FakePlatformHttpAuthCredentialDatabase(
        const PlatformHttpAuthCredentialDatabaseCreationParams(),
      );
      final db = HttpAuthCredentialDatabase.fromPlatform(fake);
      db.dispose();
      expect(fake.disposed, isTrue);
    });

    test('fromPlatformCreationParams and fromPlatform should create database',
        () {
      final fromParams = HttpAuthCredentialDatabase.fromPlatformCreationParams(
        const PlatformHttpAuthCredentialDatabaseCreationParams(),
      );
      expect(fromParams.platform, isA<FakePlatformHttpAuthCredentialDatabase>());

      final fromPlatform = HttpAuthCredentialDatabase.fromPlatform(
        FakePlatformHttpAuthCredentialDatabase(
          const PlatformHttpAuthCredentialDatabaseCreationParams(),
        ),
      );
      expect(fromPlatform.platform, isA<FakePlatformHttpAuthCredentialDatabase>());
    });
  });

  group('ChromeSafariBrowser', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor static and instance methods should delegate', () async {
      expect(await ChromeSafariBrowser.isAvailable(), isTrue);
      expect(await ChromeSafariBrowser.getMaxToolbarItems(), 5);
      expect(await ChromeSafariBrowser.getPackageName(), 'com.android.chrome');
      await ChromeSafariBrowser.clearWebsiteData();
      final token = await ChromeSafariBrowser.prewarmConnections(
        [WebUri('https://example.com')],
      );
      expect(token, isNotNull);
      await ChromeSafariBrowser.invalidatePrewarmingToken(token!);

      final browser = ChromeSafariBrowser();
      expect(browser.id, isNotEmpty);
      await browser.open(url: WebUri('https://example.com'));
      await browser.launchUrl(url: WebUri('https://example.com'));
      expect(await browser.mayLaunchUrl(url: WebUri('https://example.com')),
          isTrue);
      expect(
        await browser.validateRelationship(
          relation: CustomTabsRelationType.USE_AS_ORIGIN,
          origin: WebUri('https://example.com'),
        ),
        isTrue,
      );
      expect(browser.isOpened(), isTrue);
      browser.setActionButton(
        ChromeSafariBrowserActionButton(
          id: 1,
          description: 'Share',
          icon: Uint8List.fromList([1]),
        ),
      );
      await browser.updateActionButton(
        icon: Uint8List.fromList([1]),
        description: 'Share',
      );
      browser.setSecondaryToolbar(
        ChromeSafariBrowserSecondaryToolbar(
          layout: AndroidResource(name: 'secondary_toolbar'),
        ),
      );
      await browser.updateSecondaryToolbar(
        ChromeSafariBrowserSecondaryToolbar(
          layout: AndroidResource(name: 'secondary_toolbar'),
        ),
      );
      browser.addMenuItem(
        ChromeSafariBrowserMenuItem(id: 1, label: 'Copy'),
      );
      browser.addMenuItems([
        ChromeSafariBrowserMenuItem(id: 2, label: 'Open'),
      ]);
      expect(
        await browser.requestPostMessageChannel(
          sourceOrigin: WebUri('https://example.com'),
        ),
        isTrue,
      );
      expect(await browser.postMessage('hello'),
          CustomTabsPostMessageResultType.SUCCESS);
      expect(await browser.isEngagementSignalsApiAvailable(), isFalse);
      await browser.close();
      browser.dispose();
    });

    test('fromPlatformCreationParams and fromPlatform should create browser',
        () {
      final fromParams = ChromeSafariBrowser.fromPlatformCreationParams(
        const PlatformChromeSafariBrowserCreationParams(),
      );
      expect(fromParams.platform, isA<FakePlatformChromeSafariBrowser>());

      final fromPlatform = ChromeSafariBrowser.fromPlatform(
        FakePlatformChromeSafariBrowser(),
      );
      expect(fromPlatform.platform, isA<FakePlatformChromeSafariBrowser>());
    });
  });
}
