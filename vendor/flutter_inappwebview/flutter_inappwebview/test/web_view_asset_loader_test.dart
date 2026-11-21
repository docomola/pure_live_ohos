import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_controller.dart';
import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('WebViewAssetLoader', () {
    late FakeInAppWebViewPlatform fakePlatform;
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      fakePlatform = installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should register path handlers', () {
      final assetsHandler = FakePathHandler(
        path: '/assets/',
        handlerType: 'AssetsPathHandler',
      );
      final resourcesHandler = FakePathHandler(
        path: '/res/',
        handlerType: 'ResourcesPathHandler',
      );

      final loader = WebViewAssetLoader(
        domain: 'cdn.example.com',
        httpAllowed: true,
        pathHandlers: [assetsHandler, resourcesHandler],
      );

      expect(loader.domain, 'cdn.example.com');
      expect(loader.httpAllowed, isTrue);
      expect(loader.pathHandlers?.length, 2);
      expect(loader.pathHandlers?.first.path, '/assets/');
      expect(loader.pathHandlers?.last.path, '/res/');
    });

    test('FakePathHandler should expose path and type metadata', () {
      final handler = FakePathHandler(
        path: '/assets/',
        handlerType: 'AssetsPathHandler',
      );

      expect(handler.path, '/assets/');
      expect(handler.type, 'AssetsPathHandler');
      expect(handler.toMap()['type'], 'AssetsPathHandler');
    });

    test('toMap should serialize loader configuration', () {
      final loader = WebViewAssetLoader(
        domain: WebViewAssetLoader.DEFAULT_DOMAIN,
        httpAllowed: true,
        pathHandlers: [
          FakePathHandler(
            path: '/assets/',
            handlerType: 'AssetsPathHandler',
          ),
        ],
      );

      final map = loader.toMap();

      expect(map['domain'], WebViewAssetLoader.DEFAULT_DOMAIN);
      expect(map['httpAllowed'], isTrue);
      expect(map['pathHandlers'], isA<List>());
      expect((map['pathHandlers'] as List).first['path'], '/assets/');
    });

    test('copy should preserve domain and httpAllowed flags', () {
      final loader = WebViewAssetLoader(
        domain: 'assets.test',
        httpAllowed: false,
      );

      final copied = WebViewAssetLoader(
        domain: loader.domain,
        httpAllowed: loader.httpAllowed,
        pathHandlers: loader.pathHandlers,
      );

      expect(copied.domain, loader.domain);
      expect(copied.httpAllowed, loader.httpAllowed);
    });

    test('AssetsPathHandler fromPlatform and fromPlatformCreationParams should work',
        () {
      final fake = FakePlatformAssetsPathHandler(
        PlatformAssetsPathHandlerCreationParams(
          PlatformPathHandlerCreationParams(path: '/assets/'),
        ),
      );
      final fromPlatform = AssetsPathHandler.fromPlatform(platform: fake);
      expect(fromPlatform.path, '/assets/');
      expect(fromPlatform, isA<PathHandler>());

      final fromParams = AssetsPathHandler.fromPlatformCreationParams(
        params: PlatformAssetsPathHandlerCreationParams(
          PlatformPathHandlerCreationParams(path: '/static/'),
        ),
      );
      expect(fromParams.path, '/static/');
    });

    test('AssetsPathHandler should register through platform factory', () async {
      final handler = AssetsPathHandler(path: '/assets/');

      expect(handler.path, '/assets/');
      expect(handler.type, 'AssetsPathHandler');
      expect(handler.toMap()['path'], '/assets/');
      expect(await handler.handle('/assets/index.html'), isNull);
    });

    test('ResourcesPathHandler should register through platform factory', () async {
      final handler = ResourcesPathHandler(path: '/res/');

      expect(handler.path, '/res/');
      expect(handler.type, 'ResourcesPathHandler');
      expect(handler.toJson()['type'], 'ResourcesPathHandler');
      expect(await handler.handle('/res/style.css'), isNull);
    });

    test('InternalStoragePathHandler should expose directory metadata', () {
      final handler = InternalStoragePathHandler(
        path: '/files/',
        directory: 'documents',
      );

      expect(handler.path, '/files/');
      expect(handler.directory, 'documents');
      expect(handler.type, 'InternalStoragePathHandler');
    });

    test('CustomPathHandler subclass should handle requested paths', () async {
      final handler = _TestCustomPathHandler();
      final response = await handler.handle('/custom/page.html');

      expect(handler.path, '/custom/');
      expect(handler.type, 'CustomPathHandler');
      expect(response?.contentType, 'text/html');
    });

    test('WebViewAssetLoader handle path and type should use PathHandler', () async {
      final handler = AssetsPathHandler(path: '/assets/');

      expect(handler.path, '/assets/');
      expect(handler.type, 'AssetsPathHandler');
      expect(await handler.handle('/assets/demo.html'), isNull);

      final loader = WebViewAssetLoader(
        pathHandlers: [handler],
      );
      expect(loader.pathHandlers?.first.path, '/assets/');
      expect(loader.pathHandlers?.first.type, 'AssetsPathHandler');
    });
  });
}

class _TestCustomPathHandler extends CustomPathHandler {
  _TestCustomPathHandler() : super(path: '/custom/');

  @override
  Future<WebResourceResponse?> handle(String path) async => WebResourceResponse(
        contentType: 'text/html',
        data: null,
      );
}
