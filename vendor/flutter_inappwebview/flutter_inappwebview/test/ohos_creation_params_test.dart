import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_inappwebview_ohos/src/find_interaction/find_interaction_controller.dart';
import 'package:flutter_inappwebview_ohos/src/in_app_webview/in_app_webview.dart';
import 'package:flutter_inappwebview_ohos/src/pull_to_refresh/pull_to_refresh_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OhosInAppWebViewWidgetCreationParams', () {
    test('should accept findInteractionController and pullToRefreshController',
        () {
      final findController = OhosFindInteractionController(
        const OhosFindInteractionControllerCreationParams(),
      );
      final pullController = OhosPullToRefreshController(
        OhosPullToRefreshControllerCreationParams(
          settings: PullToRefreshSettings(enabled: true),
          onRefresh: () {},
        ),
      );

      final params = OhosInAppWebViewWidgetCreationParams(
        findInteractionController: findController,
        pullToRefreshController: pullController,
      );

      expect(params.findInteractionController, same(findController));
      expect(params.pullToRefreshController, same(pullController));
    });

    test('should construct with default optional controllers', () {
      final params = OhosInAppWebViewWidgetCreationParams();
      expect(params.findInteractionController, isNull);
      expect(params.pullToRefreshController, isNull);
    });

    test('fromPlatformInAppWebViewWidgetCreationParams should copy controllers',
        () {
      final findController = OhosFindInteractionController(
        const OhosFindInteractionControllerCreationParams(),
      );
      final pullController = OhosPullToRefreshController(
        OhosPullToRefreshControllerCreationParams(
          settings: PullToRefreshSettings(enabled: true),
          onRefresh: () {},
        ),
      );

      final params =
          OhosInAppWebViewWidgetCreationParams.fromPlatformInAppWebViewWidgetCreationParams(
        PlatformInAppWebViewWidgetCreationParams(
          findInteractionController: findController,
          pullToRefreshController: pullController,
        ),
      );

      expect(params.findInteractionController, same(findController));
      expect(params.pullToRefreshController, same(pullController));
    });
  });
}
