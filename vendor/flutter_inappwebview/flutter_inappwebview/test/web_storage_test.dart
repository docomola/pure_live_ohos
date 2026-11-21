import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('WebStorage', () {
    late FakePlatformLocalStorage fakeLocal;
    late FakePlatformSessionStorage fakeSession;
    late WebStorage webStorage;

    setUp(() {
      fakeLocal = FakePlatformLocalStorage();
      fakeSession = FakePlatformSessionStorage();
      webStorage = WebStorage.fromPlatform(
        platform: FakePlatformWebStorage(
          localStorage: fakeLocal,
          sessionStorage: fakeSession,
        ),
      );
    });

    tearDown(() {
      webStorage.dispose();
    });

    test('should expose localStorage and sessionStorage', () {
      expect(webStorage.localStorage, isA<LocalStorage>());
      expect(webStorage.sessionStorage, isA<SessionStorage>());
    });

    test('LocalStorage should support full Storage API', () async {
      final storage = webStorage.localStorage;
      await storage.setItem(key: 'k1', value: 'v1');
      expect(await storage.getItem(key: 'k1'), 'v1');
      expect(await storage.length(), 1);
      final items = await storage.getItems();
      expect(items.any((i) => i.key == 'k1'), isTrue);
      expect(await storage.key(index: 0), 'k1');
      await storage.removeItem(key: 'k1');
      expect(await storage.getItem(key: 'k1'), isNull);
      await storage.setItem(key: 'a', value: '1');
      await storage.clear();
      expect(await storage.length(), 0);
      storage.dispose();
    });

    test('SessionStorage should support full Storage API', () async {
      final storage = webStorage.sessionStorage;
      await storage.setItem(key: 's1', value: 'sv1');
      expect(await storage.getItem(key: 's1'), 'sv1');
      expect(await storage.length(), 1);
      expect(await storage.key(index: 0), 's1');
      await storage.clear();
      expect(await storage.length(), 0);
      storage.dispose();
    });

    test('WebStorage.dispose should dispose underlying storage', () {
      final platform = webStorage.platform as FakePlatformWebStorage;
      webStorage.dispose();
      expect(platform.disposed, isTrue);
    });

    test('constructor should create web storage from platform storages', () {
      final previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      try {
        final storage = WebStorage(
          localStorage: FakePlatformLocalStorage(),
          sessionStorage: FakePlatformSessionStorage(),
        );
        expect(storage.localStorage, isA<LocalStorage>());
        expect(storage.sessionStorage, isA<SessionStorage>());
        storage.dispose();
      } finally {
        restoreInAppWebViewPlatform(previousPlatform);
      }
    });

    test('fromPlatformCreationParams should create web storage', () {
      final previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      try {
        final storage = WebStorage.fromPlatformCreationParams(
          params: PlatformWebStorageCreationParams(
            localStorage: FakePlatformLocalStorage(),
            sessionStorage: FakePlatformSessionStorage(),
          ),
        );
        expect(storage.localStorage, isA<LocalStorage>());
        expect(storage.sessionStorage, isA<SessionStorage>());
      } finally {
        restoreInAppWebViewPlatform(previousPlatform);
      }
    });

    test('LocalStorage and SessionStorage constructors should use platform factory',
        () {
      final previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      try {
        final local = LocalStorage(controller: null);
        final session = SessionStorage(controller: null);
        expect(local.platform, isA<FakePlatformLocalStorage>());
        expect(session.platform, isA<FakePlatformSessionStorage>());
        expect(local.webStorageType, WebStorageType.LOCAL_STORAGE);
        expect(session.webStorageType, WebStorageType.SESSION_STORAGE);

        final platformController = FakePlatformInAppWebViewController();
        final controller = InAppWebViewController.fromPlatform(
          platform: platformController,
        );
        final linkedLocal = LocalStorage(controller: controller);
        expect(linkedLocal.controller, same(platformController));

        final localFromParams = LocalStorage.fromPlatformCreationParams(
          params: PlatformLocalStorageCreationParams(
            PlatformStorageCreationParams(
              controller: null,
              webStorageType: WebStorageType.LOCAL_STORAGE,
            ),
          ),
        );
        final sessionFromParams = SessionStorage.fromPlatformCreationParams(
          params: PlatformSessionStorageCreationParams(
            PlatformStorageCreationParams(
              controller: null,
              webStorageType: WebStorageType.SESSION_STORAGE,
            ),
          ),
        );
        expect(localFromParams.platform, isA<FakePlatformLocalStorage>());
        expect(sessionFromParams.platform, isA<FakePlatformSessionStorage>());
      } finally {
        restoreInAppWebViewPlatform(previousPlatform);
      }
    });
  });

  group('WebStorageManager', () {
    late FakePlatformWebStorageManager fakeManager;
    late WebStorageManager manager;

    setUp(() {
      fakeManager = FakePlatformWebStorageManager();
      manager = WebStorageManager.fromPlatform(fakeManager);
    });

    test('instance should return singleton when platform is available', () {
      final previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      try {
        expect(identical(WebStorageManager.instance(), WebStorageManager.instance()),
            isTrue);
      } finally {
        restoreInAppWebViewPlatform(previousPlatform);
      }
    });

    test('fromPlatformCreationParams should create manager', () {
      final manager = WebStorageManager.fromPlatformCreationParams(
        const PlatformWebStorageManagerCreationParams(),
      );
      expect(manager.platform, isA<FakePlatformWebStorageManager>());
    });

    test('constructor should create manager from default params', () {
      final previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
      try {
        final manager = WebStorageManager();
        expect(manager.platform, isA<FakePlatformWebStorageManager>());
      } finally {
        restoreInAppWebViewPlatform(previousPlatform);
      }
    });

    test('getOrigins should return storage origins', () async {
      final origins = await manager.getOrigins();
      expect(origins, isNotEmpty);
      expect(origins.first.origin, 'https://example.com');
    });

    test('deleteAllData should clear storage', () async {
      await manager.deleteAllData();
      expect(fakeManager.deleteAllCalled, isTrue);
    });

    test('deleteOrigin should remove specific origin', () async {
      await manager.deleteOrigin(origin: 'https://example.com');
      expect(fakeManager.deletedOrigin, 'https://example.com');
    });

    test('getQuotaForOrigin should return quota', () async {
      expect(await manager.getQuotaForOrigin(origin: 'https://example.com'),
          1000);
    });

    test('getUsageForOrigin should return usage', () async {
      expect(await manager.getUsageForOrigin(origin: 'https://example.com'),
          100);
    });

    test('fetchDataRecords should return records', () async {
      final records = await manager.fetchDataRecords(
          dataTypes: {WebsiteDataType.WKWebsiteDataTypeLocalStorage});
      expect(records, isNotEmpty);
    });

    test('removeDataFor should complete without error', () async {
      await manager.removeDataFor(
        dataTypes: {WebsiteDataType.WKWebsiteDataTypeLocalStorage},
        dataRecords: [
          WebsiteDataRecord(
            displayName: 'example.com',
            dataTypes: {WebsiteDataType.WKWebsiteDataTypeLocalStorage},
          ),
        ],
      );
    });

    test('removeDataModifiedSince should complete without error', () async {
      await manager.removeDataModifiedSince(
        dataTypes: {WebsiteDataType.WKWebsiteDataTypeLocalStorage},
        date: DateTime.now(),
      );
    });
  });
}
