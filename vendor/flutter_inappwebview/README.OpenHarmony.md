<p align="center">
  <h1 align="center"><code>flutter_inappwebview</code></h1>
</p>

This project is based on [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview).

## Introduction

flutter_inappwebview is a Flutter plugin that allows you to add an inline webview, use a headless webview, and open an in-app browser window. This repository is the OpenHarmony adaptation, forked from the upstream [flutter_inappwebview](https://github.com/pichillilorenzo/flutter_inappwebview) project. It supports Flutter **3.22**, **3.27**, and **3.35**.

## Download and Installation

Go to your project directory and add the following dependency in pubspec.yaml:

```yaml
dependencies:
  flutter_inappwebview:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_inappwebview.git
      path: flutter_inappwebview
      # ref: Select the TAG version that matches your Flutter framework version from the table below
      ref: 6.1.5-ohos-1.0.1
```

Execute the command

```bash
flutter pub get
```

> TAG naming rule: `original_version-ohos-version`. See [CHANGELOG.OpenHarmony.md](./CHANGELOG.OpenHarmony.md) for changes between TAGs.

| Flutter Framework Version | TAG Name | Branch | DevEco Studio | SDK | ROM |
|---|---|---|---|---|---|
| 3.22 | 6.1.5-ohos-1.0.1 | br_v6.1.5_ohos | 5.0.0 release(5.0.13.200) | 5.0.0(12) | 5.1.0.120 SP3 |
| 3.27 | 6.1.5-ohos-1.0.1 | br_v6.1.5_ohos | 5.1.0 release(5.1.0.828) | 5.0.0(12) | 5.1.0.130 SP8 |
| 3.35 | 6.1.5-ohos-1.0.1 | br_v6.1.5_ohos | 5.1.0 release(5.1.0.828) | 5.0.0(12) | 5.1.0.130 SP8 |

## Constraints and Limitations

### OpenHarmony Environment Setup

1. Install [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) (matching your Flutter SDK version).
2. Open **Settings → OpenHarmony SDK** and install the SDK and toolchains (matching your Flutter SDK version).
3. Install the Flutter OpenHarmony SDK and run `flutter doctor` to verify the HarmonyOS toolchain is available.
4. Connect an OpenHarmony device or start an emulator, then run `flutter devices` to confirm the device is visible.
5. Configure permissions in `ohos/entry/src/main/module.json5` (see [Permission Requirements](#permission-requirements) below), then run `flutter run` or `flutter build hap`.

### Compatibility

Verified on the following versions:

1. Flutter: 3.22.0-ohos-1.0.0, DevEco Studio: 5.0.0 release(5.0.13.200), SDK: 5.0.0(12), ROM: 5.1.0.120 SP3;
2. Flutter: 3.27.5-ohos-0.0.1, DevEco Studio: 5.1.0 release(5.1.0.828), SDK: 5.0.0(12), ROM: 5.1.0.130 SP8;
3. Flutter: 3.35.0-ohos-0.0.1, DevEco Studio: 5.1.0 release(5.1.0.828), SDK: 5.0.0(12), ROM: 5.1.0.130 SP8;

> The following features depend on specific API versions. Compiling with a lower API version or running on a lower API ROM may limit functionality.

1. [removeAllCache](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-webview-webviewcontroller#removeallcache18) enables the `clearAllCache` API. It requires API 18+ at compile time and API 18+ ROM at runtime.

### Rendering Constraints

> [!IMPORTANT]
> On OHOS, `InAppWebView` integrates with Flutter via PlatformView; the Web component is rendered as a surface node through the texture-composition path. The physical-pixel height of this surface node has an upper limit; exceeding it results in a silent white screen (no error, no log).

For the full symptom description, root-cause analysis, and solutions, see [InAppWebView White Screen Caused by Excessive Content Height](docs/en/WebViewWhiteScreenIssue.md).

### Soft Keyboard Avoid Mode

The native Web component uses `WebKeyboardAvoidMode.RESIZE_VISUAL` by default. When the soft keyboard appears, only the visual viewport is adjusted.

### Version Upgrade Migration

> When upgrading across Flutter major versions, confirm the `ref` TAG in pubspec.yaml and run `flutter pub get` again.

1. **Switching among Flutter 3.22 / 3.27 / 3.35**: Keep the same TAG (`6.1.5-ohos-1.0.0`) and switch DevEco Studio / SDK / ROM per the table above; if using `WebStorageManager.clearAllCache`, API 18+ compile and runtime environment is required.
2. After upgrading, run `flutter clean` and rebuild the OHOS project (`flutter build hap`).

### Permission Requirements

Loading web pages requires `ohos.permission.INTERNET`. Print, camera, or microphone features require additional permissions.

Add the following in `entry/src/main/module.json5`:

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET"
  },
  {
    "name": "ohos.permission.PRINT"
  },
  {
    "name": "ohos.permission.CAMERA",
    "reason": "$string:camera_permission_reason",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  },
  {
    "name": "ohos.permission.MICROPHONE",
    "reason": "$string:microphone_permission_reason",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

Add the following in `entry/src/main/resources/base/element/string.json`:

```json5
{
  "string": [
    {
      "name": "camera_permission_reason",
      "value": "Used for web camera permission requests"
    },
    {
      "name": "microphone_permission_reason",
      "value": "Used for web microphone permission requests"
    }
  ]
}
```

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    // OpenHarmony: declare ohos.permission.INTERNET and other permissions
    // in entry/src/main/module.json5 before running (see Permission Requirements).
    return Scaffold(
      appBar: AppBar(title: const Text('InAppWebView')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('https://flutter.dev'),
        ),
        onWebViewCreated: (InAppWebViewController controller) {
          _webViewController = controller;
        },
        onLoadStop: (InAppWebViewController controller, WebUri? url) async {
          final String? title = await controller.getTitle();
          debugPrint('Page loaded: $title');
        },
      ),
    );
  }
}
```

## Usage Instructions

### 1. Inline WebView (InAppWebView)

`InAppWebView` embeds web content inside a Flutter page. Use `initialUrlRequest` for the initial URL and `onWebViewCreated` to obtain an `InAppWebViewController` for load, reload, and JavaScript operations.

### 2. JavaScript Bridge

Register Dart handlers with `addJavaScriptHandler`; web pages call them via `window.flutter_inappwebview.callHandler`. Use `evaluateJavascript` to run JavaScript from Dart and read results.

### 3. In-App Browser (InAppBrowser)

`InAppBrowser` provides a standalone browser window with `show`, `hide`, and `close` lifecycle controls. OpenHarmony does not support static open methods such as `openUrlRequest`, `openFile`, or `openData`.

### 4. Cookies and Web Storage

`CookieManager` manages cookies. `WebStorage` and `WebStorageManager` cover page-level `localStorage`/`sessionStorage` and global web storage management.

### 5. Pull-to-Refresh and Content Blocking

Use `PullToRefreshController` with `InAppWebView` for pull-to-refresh. `ContentBlocker` applies URL-based resource blocking rules.

### 6. Local Asset Loading

`WebViewAssetLoader` loads local HTML/CSS/JS from assets or app resources for offline pages.

### 7. Run the Example Project

See [flutter_inappwebview/example](./flutter_inappwebview/example). On an OpenHarmony device or emulator, open the `flutter_inappwebview/example` directory, ensure `ohos/entry/src/main/module.json5` has network and other permissions configured, then run `flutter run`.

> For more APIs and usage, see the [official inappwebview.dev documentation](https://inappwebview.dev/docs/intro).

## API Reference

> "OpenHarmony Support" value "yes" means the platform supports the API; "no" means not supported; "partially" means partially supported. Usage is consistent across platforms.

### InAppWebView 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| key | Flutter framework base identifier | Key | / | Key | No | yes |
| controllerFromPlatform | Callback to get WebView controller from platform | function | PlatformInAppWebViewController controller | void | No | yes |
| windowId | Window ID identifier | int | / | int | No | no |
| initialUrlRequest | Initial URLRequest to load | WebUri | / | WebUri | No | yes |
| initialFile | Initial local file path to load | String | / | String | No | yes |
| initialData | Initial HTML data to load | InAppWebViewInitialData | / | InAppWebViewInitialData | No | yes |
| onWebViewCreated | WebView creation event callback | function | InAppWebViewController controller | void | No | yes |
| onLoadStart | URL loading start event callback | function | InAppWebViewController controller, WebUri? url | void | No | yes |
| onLoadStop | URL loading completion callback | function | InAppWebViewController controller, WebUri? url | void | No | yes |
| onReceivedError | Loading error reception callback | function | InAppWebViewController controller, WebUri? url, WebResourceError error | void | No | yes |
| onReceivedHttpError | HTTP error reception callback | function | InAppWebViewController controller, WebUri? url, WebResourceResponse response | void | No | yes |
| shouldOverrideUrlLoading | URL loading interception callback | function | InAppWebViewController controller, NavigationAction navigationAction | Future<NavigationActionPolicy?> | No | yes |
| onConsoleMessage | Console message callback | function | InAppWebViewController controller, ConsoleMessage consoleMessage | void | No | yes |
| onProgressChanged | Loading progress change callback | function | InAppWebViewController controller, int progress | void | No | yes |
| onPermissionRequest | Permission request callback (camera/location, etc.) | function | InAppWebViewController controller, PermissionRequest permissionRequest | void | No | yes |
| onSafeBrowsingHit | Safe browsing interception callback | function | InAppWebViewController controller, WebUri? url, SafeBrowsingThreatType threatType | void | No | no |
| onZoomScaleChanged | Zoom scale change callback | function | InAppWebViewController controller, double scale | void | No | yes |
| gestureRecognizers | Gesture recognizer collection | Set<Factory<OneSequenceGestureRecognizer>> | / | Set<Factory<OneSequenceGestureRecognizer>> | No | yes |
| keepAlive | Whether to keep WebView alive | InAppWebViewKeepAlive | / | InAppWebViewKeepAlive | No | no |
| onJsAlert | JavaScript alert dialog callback | function | InAppWebViewController controller, JsAlertRequest jsAlertRequest | void | No | yes |
| onJsConfirm | JavaScript confirmation dialog callback | function | InAppWebViewController controller, JsConfirmRequest jsConfirmRequest | void | No | yes |
| onJsPrompt | JavaScript prompt dialog callback | function | InAppWebViewController controller, JsPromptRequest jsPromptRequest | void | No | yes |
| onLoadResource | Resource loading completion callback | function | InAppWebViewController controller, WebResourceResponse response | void | No | no |
| onDownloadStartRequest | File download start callback | function | InAppWebViewController controller, DownloadStartRequest request | void | No | no |
| onCreateWindow | Window creation request callback | function | InAppWebViewController controller, CreateWindowRequest request | void | No | no |
| onCloseWindow | Window closure request callback | function | InAppWebViewController controller | void | No | no |
| onFormResubmission | Form resubmission request | function | InAppWebViewController controller, FormResubmissionAction action | void | No | no |
| onNavigationResponse | Navigation response handling | function | InAppWebViewController controller, NavigationResponseAction action | void | No | no |
| onContentSizeChanged | Content size change callback | function | InAppWebViewController controller, Size contentSize | void | No | no |
| onOverScrolled | Overscroll boundary callback | function | InAppWebViewController controller, int scrollX, bool clampedX, int scrollY, bool clampedY | void | No | yes |
| onEnterFullscreen | Fullscreen entry callback | function | InAppWebViewController controller | void | No | no |
| onExitFullscreen | Fullscreen exit callback | function | InAppWebViewController controller | void | No | no |
| onPrintRequest | Print request callback | function | InAppWebViewController controller | void | No | no |
| onGeolocationPermissionsShowPrompt | Geolocation permission request | function | InAppWebViewController controller, String origin, bool allow | void | No | yes |
| shouldInterceptRequest | Request interception | function | InAppWebViewController controller, WebResourceRequest request | Future<WebResourceResponse?> | No | yes |
| shouldInterceptAjaxRequest | AJAX request interception | function | InAppWebViewController controller, AjaxRequest request | Future<AjaxRequestPolicy?> | No | yes |
| onRenderProcessGone | Render process crash callback | function | InAppWebViewController controller, RenderProcessGoneDetail detail | void | No | no |
| onRenderProcessResponsive | Render process recovery callback | function | InAppWebViewController controller | void | No | no |
| ohosParams | OHOS-specific configuration parameters | OhosInAppWebViewWidgetCreationParams | / | OhosInAppWebViewWidgetCreationParams | No | yes |
| useHybridComposition | Whether to use hybrid rendering mode | bool | / | bool | No | yes |

---

### InAppWebViewSettings 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| javaScriptEnabled | Whether to enable JavaScript execution | bool | bool | void | No | yes |
| mediaPlaybackRequiresUserGesture | Whether media playback requires user gesture | bool | bool | void | No | yes |
| domStorageEnabled | Whether DOM storage (localStorage/sessionStorage) is enabled | bool | bool | void | No | yes |
| userAgent | Custom User-Agent string for WebView | String | String | void | No | yes |
| applicationNameForUserAgent | Application name appended to User-Agent | String | String | void | No | yes |
| javaScriptCanOpenWindowsAutomatically | Whether JavaScript can open new windows automatically | bool | bool | void | No | no |
| useShouldOverrideUrlLoading | Whether to intercept URL loading via shouldOverrideUrlLoading | bool | bool | void | No | yes |
| useOnLoadResource | Whether to monitor resource loading events | bool | bool | void | No | yes |
| useOnDownloadStart | Whether to handle download start events | bool | bool | void | No | yes |
| clearCache | Whether to clear cache before loading | bool | bool | void | No | no |
| verticalScrollBarEnabled | Whether vertical scrollbar is enabled | bool | bool | void | No | yes |
| horizontalScrollBarEnabled | Whether horizontal scrollbar is enabled | bool | bool | void | No | yes |
| supportZoom | Whether zoom control is supported | bool | bool | void | No | no |
| allowFileAccess | Whether file access is allowed | bool | bool | void | No | yes |
| allowFileAccessFromFileURLs | Whether to allow file access from file:// URLs | bool | bool | void | No | no |
| allowUniversalAccessFromFileURLs | Whether universal access from file:// URLs is allowed | bool | bool | void | No | no |
| blockNetworkImage | Whether network image loading is blocked | bool | bool | void | No | no |
| blockNetworkLoads | Whether all network requests are blocked | bool | bool | void | No | no |
| contentBlockers | List of content blocking rules applied to WebView | List<ContentBlocker> | List<ContentBlocker>? | void | No | yes |
| preferredContentMode | Preferred content rendering mode (e.g., desktop, mobile) | enum | ContentMode | void | No | no |
| minimumFontSize | Minimum font size for displaying web content | int | int | void | No | no |
| minimumLogicalFontSize | Minimum logical font size for web content | int | int | void | No | no |
| layoutAlgorithm | Layout algorithm used for HTML rendering | enum | LayoutAlgorithm | void | No | no |
| mixedContentMode | Controls loading strategy for mixed HTTP/HTTPS content | enum | MixedContentMode | void | No | yes |
| geolocationEnabled | Whether geolocation permission is enabled | bool | bool | void | No | yes |
| databaseEnabled | Whether database storage is enabled | bool | bool | void | No | no |
| appCacheEnabled | Whether application cache is enabled | bool | bool | void | No | no |
| appCachePath | Path to store application cache data | String | String | void | No | no |
| textZoom | Page text zoom scale (default 100) | int | int | void | No | yes |
| enableNativeEmbedMode | Enables WebView's native embedding mode | bool | bool | void | No | yes |
| onlineImageAccess | Controls whether online image resources can be accessed | bool | bool | void | No | no |
| blockNetwork | Whether to block all network requests | bool | bool | void | No | no |
| darkMode | Sets WebView's dark mode behavior | enum | WebDarkMode | void | No | yes |
| fileAccess | Whether file access permissions are enabled | bool | bool | void | No | yes |
| domStorageAccess | Whether DOM storage access is enabled | bool | bool | void | No | yes |
| multiWindowAccess | Whether multiple window access is allowed | bool | bool | void | No | yes |
| initialScale | Initial zoom scale for WebView (0 means default) | int | int | void | No | yes |
| needInitialFocus | Whether WebView needs initial focus | bool | bool | void | No | no |
| forceDark | Forces dark theme for WebView content | enum | WebDarkMode | void | No | yes |
| hardwareAcceleration | Whether hardware acceleration is enabled | bool | bool | void | No | no |
| supportMultipleWindows | Whether multiple windows are supported | bool | bool | void | No | yes |

---

### HeadlessInAppWebView 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| run | Runs WebView in headless mode | function | / | Future<void> | No | no |
| getSize | Gets size of headless WebView | function | / | Future<Size?> | No | no |
| setSize | Sets size for headless WebView | function | Size size | Future<void> | No | no |
| dispose | Disposes headless WebView | function | / | Future<void> | No | no |
| initialSize | Initial size setting | Size | Size | Size | No | no |
| initialUrlRequest | Initial URLRequest to load | WebUri | URLRequest? | URLRequest? | No | yes |
| initialFile | Initial local file path to load | String | String? | String? | No | yes |
| initialData | Initial HTML data to load | InAppWebViewInitialData | InAppWebViewInitialData? | InAppWebViewInitialData? | No | yes |
| onWebViewCreated | WebView creation event callback | function | InAppWebViewController controller | void | No | yes |
| onLoadStart | URL loading start event callback | function | InAppWebViewController controller, WebUri? url | void | No | yes |
| onLoadStop | URL loading completion callback | function | InAppWebViewController controller, WebUri? url | void | No | yes |
| onReceivedError | Loading error reception callback | function | InAppWebViewController controller, WebUri? url, WebResourceError error | void | No | yes |
| onConsoleMessage | Console message callback | function | InAppWebViewController controller, ConsoleMessage consoleMessage | void | No | yes |
| shouldOverrideUrlLoading | URL loading interception callback | function | InAppWebViewController controller, NavigationAction navigationAction | Future<NavigationActionPolicy?> | No | yes |
| onJsAlert | JavaScript alert dialog callback | function | InAppWebViewController controller, JsAlertRequest jsAlertRequest | void | No | yes |
| onJsConfirm | JavaScript confirmation dialog callback | function | InAppWebViewController controller, JsConfirmRequest jsConfirmRequest | void | No | yes |
| onPermissionRequest | Permission request callback (camera/location, etc.) | function | InAppWebViewController controller, PermissionRequest permissionRequest | void | No | yes |
| onDownloadStartRequest | File download start callback | function | InAppWebViewController controller, DownloadStartRequest request | void | No | no |
| onContentSizeChanged | Content size change callback | function | InAppWebViewController controller, Size contentSize | void | No | no |
| onRenderProcessGone | Render process crash callback | function | InAppWebViewController controller, RenderProcessGoneDetail detail | void | No | no |

---

### InAppWebViewController 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| getUrl | Gets the URL of the current page | function | / | Future<WebUri?> | No | yes |
| getTitle | Gets the title of the current page | function | / | Future<String?> | No | yes |
| getProgress | Gets the loading progress of the current page (0-100) | function | / | Future<int?> | No | yes |
| loadUrl | Loads the specified URL in the WebView | function | URLRequest urlRequest, WebUri? allowingReadAccessTo | Future<void> | No | yes |
| reload | Reloads the WebView | function | / | Future<void> | No | yes |
| goBack | Navigates back in the WebView's history | function | / | Future<void> | No | partially |
| setSettings | Sets WebView configuration with new settings | function | InAppWebViewSettings settings | Future<void> | No | partially |
| getSettings | Gets current WebView configuration | function | / | Future<InAppWebViewSettings?> | No | yes |
| evaluateJavascript | Executes a JavaScript expression and returns the result | function | String source, ContentWorld? contentWorld | Future<dynamic> | No | yes |
| loadData | Loads HTML data into the WebView | function | String data, String mimeType = "text/html", String encoding = "utf8", WebUri? baseUrl, WebUri? historyUrl, WebUri? allowingReadAccessTo | Future<void> | No | yes |
| postUrl | Loads a specified URL using POST request | function | WebUri url, Uint8List postData | Future<void> | No | yes |
| getOriginalUrl | Gets the original request URL of the current page | function | / | Future<WebUri?> | No | yes |
| getScrollX | Gets horizontal scroll position | function | / | Future<int?> | No | yes |
| getScrollY | Gets vertical scroll position | function | / | Future<int?> | No | yes |
| scrollTo | Scrolls to specified coordinates | function | int x, int y, bool animated = false | Future<void> | No | yes |
| scrollBy | Scrolls by specified delta values | function | int x, int y, bool animated = false | Future<void> | No | yes |
| canGoBack | Checks if navigation back in history is possible | function | / | Future<bool> | No | yes |
| canGoForward | Checks if navigation forward in history is possible | function | / | Future<bool> | No | yes |
| goForward | Navigates forward in WebView history | function | / | Future<void> | No | no |
| pauseTimers | Pauses all timers in WebView | function | / | Future<void> | No | yes |
| resumeTimers | Resumes all timers in WebView | function | / | Future<void> | No | yes |
| clearCache | Clears cache | function | / | Future<void> | No | no |
| zoomBy | Zooms by specified scale | function | double zoomFactor, bool animated = false | Future<void> | No | yes |
| getZoomScale | Gets current zoom scale | function | / | Future<double?> | No | yes |
| getCertificate | Gets SSL certificate information | function | / | Future<SslCertificate?> | No | yes |
| createPdf | Creates PDF document | function | PDFConfiguration? pdfConfiguration | Future<Uint8List?> | No | no |
| printCurrentPage | Prints current page | function | PrintJobSettings? settings | Future<PrintJobController?> | No | yes |
| addJavaScriptHandler | Adds JavaScript message handler | function | String handlerName, JavaScriptHandlerCallback callback | void | No | yes |
| removeJavaScriptHandler | Removes JavaScript message handler | function | String handlerName | JavaScriptHandlerCallback? | No | yes |
| hasJavaScriptHandler | Checks existence of specified handler | function | String handlerName | bool | No | yes |
| canScrollVertically | Checks if vertical scrolling is possible | function | / | Future<bool> | No | yes |
| canScrollHorizontally | Checks if horizontal scrolling is possible | function | / | Future<bool> | No | yes |
| getHitTestResult | Gets hit test result for touched HTML element | function | / | Future<InAppWebViewHitTestResult?> | No | yes |
| getSelectedText | Gets selected text in WebView | function | / | Future<String?> | No | yes |
| getContentHeight | Gets page content height | function | / | Future<int?> | No | yes |
| getContentWidth | Gets page content width | function | / | Future<int?> | No | yes |
| pause | Pauses the WebView | function | / | Future<void> | No | yes |
| resume | Resumes the WebView | function | / | Future<void> | No | yes |
| pageDown | Scrolls page down | function | bool bottom | Future<bool> | No | yes |
| pageUp | Scrolls page up | function | bool top | Future<bool> | No | yes |
| setAllMediaPlaybackSuspended | Sets media playback state | function | bool suspended | Future<void> | No | no |
| isInFullscreen | Checks if in fullscreen mode | function | / | Future<bool> | No | yes |
| getDefaultUserAgent | Gets default User-Agent | static function | / | Future<String> | No | yes |
| clearAllCache | Clears all caches | static function | bool includeDiskFiles = true | Future<void> | No | yes |
| goBackOrForward | Navigates forward/backward by step count | function | int steps | Future<void> | No | yes |
| canGoBackOrForward | Checks if can navigate by step count | function | int steps | Future<bool> | No | yes |
| goTo | Navigates to history item | function | WebHistoryItem historyItem | Future<void> | No | yes |
| isLoading | Checks if page is still loading | function | / | Future<bool> | No | yes |
| stopLoading | Stops current page load | function | / | Future<void> | No | yes |
| loadFile | Loads local file into WebView | function | String assetFilePath | Future<void> | No | yes |
| takeScreenshot | Takes screenshot of WebView | function | ScreenshotConfiguration? screenshotConfiguration | Future<Uint8List?> | No | yes |
| getOriginalUrl | Gets original requested URL | function | / | Future<WebUri?> | No | yes |
| getHtml | Gets current page HTML source | function | / | Future<String?> | No | yes |
| getFavicons | Extracts favicons from page | function | / | Future<List<Favicon>> | No | yes |
| getMetaTags | Extracts meta-tags from page | function | / | Future<List<MetaTag>> | No | yes |
| getMetaThemeColor | Extracts theme-color from page | function | / | Future<Color?> | No | yes |
| clearFocus | Clears WebView focus | function | / | Future<void> | No | yes |
| clearHistory | Clears navigation history | function | / | Future<void> | No | yes |
| clearFormData | Clears form data in page | function | / | Future<void> | No | yes |
| saveWebArchive | Saves page as web archive | function | String filePath, bool autoname = false | Future<String?> | No | yes |
| isSecureContext | Checks if page is secure context | function | / | Future<bool> | No | yes |
| createWebMessageChannel | Creates WebMessageChannel for bidirectional messaging | function | / | Future<WebMessageChannel?> | No | yes |
| postWebMessage | Posts WebMessage to page | function | WebMessage message, WebUri? targetOrigin | Future<void> | No | yes |
| addWebMessageListener | Adds WebMessageListener to page | function | WebMessageListener listener | Future<void> | No | yes |
| hasWebMessageListener | Checks if WebMessageListener is registered | function | WebMessageListener listener | bool | No | yes |
| createPdf | Creates PDF from page | function | PDFConfiguration? pdfConfiguration | Future<Uint8List?> | No | no |
| injectJavascriptFileFromUrl | Injects JS file from URL | function | WebUri urlFile, ScriptHtmlTagAttributes? scriptHtmlTagAttributes | Future<void> | No | yes |
| injectJavascriptFileFromAsset | Injects JS file from asset | function | String assetFilePath | Future<dynamic> | No | yes |
| injectCSSCode | Injects CSS code | function | String source | Future<void> | No | yes |
| injectCSSFileFromUrl | Injects CSS file from URL | function | WebUri urlFile, CSSLinkHtmlTagAttributes? cssLinkHtmlTagAttributes | Future<void> | No | yes |
| injectCSSFileFromAsset | Injects CSS file from asset | function | String assetFilePath | Future<void> | No | yes |
| addUserScript | Adds user script | function | UserScript userScript | Future<void> | No | yes |
| removeUserScript | Removes user script | function | UserScript userScript | Future<bool> | No | yes |
| removeAllUserScripts | Removes all user scripts | function | / | Future<void> | No | yes |
| callAsyncJavaScript | Calls async JavaScript | function | String functionBody, Map<String, dynamic> arguments, ContentWorld? contentWorld | Future<CallAsyncJavaScriptResult?> | No | yes |

---

### ServiceWorkerController

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| ServiceWorkerController | Gets the ServiceWorkerController instance | constructor | / | ServiceWorkerController | No | yes |
| setServiceWorkerClient | Sets ServiceWorker client settings | function | ServiceWorkerClient? client | Future<void> | No | yes |
| getServiceWorkerClient | Gets current ServiceWorker client | function | / | Future<ServiceWorkerClient?> | No | yes |

> Manages Service Worker behavior for the WebView. OHOS supports basic Service Worker control.

---

### ProcessGlobalConfig

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| apply | Applies global WebView configuration | function | ProcessGlobalConfigSettings settings | Future<void> | No | partially |

> OHOS has no ProcessGlobalConfig API; `apply()` parses parameters but returns false indicating not applied.

---

### TracingController

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| TracingController | Gets the TracingController instance | constructor | / | TracingController | No | yes |
| start | Starts tracing | function | TracingSettings settings | Future<void> | No | yes |
| stop | Stops tracing | function | / | Future<void> | No | yes |
| isTracing | Checks if tracing is active | function | / | bool | No | yes |

> Controls WebView performance tracing. OHOS supports basic tracing control.

---

### WebViewEnvironment

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| WebViewEnvironment | Creates WebView environment instance | constructor | WebViewEnvironmentSettings? settings | WebViewEnvironment | No | partially |
| getAvailableVersion | Gets available WebView version | static function | / | Future<String?> | No | no |

> OHOS ArkWeb is system-managed; WebViewEnvironment is a Dart-only fallback implementation.

---

### ContextMenu

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| ContextMenu | Creates context menu container | constructor | List<ContextMenuItem> menuItems | ContextMenu | No | yes |
| menuItems | Context menu items list | List<ContextMenuItem> | / | List<ContextMenuItem> | No | yes |
| onCreateContextMenu | Menu creation callback | function | InAppWebViewHitTestResult hitTestResult | void | No | yes |
| onHideContextMenu | Menu hide callback | function | / | void | No | yes |
| onContextMenuActionItemClicked | Menu item click callback | function | ContextMenuItem menuItem | void | No | yes |

> Context menu for WebView; OHOS supports full context menu integration.

---

### WebStorage 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| localStorage | Represents `window.localStorage` | Object | / | LocalStorage | No | yes |
| sessionStorage | Represents `window.sessionStorage` | Object | / | SessionStorage | No | yes |
| length | Returns number of stored items | function | / | Future<int?> | No | yes |
| setItem | Adds/updates a storage item | function | String key, dynamic value | Future<void> | No | yes |
| getItem | Retrieves a storage item | function | String key | Future<dynamic> | No | yes |
| removeItem | Removes a storage item | function | String key | Future<void> | No | yes |
| clear | Clears all keys from storage | function | / | Future<void> | No | yes |
| key | Gets key name at specified index | function | int index | Future<String> | No | yes |

---

### WebStorageManager 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| getOrigins | Gets storage usage for specific origins | function | / | Future<List<WebStorageOrigin>> | No | yes |
| deleteAllData | Removes all storage data | function | / | Future<void> | No | yes |
| deleteOrigin | Removes storage data for specific origin | function | String origin | Future<void> | No | yes |
| getQuotaForOrigin | Gets storage quota for specific origin | function | String origin | Future<int> | No | yes |
| getUsageForOrigin | Gets storage usage for specific origin | function | String origin | Future<int> | No | yes |
| fetchDataRecords | Gets website data records | function | Set<WebsiteDataType> dataTypes | Future<List<WebsiteDataRecord>> | No | no |
| removeDataFor | Removes specified website data records | function | Set<WebsiteDataType> dataTypes, List<WebsiteDataRecord> dataRecords | Future<void> | No | no |
| removeDataModifiedSince | Removes website data modified after specified time | function | Set<WebsiteDataType> dataTypes, DateTime date | Future<void> | No | no |

---

### PrintJobController 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| cancel | Cancels an ongoing print job | function | / | Future<void> | No | yes |
| restart | Restarts a cancelled print job | function | / | Future<void> | No | yes |
| dismiss | Closes print interface | function | bool animated = true | Future<void> | No | yes |
| getInfo | Gets print job information | function | / | Future<PrintJobInfo?> | No | yes |
| dispose | Releases resources | function | / | void | No | yes |
| id | Unique identifier for print job | String | / | String | No | yes |
| onComplete | Print completion callback | function | PrintJobCompletionHandler? | void | No | yes |

---

### FindInteractionController 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| findAll | Finds all matching items | function | String? find | Future<void> | No | yes |
| findNext | Finds next matching item | function | bool forward = true | Future<void> | No | yes |
| clearMatches | Clears all match highlights | function | / | Future<void> | No | yes |
| setSearchText | Sets search text value | function | String? searchText | Future<void> | No | yes |
| getSearchText | Gets current search text | function | / | Future<String?> | No | yes |
| isFindNavigatorVisible | Checks if find navigator visible | function | / | Future<bool?> | No | no |
| presentFindNavigator | Shows find navigator | function | / | Future<void> | No | no |
| dismissFindNavigator | Hides find navigator | function | / | Future<void> | No | no |
| onFindResultReceived | Find result callback | function | void Function(controller, int activeMatchOrdinal, int numberOfMatches, bool isDoneCounting)? | void | No | yes |

---

### ProxyController

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| setProxyOverride | Sets network proxy configuration | function | ProxySettings settings | Future<void> | No | yes |
| clearProxyOverride | Clears network proxy configuration | function | / | Future<void> | No | yes |
---

### PullToRefreshController 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| setEnabled | Enables/disables pull-to-refresh feature | function | bool enabled | Future<void> | No | yes |
| beginRefreshing | Manually starts refresh animation | function | / | Future<void> | No | yes |
| endRefreshing | Ends refresh animation | function | / | Future<void> | No | yes |
| isEnabled | Checks if refresh is enabled | function | / | Future<bool> | No | yes |
| isRefreshing | Checks if currently refreshing | function | / | Future<bool> | No | yes |
| setColor | Sets refresh indicator color | function | Color color | Future<void> | No | no |
| setBackgroundColor | Sets refresh background color | function | Color color | Future<void> | No | no |
| setDistanceToTriggerSync | Sets trigger distance for refresh | function | int distanceToTriggerSync | Future<void> | No | no |
| setSlingshotDistance | Sets elastic rebound distance (iOS-specific) | function | int slingshotDistance | Future<void> | No | no |
| setIndicatorSize | Sets indicator size (Android-specific) | function | PullToRefreshSize size | Future<void> | No | no |
| setStyledTitle | Sets refresh title (iOS-specific) | function | AttributedString attributedTitle | Future<void> | No | no |

---

### WebViewAssetLoader 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| handle | Handles resource requests at specified path | function | String path | Future<WebResourceResponse?> | No | yes |
| path | Resource path matching rules | String | / | String | No | yes |
| type | Path handler type | String | / | String | No | yes |
| AssetsPathHandler | Asset file handler | Object | String path | AssetsPathHandler | No | yes |
| ResourcesPathHandler | Resource file handler | Object | String path | ResourcesPathHandler | No | yes |
| InternalStoragePathHandler | Internal storage handler | Object | String path, String directory | InternalStoragePathHandler | No | no |
| CustomPathHandler | Custom path handler | Object | String path | CustomPathHandler | No | yes |

---

### ContentBlocker 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| ContentBlocker | Content blocking rule container | Object | ContentBlockerTrigger trigger, ContentBlockerAction action | ContentBlocker | No | yes |
| trigger | Trigger rule definition | ContentBlockerTrigger | / | ContentBlockerTrigger | No | yes |
| action | Execution action after trigger | ContentBlockerAction | / | ContentBlockerAction | No | yes |
| urlFilter | URL matching regular expression | String | String urlFilter | String | No | yes |
| urlFilterIsCaseSensitive | URL matching case sensitivity | bool | bool urlFilterIsCaseSensitive = false | bool | No | yes |
| resourceType | Resource type filter list | List<ContentBlockerTriggerResourceType> | List<ContentBlockerTriggerResourceType> resourceType = const [] | List<ContentBlockerTriggerResourceType> | No | no |
| ifDomain | Domain list for effective rules | List<String> | List<String> ifDomain = const [] | List<String> | No | yes |
| unlessDomain | Excluded domain list | List<String> | List<String> unlessDomain = const [] | List<String> | No | yes |
| loadType | Loading type filter | List<ContentBlockerTriggerLoadType> | List<ContentBlockerTriggerLoadType> loadType = const [] | List<ContentBlockerTriggerLoadType> | No | no |
| ifFrameUrl | iframe URL matching rules | List<String> | List<String> ifFrameUrl = const [] | List<String> | No | no |
| unlessTopUrl | Excluded main document URLs | List<String> | List<String> unlessTopUrl = const [] | List<String> | No | yes |
| type | Action type (block/display-none, etc.) | enum | ContentBlockerActionType type | ContentBlockerActionType | No | yes |
| selector | CSS selector (display-none only) | String | String? selector | String? | No | no |

---

### WebMessageChannel

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| WebMessageChannel | Create a Web message channel | constructor | String id, WebMessagePort port1, WebMessagePort port2 | WebMessageChannel | Yes | yes |
| id | Unique channel identifier | String | / | String | No | yes |
| port1 | Channel port 1 | WebMessagePort | / | WebMessagePort | No | yes |
| port2 | Channel port 2 | WebMessagePort | / | WebMessagePort | No | yes |
| dispose | Release channel resources | method | / | void | No | yes |

> Created via `InAppWebViewController.createWebMessageChannel()`; use with `WebMessagePort.postMessage` for two-way communication between Dart and the Web page.

---

### WebMessagePort

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| setWebMessageCallback | Registers callback for incoming messages | function | ValueCallback<void> callback | void | No | yes |
| postMessage | Sends a WebMessage to the paired port | function | WebMessage message | void | No | yes |
| close | Closes this message port | function | / | void | No | yes |

> Used as port1/port2 within a `WebMessageChannel`; messages sent on one port are received on the paired port.

---

### WebMessageListener

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| WebMessageListener | Register a JS-side message listener object | constructor | String jsObjectName, Set<String>? allowedOriginRules, OnPostMessageCallback? onPostMessage | WebMessageListener | Yes | yes |
| jsObjectName | Object name injected into the Web environment | String | / | String | Yes | yes |
| allowedOriginRules | Allowed origin rule set | Set<String> | Set<String>? allowedOriginRules | Set<String>? | No | yes |
| onPostMessage | Callback when a Web message is received | function | WebMessage message, JavaScriptReplyProxy replyProxy | void | No | yes |
| dispose | Release listener resources | method | / | void | No | yes |

> Registered via `InAppWebViewController.addWebMessageListener()`; the page sends messages to Dart through `jsObjectName.postMessage()`.

---

### InAppWebViewKeepAlive 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| InAppWebViewKeepAlive | Creates WebView keep-alive instance | constructor | / | InAppWebViewKeepAlive | No | yes |
| id | Gets/sets keep-alive instance ID | String | / | String | No | yes |
| javaScriptHandlersMap | JavaScript handler mapping table | Map<String, JavaScriptHandlerCallback> | Map<String, JavaScriptHandlerCallback> javaScriptHandlersMap | / | No | yes |
| userScripts | User script collection | Map<UserScriptInjectionTime, List<UserScript>> | Map<UserScriptInjectionTime, List<UserScript>> userScripts | / | No | yes |
| webMessageListenerObjNames | Web message listener object names | Set<String> | Set<String> webMessageListenerObjNames | / | No | yes |
| injectedScriptsFromURL | Script attributes injected via URL | Map<String, ScriptHtmlTagAttributes> | Map<String, ScriptHtmlTagAttributes> injectedScriptsFromURL | / | No | yes |
| webMessageChannels | Web message channel collection | Set<PlatformWebMessageChannel> | Set<PlatformWebMessageChannel> webMessageChannels = Set() | / | No | yes |
| webMessageListeners | Web message listener collection | Set<PlatformWebMessageListener> | Set<PlatformWebMessageListener> webMessageListeners = Set() | / | No | yes |

---

### InAppBrowser 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| openUrlRequest | Opens webpage with specified URLRequest | function | URLRequest urlRequest, InAppBrowserClassOptions? options, InAppBrowserClassSettings? settings | Future<void> | No | no |
| openFile | Opens local file | function | String assetFilePath, InAppBrowserClassOptions? options, InAppBrowserClassSettings? settings | Future<void> | No | no |
| openData | Opens HTML data | function | String data, String mimeType = "text/html", String encoding = "utf8", WebUri? baseUrl, WebUri? historyUrl, InAppBrowserClassSettings? settings | Future<void> | No | no |
| show | Shows browser window | function | / | Future<void> | No | yes |
| hide | Hides browser window | function | / | Future<void> | No | yes |
| close | Closes browser window | function | / | Future<void> | No | yes |
| setSettings | Sets browser configuration | function | InAppBrowserClassSettings settings | Future<void> | No | partially |
| getSettings | Gets current configuration | function | / | Future<InAppBrowserClassSettings?> | No | yes |
| addMenuItem | Adds menu item | function | InAppBrowserMenuItem menuItem | void | No | no |
| removeMenuItem | Removes menu item | function | InAppBrowserMenuItem menuItem | bool | No | no |
| isHidden | Checks if browser is hidden | function | / | Future<bool> | No | yes |
| isOpened | Checks if browser is open | function | / | bool | No | yes |
| onBrowserCreated | Browser creation callback | function | / | void | No | yes |
| onLoadStart | Page loading start callback | function | WebUri? url | void | No | yes |
| onLoadStop | Page loading completion callback | function | WebUri? url | void | No | yes |
| onLoadError | Loading error callback | function | WebUri? url, int code, String message | void | No | yes |
| onProgressChanged | Loading progress change callback | function | int progress | void | No | yes |
| onTitleChanged | Page title change callback | function | String? title | void | No | yes |
| onExit | Browser exit callback | function | / | void | No | no |
| onConsoleMessage | Console message callback | function | ConsoleMessage consoleMessage | void | No | yes |
| onReceivedIcon | Website icon reception callback | function | Uint8List icon | void | No | no |
| onPermissionRequest | Permission request callback | function | PermissionRequest permissionRequest | Future<PermissionResponse?> | No | yes |
| onJsAlert | JavaScript alert callback | function | JsAlertRequest jsAlertRequest | Future<JsAlertResponse?> | No | yes |
| onJsConfirm | JavaScript confirmation callback | function | JsConfirmRequest jsConfirmRequest | Future<JsConfirmResponse?> | No | yes |

---

### ChromeSafariBrowser 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| open | Opens browser with specified URL | function | WebUri? url, Map<String, String>? headers, List<WebUri>? otherLikelyURLs, ChromeSafariBrowserSettings? settings | Future<void> | No | no |
| launchUrl | Launches specified URL | function | WebUri url, Map<String, String>? headers, List<WebUri>? otherLikelyURLs | Future<void> | No | no |
| close | Closes browser | function | / | Future<void> | No | no |
| isAvailable | Checks browser availability | static function | / | Future<bool> | No | no |
| clearWebsiteData | Clears website data | static function | / | Future<void> | No | no |
| prewarmConnections | Prewarms connections | static function | List<WebUri> URLs | Future<PrewarmingToken?> | No | no |
| onClosed | Browser closure callback | function | / | void | No | no |
| onOpened | Browser open callback | function | / | void | No | no |
| onCompletedInitialLoad | Initial load completion callback | function | bool? didLoadSuccessfully | void | No | no |
| onNavigationEvent | Navigation event callback | function | CustomTabsNavigationEventType? navigationEvent | void | No | no |
| onPostMessage | postMessage callback | function | String message | void | No | no |
| setActionButton | Sets action button | function | ChromeSafariBrowserActionButton actionButton | void | No | no |
| setSecondaryToolbar | Sets secondary toolbar | function | ChromeSafariBrowserSecondaryToolbar secondaryToolbar | void | No | no |
| addMenuItem | Adds menu item | function | ChromeSafariBrowserMenuItem menuItem | void | No | no |
| requestPostMessageChannel | Requests message channel | function | WebUri sourceOrigin, WebUri? targetOrigin | Future<bool> | No | no |
| validateRelationship | Validates relationship | function | CustomTabsRelationType relation, WebUri origin | Future<bool> | No | no |

---

### InAppLocalhostServer 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| InAppLocalhostServer | Creates local server instance | constructor | int port = 8080, String directoryIndex = "index.html", String documentRoot = "./", bool shared = false | InAppLocalhostServer | No | no |
| start | Starts local server | function | / | Future<void> | No | no |
| close | Stops local server | function | / | Future<void> | No | no |
| isRunning | Checks server running status | function | / | bool | No | no |
| port | Gets server port number | int | / | int | No | no |
| directoryIndex | Gets directory index filename | String | / | String | No | no |
| documentRoot | Gets document root directory | String | / | String | No | no |
| shared | Checks if instance is shared | bool | / | bool | No | no |

---

### CookieManager 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| setCookie | Sets cookie for specified URL | function | WebUri url, String name, String value, String path = "/", String? domain, int? expiresDate, int? maxAge, bool? isSecure, bool? isHttpOnly, HTTPCookieSameSitePolicy? sameSite, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<bool> | No | yes |
| getCookies | Gets all cookies for URL | function | WebUri url, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<List<Cookie>> | No | yes |
| getCookie | Gets cookie by name | function | WebUri url, String name, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<Cookie?> | No | yes |
| deleteCookie | Deletes specified cookie | function | WebUri url, String name, String path = "/", String? domain, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<bool> | No | yes |
| deleteCookies | Deletes all cookies for URL | function | WebUri url, String path = "/", String? domain, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<bool> | No | yes |
| deleteAllCookies | Deletes all cookies | static function | / | Future<bool> | No | yes |
| getAllCookies | Gets all cookies (iOS/macOS only) | static function | / | Future<List<Cookie>> | No | no |
| removeSessionCookies | Removes session cookies | static function | / | Future<bool> | No | yes |
| IOSCookieManager | iOS-specific cookie manager class (deprecated) | Object | / | IOSCookieManager | No | no |

---

### HttpAuthCredentialDatabase 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| getAllAuthCredentials | Gets all HTTP authentication credentials | function | / | Future<List<URLProtectionSpaceHttpAuthCredentials>> | No | yes |
| getHttpAuthCredentials | Gets HTTP credentials for specified protection space | function | URLProtectionSpace protectionSpace | Future<List<URLCredential>> | No | yes |
| setHttpAuthCredential | Sets HTTP authentication credentials | function | URLProtectionSpace protectionSpace, URLCredential credential | Future<void> | No | yes |
| removeHttpAuthCredential | Removes specified HTTP authentication credentials | function | URLProtectionSpace protectionSpace, URLCredential credential | Future<void> | No | yes |
| removeHttpAuthCredentials | Removes all credentials for specified protection space | function | URLProtectionSpace protectionSpace | Future<void> | No | yes |
| clearAllAuthCredentials | Clears all authentication credentials | function | / | Future<void> | No | yes |
| dispose | Releases resources | function | / | Future<void> | No | yes |

---

### WebAuthenticationSession 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| create | Creates Web authentication session | function | WebUri url, String? callbackURLScheme, WebAuthenticationSessionCompletionHandler onComplete, WebAuthenticationSessionSettings? initialSettings | Future<WebAuthenticationSession> | No | no |
| canStart | Checks if session can be started | function | / | Future<bool> | No | no |
| start | Starts Web authentication session | function | / | Future<bool> | No | no |
| cancel | Cancels ongoing authentication session | function | / | Future<void> | No | no |
| dispose | Releases session resources | function | / | Future<void> | No | no |
| isAvailable | Checks device support for Web authentication | static function | / | Future<bool> | No | no |
| id | Gets session unique identifier | String | / | String | No | no |
| url | Gets authentication session URL | WebUri | / | WebUri | No | no |
| callbackURLScheme | Gets callback URL scheme | String | / | String? | No | no |
| initialSettings | Gets initial session configuration | WebAuthenticationSessionSettings | / | WebAuthenticationSessionSettings? | No | no |
| onComplete | Authentication completion handler | WebAuthenticationSessionCompletionHandler | / | WebAuthenticationSessionCompletionHandler | No | no |

---

### WebUri 

| Name | Description | Type | Parameter Type | Return Value | Required | OpenHarmony Support |
|------|-------------|------|----------------|--------------|----------|---------------------|
| authority | Gets URI authority part (host:port format) | String | / | String | No | yes |
| data | Gets URI data part | UriData? | / | UriData? | No | yes |
| fragment | Gets URI fragment identifier | String | / | String | No | yes |
| hasAbsolutePath | Checks if path is absolute | bool | / | bool | No | yes |
| hasAuthority | Checks existence of authority | bool | / | bool | No | yes |
| hasEmptyPath | Checks if path is empty | bool | / | bool | No | yes |
| hasFragment | Checks existence of fragment | bool | / | bool | No | yes |
| hasPort | Checks existence of port number | bool | / | bool | No | yes |
| hasQuery | Checks existence of query parameters | bool | / | bool | No | yes |
| hasScheme | Checks existence of protocol scheme | bool | / | bool | No | yes |
| host | Gets hostname (case-sensitive) | String | / | String | No | yes |
| isAbsolute | Checks if URI is absolute | bool | / | bool | No | yes |
| isScheme | Checks protocol scheme match | function | String scheme | bool | No | yes |
| normalizePath | Standardizes path (removes redundancy) | function | / | Uri | No | yes |
| origin | Gets origin (scheme+authority) | String | / | String | No | yes |
| path | Gets path (case-sensitive) | String | / | String | No | yes |
| pathSegments | Gets path segment list | List<String> | / | List<String> | No | yes |
| port | Gets port number | int | / | int | No | yes |
| query | Gets raw query string | String | / | String | No | yes |
| queryParameters | Gets query parameters map (first value only) | Map<String, String> | / | Map<String, String> | No | yes |
| queryParametersAll | Gets complete query parameters map | Map<String, List<String>> | / | Map<String, List<String>> | No | yes |
| removeFragment | Creates new URI with fragment removed | function | / | Uri | No | yes |
| replace | Replaces URI components | function | String? scheme, String? userInfo, String? host, int? port, String? path, Iterable<String>? pathSegments, String? query, Map<String, dynamic>? queryParameters, String? fragment | Uri | No | yes |
| resolve | Resolves relative URI | function | String reference | Uri | No | yes |
| resolveUri | Resolves relative URI object | function | Uri reference | Uri | No | yes |
| scheme | Gets protocol scheme (e.g., http) | String | / | String | No | yes |
| toFilePath | Converts to file path | function | bool? windows | String | No | yes |
| userInfo | Gets user info component | String | / | String | No | yes |
| rawValue | Gets raw unparsed URI string | String | / | String | No | yes |
| uriValue | Gets parsed standard URI object | Uri | / | Uri | No | yes |
| isValidUri | Indicates if URI parsing succeeded | bool | / | bool | No | yes |
| forceToStringRawValue | Controls toString() to use raw value | bool | / | bool | No | yes |
| normalizePath() | Returns new standardized path URI | function | / | Uri | No | yes |
| toString() | String representation (configurable to use raw value) | function | / | String | No | yes |

---

## Known Issues

None

## Directory Structure

```text
flutter_inappwebview/                  # Main package, unified API export
flutter_inappwebview_ohos/             # OpenHarmony platform implementation (ArkTS)
flutter_inappwebview_platform_interface/  # Cross-platform interface definitions
flutter_inappwebview_android/          # Android platform implementation
flutter_inappwebview_ios/              # iOS platform implementation
flutter_inappwebview_macos/            # macOS platform implementation
flutter_inappwebview_web/              # Web platform implementation
flutter_inappwebview_windows/          # Windows platform implementation
dev_packages/                          # Internal development packages
```

## Contributing

If you find any issues during use, feel free to submit an [Issue](https://gitcode.com/CPF-Flutter/flutter_inappwebview/issues). Contributions via [PR](https://gitcode.com/CPF-Flutter/flutter_inappwebview/pulls) are also very welcome.

## License

This project is licensed under [Apache-2.0](https://github.com/pichillilorenzo/flutter_inappwebview/blob/master/LICENSE).
