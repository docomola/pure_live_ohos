import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InAppWebViewSettings', () {
    test('constructor should expose documented configuration properties', () {
      final blocker = ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: '.*'),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      );
      final settings = InAppWebViewSettings(
        javaScriptEnabled: false,
        mediaPlaybackRequiresUserGesture: false,
        domStorageEnabled: false,
        userAgent: 'CustomAgent/1.0',
        applicationNameForUserAgent: 'TestApp',
        useShouldOverrideUrlLoading: true,
        useOnLoadResource: true,
        useOnDownloadStart: true,
        allowFileAccess: false,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        contentBlockers: [blocker],
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        geolocationEnabled: false,
        textZoom: 120,
        enableNativeEmbedMode: true,
        initialScale: 75,
        supportMultipleWindows: true,
        forceDark: ForceDark.ON,
      );

      expect(settings.javaScriptEnabled, isFalse);
      expect(settings.mediaPlaybackRequiresUserGesture, isFalse);
      expect(settings.domStorageEnabled, isFalse);
      expect(settings.userAgent, 'CustomAgent/1.0');
      expect(settings.applicationNameForUserAgent, 'TestApp');
      expect(settings.useShouldOverrideUrlLoading, isTrue);
      expect(settings.useOnLoadResource, isTrue);
      expect(settings.useOnDownloadStart, isTrue);
      expect(settings.allowFileAccess, isFalse);
      expect(settings.verticalScrollBarEnabled, isFalse);
      expect(settings.horizontalScrollBarEnabled, isFalse);
      expect(settings.contentBlockers?.length, 1);
      expect(settings.mixedContentMode, MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW);
      expect(settings.geolocationEnabled, isFalse);
      expect(settings.textZoom, 120);
      expect(settings.enableNativeEmbedMode, isTrue);
      expect(settings.initialScale, 75);
      expect(settings.supportMultipleWindows, isTrue);
      expect(settings.forceDark, ForceDark.ON);
    });

    test('property setters should update configuration values', () {
      final settings = InAppWebViewSettings();

      settings.textZoom = 150;
      settings.javaScriptEnabled = false;
      settings.domStorageEnabled = false;
      settings.allowFileAccess = false;

      expect(settings.textZoom, 150);
      expect(settings.javaScriptEnabled, isFalse);
      expect(settings.domStorageEnabled, isFalse);
      expect(settings.allowFileAccess, isFalse);
    });

    test('useHybridComposition should be configurable', () {
      final settings = InAppWebViewSettings(useHybridComposition: false);
      expect(settings.useHybridComposition, isFalse);
    });

    test('darkMode fileAccess domStorageAccess multiWindowAccess spec aliases',
        () {
      // OHOS 接口规格名称映射到 Dart 属性：
      // darkMode -> forceDark
      // fileAccess -> allowFileAccess
      // domStorageAccess -> domStorageEnabled
      // multiWindowAccess -> supportMultipleWindows
      final settings = InAppWebViewSettings(
        forceDark: ForceDark.ON,
        allowFileAccess: true,
        domStorageEnabled: true,
        supportMultipleWindows: true,
        forceDarkAccess: true,
      );

      expect(settings.forceDark, ForceDark.ON); // darkMode
      expect(settings.allowFileAccess, isTrue); // fileAccess
      expect(settings.domStorageEnabled, isTrue); // domStorageAccess
      expect(settings.supportMultipleWindows, isTrue); // multiWindowAccess
      expect(settings.forceDarkAccess, isTrue);

      final map = settings.toMap();
      // Dart channel keys consumed by OHOS InAppWebViewSettings.parse()
      expect(map['forceDark'], isNotNull); // -> native darkMode
      expect(map['allowFileAccess'], isTrue); // -> native fileAccess
      expect(map['domStorageEnabled'], isTrue); // -> native domStorageAccess
      expect(map['supportMultipleWindows'], isTrue); // -> native multiWindowAccess
      expect(map['forceDarkAccess'], isTrue);
    });

    test('darkMode Off Auto On should serialize via forceDark', () {
      expect(
        InAppWebViewSettings(forceDark: ForceDark.OFF).forceDark,
        ForceDark.OFF,
      );
      expect(
        InAppWebViewSettings(forceDark: ForceDark.AUTO).forceDark,
        ForceDark.AUTO,
      );
      expect(
        InAppWebViewSettings(forceDark: ForceDark.ON).forceDark,
        ForceDark.ON,
      );
    });

    test('fileAccess domStorageAccess multiWindowAccess should toggle independently',
        () {
      final settings = InAppWebViewSettings(
        allowFileAccess: false,
        domStorageEnabled: false,
        supportMultipleWindows: false,
      );

      expect(settings.allowFileAccess, isFalse); // fileAccess
      expect(settings.domStorageEnabled, isFalse); // domStorageAccess
      expect(settings.supportMultipleWindows, isFalse); // multiWindowAccess

      settings.allowFileAccess = true;
      settings.domStorageEnabled = true;
      settings.supportMultipleWindows = true;

      expect(settings.allowFileAccess, isTrue);
      expect(settings.domStorageEnabled, isTrue);
      expect(settings.supportMultipleWindows, isTrue);

      final map = settings.toMap();
      expect(map['allowFileAccess'], isTrue);
      expect(map['domStorageEnabled'], isTrue);
      expect(map['supportMultipleWindows'], isTrue);
    });

    test('setTextZoom setJavaScriptEnabled setDomStorageEnabled setAllowFileAccess',
        () {
      final settings = InAppWebViewSettings();

      // Spec lists Android-style setters; Dart exposes them as property assignments.
      settings.textZoom = 125;
      settings.javaScriptEnabled = false;
      settings.domStorageEnabled = false;
      settings.allowFileAccess = false;

      expect(settings.textZoom, 125);
      expect(settings.javaScriptEnabled, isFalse);
      expect(settings.domStorageEnabled, isFalse);
      expect(settings.allowFileAccess, isFalse);
    });

    test('toMap fromMap copy toJson and toString should round-trip settings',
        () {
      final original = InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        allowFileAccess: false,
        supportMultipleWindows: true,
        forceDark: ForceDark.AUTO,
        forceDarkAccess: true,
        textZoom: 110,
        useHybridComposition: false,
      );

      final map = original.toMap();
      final restored = InAppWebViewSettings.fromMap(map);
      final copied = original.copy();

      expect(restored?.javaScriptEnabled, isTrue);
      expect(restored?.domStorageEnabled, isTrue);
      expect(restored?.allowFileAccess, isFalse);
      expect(restored?.supportMultipleWindows, isTrue);
      expect(restored?.forceDark, ForceDark.AUTO);
      expect(restored?.forceDarkAccess, isTrue);
      expect(restored?.textZoom, 110);
      expect(restored?.useHybridComposition, isFalse);
      expect(copied.javaScriptEnabled, isTrue);
      expect(copied.forceDark, ForceDark.AUTO);
      expect(original.toJson(), map);
      expect(original.toString(), contains('InAppWebViewSettings'));
    });
  });
}
