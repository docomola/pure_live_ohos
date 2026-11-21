<p align="center">
  <h1 align="center"><code>flutter_inappwebview</code></h1>
</p>

本项目基于 [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) 开发。

## 简介

flutter_inappwebview 是一个 Flutter 插件，支持在应用内嵌入 WebView、使用无头 WebView，以及打开应用内浏览器窗口。本仓库为 OpenHarmony 平台适配版本，基于上游 [flutter_inappwebview](https://github.com/pichillilorenzo/flutter_inappwebview) 源码进行鸿蒙化改造，适配 Flutter **3.22**、**3.27**、**3.35** 框架版本。

## 下载安装

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

```yaml
dependencies:
  flutter_inappwebview:
    git:
      url: https://gitcode.com/CPF-Flutter/flutter_inappwebview.git
      path: flutter_inappwebview
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: 6.1.5-ohos-1.0.1
```

执行命令

```bash
flutter pub get
```

> TAG 命名规则：`原库版本-ohos-版本号`，不同 TAG 之间的变更详见 [CHANGELOG.OpenHarmony.md](./CHANGELOG.OpenHarmony.md)。

| Flutter 框架版本 | TAG 名称 | 分支名 | DevEco Studio | SDK | ROM |
|---|---|---|---|---|---|
| 3.22 | 6.1.5-ohos-1.0.1 | br_v6.1.5_ohos | 5.0.0 release(5.0.13.200) | 5.0.0(12) | 5.1.0.120 SP3 |
| 3.27 | 6.1.5-ohos-1.0.1 | br_v6.1.5_ohos | 5.1.0 release(5.1.0.828) | 5.0.0(12) | 5.1.0.130 SP8 |
| 3.35 | 6.1.5-ohos-1.0.1 | br_v6.1.5_ohos | 5.1.0 release(5.1.0.828) | 5.0.0(12) | 5.1.0.130 SP8 |

## 约束与限制

### OpenHarmony 环境配置

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（与 Flutter SDK 版本匹配）。
2. 打开 **Settings → OpenHarmony SDK**，安装 SDK 及对应工具链（与 Flutter SDK 版本匹配）。
3. 安装 Flutter OpenHarmony SDK，执行 `flutter doctor` 确认 HarmonyOS toolchain 可用。
4. 连接 OpenHarmony 真机或启动模拟器，执行 `flutter devices` 确认设备可见。
5. 在应用 `ohos/entry/src/main/module.json5` 中配置权限（见下文「权限要求」），再执行 `flutter run` 或 `flutter build hap`。

### 兼容性

在以下版本中已测试通过

1. Flutter: 3.22.0-ohos-1.0.0, DevEco Studio: 5.0.0 release(5.0.13.200), SDK: 5.0.0(12), ROM: 5.1.0.120 SP3;
2. Flutter: 3.27.5-ohos-0.0.1, DevEco Studio: 5.1.0 release(5.1.0.828), SDK: 5.0.0(12), ROM: 5.1.0.130 SP8;
3. Flutter: 3.35.0-ohos-0.0.1, DevEco Studio: 5.1.0 release(5.1.0.828), SDK: 5.0.0(12), ROM: 5.1.0.130 SP8;

> 以下功能依赖特定版本的 API，使用低于指定 API 版本的工程编译，或低于指定 API 版本的 ROM 运行，均可能导致部分功能受限。

1. 引入 [removeAllCache](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-webview-webviewcontroller#removeallcache18)，实现了 `clearAllCache` 接口清除所有缓存功能。此 API 需要在支持 API 18+ 的工程编译，并在支持 API 18+ 的 ROM 上运行，方可生效。

### 渲染约束

> [!IMPORTANT]
> OHOS 端 `InAppWebView` 通过 PlatformView 接入 Flutter，Web 组件经纹理合成路径渲染为 surface 节点。该 surface 节点的物理像素高度存在上限，超出将出现静默白屏（无报错、无日志）。

完整的现象、根因分析与解决方案见 [InAppWebView 内容高度过大导致白屏说明](docs/zh_cn/WebView白屏问题说明.md)。

### 软键盘避让模式

原生 Web 组件默认使用 `WebKeyboardAvoidMode.RESIZE_VISUAL`，软键盘弹起时仅调整可视视口。

### 版本升级迁移

> 跨 Flutter 主版本升级时，请确认 `pubspec.yaml` 中的 `ref` TAG，并重新执行 `flutter pub get`。

1. **3.22 / 3.27 / 3.35 之间切换框架**：无需更换 TAG（均使用 `6.1.5-ohos-1.0.0`），按上表切换匹配的 DevEco Studio / SDK / ROM 即可；若使用 `WebStorageManager.clearAllCache`，需 API 18+ 编译与运行环境。
2. 升级后建议执行 `flutter clean`，并重新构建 OHOS 工程（`flutter build hap`）。

### 权限要求

WebView 加载网络页面需要 `ohos.permission.INTERNET` 权限。若页面涉及打印、摄像头或麦克风能力，还需声明对应权限。

在 `entry/src/main/module.json5` 中添加：

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

在 `entry/src/main/resources/base/element/string.json` 中添加：

```json5
{
  "string": [
    {
      "name": "camera_permission_reason",
      "value": "用于 Web 页面申请摄像头权限"
    },
    {
      "name": "microphone_permission_reason",
      "value": "用于 Web 页面申请麦克风权限"
    }
  ]
}
```

## 使用示例

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
    // OpenHarmony：运行前须在 entry/src/main/module.json5 中声明
    // ohos.permission.INTERNET 等权限，详见上文「权限要求」章节。
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

## 使用说明

### 1. 内嵌 WebView（InAppWebView）

`InAppWebView` 是最常用的组件，可在 Flutter 页面中嵌入 Web 内容。通过 `initialUrlRequest` 指定初始 URL，通过 `onWebViewCreated` 获取 `InAppWebViewController` 以执行加载、刷新、JavaScript 调用等操作。

### 2. JavaScript 双向通信

通过 `addJavaScriptHandler` 注册 Dart 侧处理器，页面内使用 `window.flutter_inappwebview.callHandler` 调用；通过 `evaluateJavascript` 从 Dart 侧执行 JavaScript 并获取返回值。

### 3. 应用内浏览器（InAppBrowser）

`InAppBrowser` 提供独立浏览器窗口，支持 `show`、`hide`、`close` 等生命周期控制。OpenHarmony 平台暂不支持 `openUrlRequest`、`openFile`、`openData` 等静态打开方法。

### 4. Cookie 与 Web 存储

`CookieManager` 提供 Cookie 的增删改查；`WebStorage` 与 `WebStorageManager` 分别对应页面级 `localStorage`/`sessionStorage` 和全局 Web 存储管理。

### 5. 下拉刷新与内容拦截

`PullToRefreshController` 配合 `InAppWebView` 实现下拉刷新；`ContentBlocker` 支持基于 URL 规则拦截页面资源加载。

### 6. 本地资源加载

`WebViewAssetLoader` 支持从 assets 或应用资源目录加载本地 HTML/CSS/JS 文件，适用于离线页面场景。

### 7. 运行示例工程

完整示例位于 [flutter_inappwebview/example](./flutter_inappwebview/example)。在 OpenHarmony 设备或模拟器上，进入 `flutter_inappwebview/example` 目录，确认 `ohos/entry/src/main/module.json5` 已配置网络等权限后，执行 `flutter run` 即可运行。

> 更多 API 说明与用法请参考 [inappwebview.dev 官方文档](https://inappwebview.dev/docs/intro)。

## 接口说明

> OpenHarmony 平台支持列中「是」表示该平台支持该接口，「否」表示不支持，「部分」表示部分支持。使用方法在各平台保持一致。

### InAppWebView 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| key | Flutter框架基础标识符 | Key | / | Key | 否 | 是 |
| controllerFromPlatform | 从平台获取WebView控制器的回调 | function | PlatformInAppWebViewController controller | void | 否 | 是 |
| windowId | 窗口ID标识符 | int | / | int | 否 | 否 |
| initialUrlRequest | 要加载的初始URLRequest | WebUri | / | WebUri | 否 | 是 |
| initialFile | 要加载的初始本地文件路径 | String | / | String | 否 | 是 |
| initialData | 要加载的初始HTML数据 | InAppWebViewInitialData | / | InAppWebViewInitialData | 否 | 是 |
| onWebViewCreated | WebView创建事件回调 | function | InAppWebViewController controller | void | 否 | 是 |
| onLoadStart | URL加载开始事件回调 | function | InAppWebViewController controller, WebUri? url | void | 否 | 是 |
| onLoadStop | URL加载完成事件回调 | function | InAppWebViewController controller, WebUri? url | void | 否 | 是 |
| onReceivedError | 加载错误接收回调 | function | InAppWebViewController controller, WebUri? url, WebResourceError error | void | 否 | 是 |
| onReceivedHttpError | HTTP错误接收回调 | function | InAppWebViewController controller, WebUri? url, WebResourceResponse response | void | 否 | 是 |
| shouldOverrideUrlLoading | URL加载拦截回调 | function | InAppWebViewController controller, NavigationAction navigationAction | Future<NavigationActionPolicy?> | 否 | 是 |
| onConsoleMessage | 控制台消息回调 | function | InAppWebViewController controller, ConsoleMessage consoleMessage | void | 否 | 是 |
| onProgressChanged | 加载进度变化回调 | function | InAppWebViewController controller, int progress | void | 否 | 是 |
| onPermissionRequest | 权限请求回调（摄像头/定位等） | function | InAppWebViewController controller, PermissionRequest permissionRequest | void | 否 | 是 |
| onSafeBrowsingHit | 安全浏览拦截回调 | function | InAppWebViewController controller, WebUri? url, SafeBrowsingThreatType threatType | void | 否 | 否 |
| onZoomScaleChanged | 缩放比例变化回调 | function | InAppWebViewController controller, double scale | void | 否 | 是 |
| gestureRecognizers | 手势识别器集合 | Set<Factory<OneSequenceGestureRecognizer>> | / | Set<Factory<OneSequenceGestureRecognizer>> | 否 | 是 |
| keepAlive | 是否保持WebView存活 | InAppWebViewKeepAlive | / | InAppWebViewKeepAlive | 否 | 否 |
| onJsAlert | JavaScript警报对话框回调 | function | InAppWebViewController controller, JsAlertRequest jsAlertRequest | void | 否 | 是 |
| onJsConfirm | JavaScript确认对话框回调 | function | InAppWebViewController controller, JsConfirmRequest jsConfirmRequest | void | 否 | 是 |
| onJsPrompt | JavaScript提示对话框回调 | function | InAppWebViewController controller, JsPromptRequest jsPromptRequest | void | 否 | 是 |
| onLoadResource | 资源加载完成回调 | function | InAppWebViewController controller, WebResourceResponse response | void | 否 | 否 |
| onDownloadStartRequest | 文件下载开始回调 | function | InAppWebViewController controller, DownloadStartRequest request | void | 否 | 否 |
| onCreateWindow | 窗口创建请求回调 | function | InAppWebViewController controller, CreateWindowRequest request | void | 否 | 否 |
| onCloseWindow | 窗口关闭请求回调 | function | InAppWebViewController controller | void | 否 | 否 |
| onFormResubmission | 表单重新提交请求 | function | InAppWebViewController controller, FormResubmissionAction action | void | 否 | 否 |
| onNavigationResponse | 导航响应处理 | function | InAppWebViewController controller, NavigationResponseAction action | void | 否 | 否 |
| onContentSizeChanged | 内容大小变化回调 | function | InAppWebViewController controller, Size contentSize | void | 否 | 否 |
| onOverScrolled | 超出滚动边界回调 | function | InAppWebViewController controller, int scrollX, bool clampedX, int scrollY, bool clampedY | void | 否 | 是 |
| onEnterFullscreen | 进入全屏模式回调 | function | InAppWebViewController controller | void | 否 | 否 |
| onExitFullscreen | 退出全屏模式回调 | function | InAppWebViewController controller | void | 否 | 否 |
| onPrintRequest | 打印请求回调 | function | InAppWebViewController controller | void | 否 | 否 |
| onGeolocationPermissionsShowPrompt | 地理位置权限请求 | function | InAppWebViewController controller, String origin, bool allow | void | 否 | 是 |
| shouldInterceptRequest | 请求拦截 | function | InAppWebViewController controller, WebResourceRequest request | Future<WebResourceResponse?> | 否 | 是 |
| shouldInterceptAjaxRequest | AJAX请求拦截 | function | InAppWebViewController controller, AjaxRequest request | Future<AjaxRequestPolicy?> | 否 | 是 |
| onRenderProcessGone | 渲染进程崩溃回调 | function | InAppWebViewController controller, RenderProcessGoneDetail detail | void | 否 | 否 |
| onRenderProcessResponsive | 渲染进程恢复回调 | function | InAppWebViewController controller | void | 否 | 否 |
| ohosParams | OHOS特定配置参数 | OhosInAppWebViewWidgetCreationParams | / | OhosInAppWebViewWidgetCreationParams | 否 | 是 |
| useHybridComposition | 是否使用混合渲染模式 | bool | / | bool | 否 | 是 |

---

### InAppWebViewSettings 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| javaScriptEnabled | 是否启用JavaScript执行 | bool | bool | void | 否 | 是 |
| mediaPlaybackRequiresUserGesture | 媒体播放是否需要用户手势 | bool | bool | void | 否 | 是 |
| domStorageEnabled | 是否启用DOM存储（localStorage/sessionStorage） | bool | bool | void | 否 | 是 |
| userAgent | 自定义User-Agent字符串 | String | String | void | 否 | 是 |
| applicationNameForUserAgent | 附加到User-Agent的应用名称 | String | String | void | 否 | 是 |
| javaScriptCanOpenWindowsAutomatically | JavaScript是否可以自动打开新窗口 | bool | bool | void | 否 | 否 |
| useShouldOverrideUrlLoading | 是否通过shouldOverrideUrlLoading拦截URL加载 | bool | bool | void | 否 | 是 |
| useOnLoadResource | 是否监控资源加载事件 | bool | bool | void | 否 | 是 |
| useOnDownloadStart | 是否处理下载开始事件 | bool | bool | void | 否 | 是 |
| clearCache | 加载前是否清除缓存 | bool | bool | void | 否 | 否 |
| verticalScrollBarEnabled | 是否启用垂直滚动条 | bool | bool | void | 否 | 是 |
| horizontalScrollBarEnabled | 是否启用水平滚动条 | bool | bool | void | 否 | 是 |
| supportZoom | 是否支持缩放控制 | bool | bool | void | 否 | 否 |
| allowFileAccess | 是否允许文件访问 | bool | bool | void | 否 | 是 |
| allowFileAccessFromFileURLs | 是否允许从file:// URL访问文件 | bool | bool | void | 否 | 否 |
| allowUniversalAccessFromFileURLs | 是否允许从file:// URL进行通用访问 | bool | bool | void | 否 | 否 |
| blockNetworkImage | 是否阻止网络图片加载 | bool | bool | void | 否 | 否 |
| blockNetworkLoads | 是否阻止所有网络请求 | bool | bool | void | 否 | 否 |
| contentBlockers | 应用于WebView的内容阻止规则列表 | List<ContentBlocker> | List<ContentBlocker>? | void | 否 | 是 |
| preferredContentMode | 首选内容渲染模式（例如desktop，mobile） | enum | ContentMode | void | 否 | 否 |
| minimumFontSize | 显示网页内容的最小字体大小 | int | int | void | 否 | 否 |
| minimumLogicalFontSize | 网页内容的最小逻辑字体大小 | int | int | void | 否 | 否 |
| layoutAlgorithm | HTML渲染使用的布局算法 | enum | LayoutAlgorithm | void | 否 | 否 |
| mixedContentMode | 控制混合HTTP/HTTPS内容的加载策略 | enum | MixedContentMode | void | 否 | 是 |
| geolocationEnabled | 是否启用地理位置权限 | bool | bool | void | 否 | 是 |
| databaseEnabled | 是否启用数据库存储 | bool | bool | void | 否 | 否 |
| appCacheEnabled | 是否启用应用程序缓存 | bool | bool | void | 否 | 否 |
| appCachePath | 存储应用程序缓存数据的路径 | String | String | void | 否 | 否 |
| textZoom | 页面文本缩放比例（默认100） | int | int | void | 否 | 是 |
| enableNativeEmbedMode | 启用WebView的原生嵌入模式 | bool | bool | void | 否 | 是 |
| onlineImageAccess | 控制是否可以访问在线图像资源 | bool | bool | void | 否 | 否 |
| blockNetwork | 是否阻止所有网络请求 | bool | bool | void | 否 | 否 |
| darkMode | 设置WebView的暗色模式行为 | enum | WebDarkMode | void | 否 | 是 |
| fileAccess | 是否启用文件访问权限 | bool | bool | void | 否 | 是 |
| domStorageAccess | 是否启用DOM存储访问 | bool | bool | void | 否 | 是 |
| multiWindowAccess | 是否允许多窗口访问 | bool | bool | void | 否 | 是 |
| initialScale | WebView的初始缩放比例（0表示默认） | int | int | void | 否 | 是 |
| needInitialFocus | WebView是否需要初始焦点 | bool | bool | void | 否 | 否 |
| forceDark | 强制WebView内容使用暗色主题 | enum | WebDarkMode | void | 否 | 是 |
| hardwareAcceleration | 是否启用硬件加速 | bool | bool | void | 否 | 否 |
| supportMultipleWindows | 是否支持多个窗口 | bool | bool | void | 否 | 是 |

---

### HeadlessInAppWebView 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| run | 以无头模式运行WebView | function | / | Future<void> | 否 | 否 |
| getSize | 获取无头WebView的尺寸 | function | / | Future<Size?> | 否 | 否 |
| setSize | 设置无头WebView的尺寸 | function | Size size | Future<void> | 否 | 否 |
| dispose | 处置无头WebView | function | / | Future<void> | 否 | 否 |
| initialSize | 初始尺寸设置 | Size | Size | Size | 否 | 否 |
| initialUrlRequest | 要加载的初始URLRequest | WebUri | URLRequest? | URLRequest? | 否 | 是 |
| initialFile | 要加载的初始本地文件路径 | String | String? | String? | 否 | 是 |
| initialData | 要加载的初始HTML数据 | InAppWebViewInitialData | InAppWebViewInitialData? | InAppWebViewInitialData? | 否 | 是 |
| onWebViewCreated | WebView创建事件回调 | function | InAppWebViewController controller | void | 否 | 是 |
| onLoadStart | URL加载开始事件回调 | function | InAppWebViewController controller, WebUri? url | void | 否 | 是 |
| onLoadStop | URL加载完成事件回调 | function | InAppWebViewController controller, WebUri? url | void | 否 | 是 |
| onReceivedError | 加载错误接收回调 | function | InAppWebViewController controller, WebUri? url, WebResourceError error | void | 否 | 是 |
| onConsoleMessage | 控制台消息回调 | function | InAppWebViewController controller, ConsoleMessage consoleMessage | void | 否 | 是 |
| shouldOverrideUrlLoading | URL加载拦截回调 | function | InAppWebViewController controller, NavigationAction navigationAction | Future<NavigationActionPolicy?> | 否 | 是 |
| onJsAlert | JavaScript警报对话框回调 | function | InAppWebViewController controller, JsAlertRequest jsAlertRequest | void | 否 | 是 |
| onJsConfirm | JavaScript确认对话框回调 | function | InAppWebViewController controller, JsConfirmRequest jsConfirmRequest | void | 否 | 是 |
| onPermissionRequest | 权限请求回调（摄像头/定位等） | function | InAppWebViewController controller, PermissionRequest permissionRequest | void | 否 | 是 |
| onDownloadStartRequest | 文件下载开始回调 | function | InAppWebViewController controller, DownloadStartRequest request | void | 否 | 否 |
| onContentSizeChanged | 内容大小变化回调 | function | InAppWebViewController controller, Size contentSize | void | 否 | 否 |
| onRenderProcessGone | 渲染进程崩溃回调 | function | InAppWebViewController controller, RenderProcessGoneDetail detail | void | 否 | 否 |

---

### InAppWebViewController 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| getUrl | 获取当前页面的URL | function | / | Future<WebUri?> | 否 | 是 |
| getTitle | 获取当前页面的标题 | function | / | Future<String?> | 否 | 是 |
| getProgress | 获取当前页面的加载进度（0-100） | function | / | Future<int?> | 否 | 是 |
| loadUrl | 在WebView中加载指定的URL | function | URLRequest urlRequest, WebUri? allowingReadAccessTo | Future<void> | 否 | 是 |
| reload | 重新加载WebView | function | / | Future<void> | 否 | 是 |
| goBack | 在WebView的历史记录中向后导航 | function | / | Future<void> | 否 | 部分 |
| setSettings | 使用新设置配置WebView | function | InAppWebViewSettings settings | Future<void> | 否 | 部分 |
| getSettings | 获取当前的WebView配置 | function | / | Future<InAppWebViewSettings?> | 否 | 是 |
| evaluateJavascript | 执行JavaScript表达式并返回结果 | function | String source, ContentWorld? contentWorld | Future<dynamic> | 否 | 是 |
| loadData | 将HTML数据加载到WebView中 | function | String data, String mimeType = "text/html", String encoding = "utf8", WebUri? baseUrl, WebUri? historyUrl, WebUri? allowingReadAccessTo | Future<void> | 否 | 是 |
| postUrl | 使用POST请求加载指定的URL | function | WebUri url, Uint8List postData | Future<void> | 否 | 是 |
| getOriginalUrl | 获取当前页面的原始请求URL | function | / | Future<WebUri?> | 否 | 是 |
| getScrollX | 获取水平滚动位置 | function | / | Future<int?> | 否 | 是 |
| getScrollY | 获取垂直滚动位置 | function | / | Future<int?> | 否 | 是 |
| scrollTo | 滚动到指定坐标 | function | int x, int y, bool animated = false | Future<void> | 否 | 是 |
| scrollBy | 按指定的增量值滚动 | function | int x, int y, bool animated = false | Future<void> | 否 | 是 |
| canGoBack | 检查是否可以向后导航 | function | / | Future<bool> | 否 | 是 |
| canGoForward | 检查是否可以向前导航 | function | / | Future<bool> | 否 | 是 |
| goForward | 在WebView历史记录中向前导航 | function | / | Future<void> | 否 | 否 |
| pauseTimers | 暂停WebView中的所有定时器 | function | / | Future<void> | 否 | 是 |
| resumeTimers | 恢复WebView中的所有定时器 | function | / | Future<void> | 否 | 是 |
| clearCache | 清除缓存 | function | / | Future<void> | 否 | 否 |
| zoomBy | 按指定比例缩放 | function | double zoomFactor, bool animated = false | Future<void> | 否 | 是 |
| getZoomScale | 获取当前缩放比例 | function | / | Future<double?> | 否 | 是 |
| getCertificate | 获取SSL证书信息 | function | / | Future<SslCertificate?> | 否 | 是 |
| createPdf | 创建PDF文档 | function | PDFConfiguration? pdfConfiguration | Future<Uint8List?> | 否 | 否 |
| printCurrentPage | 打印当前页面 | function | PrintJobSettings? settings | Future<PrintJobController?> | 否 | 是 |
| addJavaScriptHandler | 添加JavaScript消息处理程序 | function | String handlerName, JavaScriptHandlerCallback callback | void | 否 | 是 |
| removeJavaScriptHandler | 移除JavaScript消息处理程序 | function | String handlerName | JavaScriptHandlerCallback? | 否 | 是 |
| hasJavaScriptHandler | 检查指定的处理程序是否存在 | function | String handlerName | bool | 否 | 是 |
| canScrollVertically | 检查是否可以垂直滚动 | function | / | Future<bool> | 否 | 是 |
| canScrollHorizontally | 检查是否可以水平滚动 | function | / | Future<bool> | 否 | 是 |
| getHitTestResult | 获取触摸的HTML元素的命中测试结果 | function | / | Future<InAppWebViewHitTestResult?> | 否 | 是 |
| getSelectedText | 获取WebView中的选定文本 | function | / | Future<String?> | 否 | 是 |
| getContentHeight | 获取页面内容高度 | function | / | Future<int?> | 否 | 是 |
| getContentWidth | 获取页面内容宽度 | function | / | Future<int?> | 否 | 是 |
| pause | 暂停WebView | function | / | Future<void> | 否 | 是 |
| resume | 恢复WebView | function | / | Future<void> | 否 | 是 |
| pageDown | 向下滚动页面 | function | bool bottom | Future<bool> | 否 | 是 |
| pageUp | 向上滚动页面 | function | bool top | Future<bool> | 否 | 是 |
| setAllMediaPlaybackSuspended | 设置媒体播放状态 | function | bool suspended | Future<void> | 否 | 否 |
| isInFullscreen | 检查是否处于全屏模式 | function | / | Future<bool> | 否 | 是 |
| getDefaultUserAgent | 获取默认的User-Agent | static function | / | Future<String> | 否 | 是 |
| clearAllCache | 清除所有缓存 | static function | bool includeDiskFiles = true | Future<void> | 否 | 是 |
| goBackOrForward | 按步数前进/后退导航 | function | int steps | Future<void> | 否 | 是 |
| canGoBackOrForward | 检查是否可按步数导航 | function | int steps | Future<bool> | 否 | 是 |
| goTo | 导航到指定历史项 | function | WebHistoryItem historyItem | Future<void> | 否 | 是 |
| isLoading | 检查页面是否正在加载 | function | / | Future<bool> | 否 | 是 |
| stopLoading | 停止当前页面加载 | function | / | Future<void> | 否 | 是 |
| loadFile | 将本地文件加载到WebView中 | function | String assetFilePath | Future<void> | 否 | 是 |
| takeScreenshot | 对WebView进行截图 | function | ScreenshotConfiguration? screenshotConfiguration | Future<Uint8List?> | 否 | 是 |
| getOriginalUrl | 获取原始请求URL | function | / | Future<WebUri?> | 否 | 是 |
| getHtml | 获取当前页面HTML源码 | function | / | Future<String?> | 否 | 是 |
| getFavicons | 从页面提取favicon图标 | function | / | Future<List<Favicon>> | 否 | 是 |
| getMetaTags | 从页面提取meta标签 | function | / | Future<List<MetaTag>> | 否 | 是 |
| getMetaThemeColor | 从页面提取主题颜色 | function | / | Future<Color?> | 否 | 是 |
| clearFocus | 清除WebView焦点 | function | / | Future<void> | 否 | 是 |
| clearHistory | 清除导航历史记录 | function | / | Future<void> | 否 | 是 |
| clearFormData | 清除页面中的表单数据 | function | / | Future<void> | 否 | 是 |
| saveWebArchive | 将页面保存为Web归档 | function | String filePath, bool autoname = false | Future<String?> | 否 | 是 |
| isSecureContext | 检查页面是否为安全上下文 | function | / | Future<bool> | 否 | 是 |
| createWebMessageChannel | 创建用于双向消息的WebMessageChannel | function | / | Future<WebMessageChannel?> | 否 | 是 |
| postWebMessage | 向页面发送WebMessage | function | WebMessage message, WebUri? targetOrigin | Future<void> | 否 | 是 |
| addWebMessageListener | 向页面添加WebMessageListener | function | WebMessageListener listener | Future<void> | 否 | 是 |
| hasWebMessageListener | 检查WebMessageListener是否已注册 | function | WebMessageListener listener | bool | 否 | 是 |
| createPdf | 从页面创建PDF | function | PDFConfiguration? pdfConfiguration | Future<Uint8List?> | 否 | 否 |
| injectJavascriptFileFromUrl | 从URL注入JS文件 | function | WebUri urlFile, ScriptHtmlTagAttributes? scriptHtmlTagAttributes | Future<void> | 否 | 是 |
| injectJavascriptFileFromAsset | 从资源注入JS文件 | function | String assetFilePath | Future<dynamic> | 否 | 是 |
| injectCSSCode | 注入CSS代码 | function | String source | Future<void> | 否 | 是 |
| injectCSSFileFromUrl | 从URL注入CSS文件 | function | WebUri urlFile, CSSLinkHtmlTagAttributes? cssLinkHtmlTagAttributes | Future<void> | 否 | 是 |
| injectCSSFileFromAsset | 从资源注入CSS文件 | function | String assetFilePath | Future<void> | 否 | 是 |
| addUserScript | 添加用户脚本 | function | UserScript userScript | Future<void> | 否 | 是 |
| removeUserScript | 移除用户脚本 | function | UserScript userScript | Future<bool> | 否 | 是 |
| removeAllUserScripts | 移除所有用户脚本 | function | / | Future<void> | 否 | 是 |
| callAsyncJavaScript | 调用异步JavaScript | function | String functionBody, Map<String, dynamic> arguments, ContentWorld? contentWorld | Future<CallAsyncJavaScriptResult?> | 否 | 是 |

---

### ServiceWorkerController

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| ServiceWorkerController | 获取 ServiceWorkerController 实例 | 构造函数 | / | ServiceWorkerController | 否 | 是 |
| setServiceWorkerClient | 设置 ServiceWorker 客户端设置 | function | ServiceWorkerClient? client | Future<void> | 否 | 是 |
| getServiceWorkerClient | 获取当前 ServiceWorker 客户端 | function | / | Future<ServiceWorkerClient?> | 否 | 是 |

> 管理 WebView 的 Service Worker 行为。OHOS 支持基本的 Service Worker 控制。

---

### ProcessGlobalConfig

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| apply | 应用全局 WebView 配置 | function | ProcessGlobalConfigSettings settings | Future<void> | 否 | 部分 |

> OHOS 无 ProcessGlobalConfig API；`apply()` 解析参数但返回 false 表示未应用。

---

### TracingController

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| TracingController | 获取 TracingController 实例 | 构造函数 | / | TracingController | 否 | 是 |
| start | 开始跟踪 | function | TracingSettings settings | Future<void> | 否 | 是 |
| stop | 停止跟踪 | function | / | Future<void> | 否 | 是 |
| isTracing | 检查是否正在跟踪 | function | / | bool | 否 | 是 |

> 控制 WebView 性能跟踪。OHOS 支持基本的跟踪控制。

---

### WebViewEnvironment

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| WebViewEnvironment | 创建 WebView 环境实例 | 构造函数 | WebViewEnvironmentSettings? settings | WebViewEnvironment | 否 | 部分 |
| getAvailableVersion | 获取可用的 WebView 版本 | static function | / | Future<String?> | 否 | 否 |

> OHOS ArkWeb 为系统管理；WebViewEnvironment 为 Dart-only 降级实现。

---

### ContextMenu

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| ContextMenu | 创建上下文菜单容器 | 构造函数 | List<ContextMenuItem> menuItems | ContextMenu | 否 | 是 |
| menuItems | 上下文菜单项列表 | List<ContextMenuItem> | / | List<ContextMenuItem> | 否 | 是 |
| onCreateContextMenu | 菜单创建回调 | function | InAppWebViewHitTestResult hitTestResult | void | 否 | 是 |
| onHideContextMenu | 菜单隐藏回调 | function | / | void | 否 | 是 |
| onContextMenuActionItemClicked | 菜单项点击回调 | function | ContextMenuItem menuItem | void | 否 | 是 |

> WebView 上下文菜单；OHOS 支持完整的上下文菜单集成。

---

### WebStorage 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| localStorage | 表示 `window.localStorage` | Object | / | LocalStorage | 否 | 是 |
| sessionStorage | 表示 `window.sessionStorage` | Object | / | SessionStorage | 否 | 是 |
| length | 返回存储项的数量 | function | / | Future<int?> | 否 | 是 |
| setItem | 添加/更新一个存储项 | function | String key, dynamic value | Future<void> | 否 | 是 |
| getItem | 获取一个存储项 | function | String key | Future<dynamic> | 否 | 是 |
| removeItem | 移除一个存储项 | function | String key | Future<void> | 否 | 是 |
| clear | 清除所有存储项 | function | / | Future<void> | 否 | 是 |
| key | 获取指定索引处的键名 | function | int index | Future<String> | 否 | 是 |

---

### WebStorageManager 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| getOrigins | 获取特定来源的存储使用情况 | function | / | Future<List<WebStorageOrigin>> | 否 | 是 |
| deleteAllData | 删除所有存储数据 | function | / | Future<void> | 否 | 是 |
| deleteOrigin | 删除特定来源的存储数据 | function | String origin | Future<void> | 否 | 是 |
| getQuotaForOrigin | 获取特定来源的存储配额 | function | String origin | Future<int> | 否 | 是 |
| getUsageForOrigin | 获取特定来源的存储使用量 | function | String origin | Future<int> | 否 | 是 |
| fetchDataRecords | 获取网站数据记录 | function | Set<WebsiteDataType> dataTypes | Future<List<WebsiteDataRecord>> | 否 | 否 |
| removeDataFor | 删除指定的网站数据记录 | function | Set<WebsiteDataType> dataTypes, List<WebsiteDataRecord> dataRecords | Future<void> | 否 | 否 |
| removeDataModifiedSince | 删除在指定时间后修改的数据记录 | function | Set<WebsiteDataType> dataTypes, DateTime date | Future<void> | 否 | 否 |

---

### PrintJobController 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| cancel | 取消正在进行的打印任务 | function | / | Future<void> | 否 | 是 |
| restart | 重启已取消的打印任务 | function | / | Future<void> | 否 | 是 |
| dismiss | 关闭打印界面 | function | bool animated = true | Future<void> | 否 | 是 |
| getInfo | 获取打印任务信息 | function | / | Future<PrintJobInfo?> | 否 | 是 |
| dispose | 释放资源 | function | / | void | 否 | 是 |
| id | 打印任务的唯一标识符 | String | / | String | 否 | 是 |
| onComplete | 打印完成回调 | function | PrintJobCompletionHandler? | void | 否 | 是 |

---

### FindInteractionController 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| findAll | 查找所有匹配项 | function | String? find | Future<void> | 否 | 是 |
| findNext | 查找下一个匹配项 | function | bool forward = true | Future<void> | 否 | 是 |
| clearMatches | 清除所有匹配高亮 | function | / | Future<void> | 否 | 是 |
| setSearchText | 设置搜索文本值 | function | String? searchText | Future<void> | 否 | 是 |
| getSearchText | 获取当前搜索文本 | function | / | Future<String?> | 否 | 是 |
| isFindNavigatorVisible | 检查查找导航器是否可见 | function | / | Future<bool?> | 否 | 否 |
| presentFindNavigator | 显示查找导航器 | function | / | Future<void> | 否 | 否 |
| dismissFindNavigator | 隐藏查找导航器 | function | / | Future<void> | 否 | 否 |
| onFindResultReceived | 查找结果回调 | function | void Function(controller, int activeMatchOrdinal, int numberOfMatches, bool isDoneCounting)? | void | 否 | 是 |

---

### ProxyController 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| setProxyOverride | 设置网络代理配置 | function | ProxySettings settings | Future<void> | 否 | 是 |
| clearProxyOverride | 清除网络代理配置 | function | / | Future<void> | 否 | 是 |

---

### PullToRefreshController 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| setEnabled | 启用/禁用下拉刷新功能 | function | bool enabled | Future<void> | 否 | 是 |
| beginRefreshing | 手动开始刷新动画 | function | / | Future<void> | 否 | 是 |
| endRefreshing | 结束刷新动画 | function | / | Future<void> | 否 | 是 |
| isEnabled | 检查刷新功能是否启用 | function | / | Future<bool> | 否 | 是 |
| isRefreshing | 检查是否正在刷新 | function | / | Future<bool> | 否 | 是 |
| setColor | 设置刷新指示器颜色 | function | Color color | Future<void> | 否 | 否 |
| setBackgroundColor | 设置刷新背景颜色 | function | Color color | Future<void> | 否 | 否 |
| setDistanceToTriggerSync | 设置触发刷新的距离 | function | int distanceToTriggerSync | Future<void> | 否 | 否 |
| setSlingshotDistance | 设置弹性回弹距离（iOS 特有） | function | int slingshotDistance | Future<void> | 否 | 否 |
| setIndicatorSize | 设置指示器大小（Android 特有） | function | PullToRefreshSize size | Future<void> | 否 | 否 |
| setStyledTitle | 设置刷新标题（iOS 特有） | function | AttributedString attributedTitle | Future<void> | 否 | 否 |

---

### WebViewAssetLoader 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| handle | 处理指定路径的资源请求 | function | String path | Future<WebResourceResponse?> | 否 | 是 |
| path | 资源路径匹配规则 | String | / | String | 否 | 是 |
| type | 路径处理器类型 | String | / | String | 否 | 是 |
| AssetsPathHandler | 资源文件处理器 | Object | String path | AssetsPathHandler | 否 | 是 |
| ResourcesPathHandler | 资源文件处理器 | Object | String path | ResourcesPathHandler | 否 | 是 |
| InternalStoragePathHandler | 内部存储处理器 | Object | String path, String directory | InternalStoragePathHandler | 否 | 否 |
| CustomPathHandler | 自定义路径处理器 | Object | String path | CustomPathHandler | 否 | 是 |

---

### ContentBlocker 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| ContentBlocker | 内容阻止规则容器 | Object | ContentBlockerTrigger trigger, ContentBlockerAction action | ContentBlocker | 否 | 是 |
| trigger | 触发规则定义 | ContentBlockerTrigger | / | ContentBlockerTrigger | 否 | 是 |
| action | 触发后的执行操作 | ContentBlockerAction | / | ContentBlockerAction | 否 | 是 |
| urlFilter | URL 匹配正则表达式 | String | String urlFilter | String | 否 | 是 |
| urlFilterIsCaseSensitive | URL 匹配是否区分大小写 | bool | bool urlFilterIsCaseSensitive = false | bool | 否 | 是 |
| resourceType | 资源类型过滤列表 | List<ContentBlockerTriggerResourceType> | List<ContentBlockerTriggerResourceType> resourceType = const [] | List<ContentBlockerTriggerResourceType> | 否 | 否 |
| ifDomain | 生效规则的域名列表 | List<String> | List<String> ifDomain = const [] | List<String> | 否 | 是 |
| unlessDomain | 排除的域名列表 | List<String> | List<String> unlessDomain = const [] | List<String> | 否 | 是 |
| loadType | 加载类型过滤 | List<ContentBlockerTriggerLoadType> | List<ContentBlockerTriggerLoadType> loadType = const [] | List<ContentBlockerTriggerLoadType> | 否 | 否 |
| ifFrameUrl | iframe URL 匹配规则 | List<String> | List<String> ifFrameUrl = const [] | List<String> | 否 | 否 |
| unlessTopUrl | 排除的主文档URL | List<String> | List<String> unlessTopUrl = const [] | List<String> | 否 | 是 |
| type | 操作类型 (block/display-none等) | enum | ContentBlockerActionType type | ContentBlockerActionType | 否 | 是 |
| selector | CSS选择器 (仅 display-none) | String | String? selector | String? | 否 | 否 |

---

### WebMessageChannel

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| WebMessageChannel | 创建 Web 消息通道 | 构造函数 | String id, WebMessagePort port1, WebMessagePort port2 | WebMessageChannel | 是 | 是 |
| id | 通道唯一标识 | String | / | String | 否 | 是 |
| port1 | 通道端口 1 | WebMessagePort | / | WebMessagePort | 否 | 是 |
| port2 | 通道端口 2 | WebMessagePort | / | WebMessagePort | 否 | 是 |
| dispose | 释放通道资源 | 方法 | / | void | 否 | 是 |

> 通过 `InAppWebViewController.createWebMessageChannel()` 创建，配合 `WebMessagePort.postMessage` 实现 Dart 与 Web 页面双向通信。

---

### WebMessagePort

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| setWebMessageCallback | 注册接收消息的回调 | function | ValueCallback<void> callback | void | 否 | 是 |
| postMessage | 向配对端口发送 WebMessage | function | WebMessage message | void | 否 | 是 |
| close | 关闭此消息端口 | function | / | void | 否 | 是 |

> 作为 WebMessageChannel 中的 port1/port2 使用；在一个端口上发送的消息会在配对端口上接收。

---

### WebMessageListener

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| WebMessageListener | 注册 JS 侧消息监听对象 | 构造函数 | String jsObjectName, Set<String>? allowedOriginRules, OnPostMessageCallback? onPostMessage | WebMessageListener | 是 | 是 |
| jsObjectName | 注入到 Web 环境的对象名 | String | / | String | 是 | 是 |
| allowedOriginRules | 允许的来源规则集合 | Set<String> | Set<String>? allowedOriginRules | Set<String>? | 否 | 是 |
| onPostMessage | 收到 Web 消息时的回调 | 函数 | WebMessage message, JavaScriptReplyProxy replyProxy | void | 否 | 是 |
| dispose | 释放监听器资源 | 方法 | / | void | 否 | 是 |

> 通过 `InAppWebViewController.addWebMessageListener()` 注册；页面内通过 `jsObjectName.postMessage()` 向 Dart 发送消息。

---

### InAppWebViewKeepAlive 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| InAppWebViewKeepAlive | 创建 WebView 常驻实例 | constructor | / | InAppWebViewKeepAlive | 否 | 是 |
| id | 获取/设置常驻实例的 ID | String | / | String | 否 | 是 |
| javaScriptHandlersMap | JavaScript 处理器映射表 | Map<String, JavaScriptHandlerCallback> | Map<String, JavaScriptHandlerCallback> javaScriptHandlersMap | / | 否 | 是 |
| userScripts | 用户脚本集合 | Map<UserScriptInjectionTime, List<UserScript>> | Map<UserScriptInjectionTime, List<UserScript>> userScripts | / | 否 | 是 |
| webMessageListenerObjNames | Web 消息监听器对象名称 | Set<String> | Set<String> webMessageListenerObjNames | / | 否 | 是 |
| injectedScriptsFromURL | 通过 URL 注入的脚本属性 | Map<String, ScriptHtmlTagAttributes> | Map<String, ScriptHtmlTagAttributes> injectedScriptsFromURL | / | 否 | 是 |
| webMessageChannels | Web 消息通道集合 | Set<PlatformWebMessageChannel> | Set<PlatformWebMessageChannel> webMessageChannels = Set() | / | 否 | 是 |
| webMessageListeners | Web 消息监听器集合 | Set<PlatformWebMessageListener> | Set<PlatformWebMessageListener> webMessageListeners = Set() | / | 否 | 是 |

---

### InAppBrowser 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| openUrlRequest | 使用指定的 URLRequest 打开网页 | function | URLRequest urlRequest, InAppBrowserClassOptions? options, InAppBrowserClassSettings? settings | Future<void> | 否 | 否 |
| openFile | 打开本地文件 | function | String assetFilePath, InAppBrowserClassOptions? options, InAppBrowserClassSettings? settings | Future<void> | 否 | 否 |
| openData | 打开 HTML 数据 | function | String data, String mimeType = "text/html", String encoding = "utf8", WebUri? baseUrl, WebUri? historyUrl, InAppBrowserClassSettings? settings | Future<void> | 否 | 否 |
| show | 显示浏览器窗口 | function | / | Future<void> | 否 | 是 |
| hide | 隐藏浏览器窗口 | function | / | Future<void> | 否 | 是 |
| close | 关闭浏览器窗口 | function | / | Future<void> | 否 | 是 |
| setSettings | 设置浏览器配置 | function | InAppBrowserClassSettings settings | Future<void> | 否 | 部分 |
| getSettings | 获取当前配置 | function | / | Future<InAppBrowserClassSettings?> | 否 | 是 |
| addMenuItem | 添加菜单项 | function | InAppBrowserMenuItem menuItem | void | 否 | 否 |
| removeMenuItem | 移除菜单项 | function | InAppBrowserMenuItem menuItem | bool | 否 | 否 |
| isHidden | 检查浏览器是否隐藏 | function | / | Future<bool> | 否 | 是 |
| isOpened | 检查浏览器是否已打开 | function | / | bool | 否 | 是 |
| onBrowserCreated | 浏览器创建回调 | function | / | void | 否 | 是 |
| onLoadStart | 页面加载开始回调 | function | WebUri? url | void | 否 | 是 |
| onLoadStop | 页面加载完成回调 | function | WebUri? url | void | 否 | 是 |
| onLoadError | 加载错误回调 | function | WebUri? url, int code, String message | void | 否 | 是 |
| onProgressChanged | 加载进度变化回调 | function | int progress | void | 否 | 是 |
| onTitleChanged | 页面标题变化回调 | function | String? title | void | 否 | 是 |
| onExit | 浏览器退出回调 | function | / | void | 否 | 否 |
| onConsoleMessage | 控制台消息回调 | function | ConsoleMessage consoleMessage | void | 否 | 是 |
| onReceivedIcon | 网站图标接收回调 | function | Uint8List icon | void | 否 | 否 |
| onPermissionRequest | 权限请求回调 | function | PermissionRequest permissionRequest | Future<PermissionResponse?> | 否 | 是 |
| onJsAlert | JavaScript 弹窗回调 | function | JsAlertRequest jsAlertRequest | Future<JsAlertResponse?> | 否 | 是 |
| onJsConfirm | JavaScript 确认框回调 | function | JsConfirmRequest jsConfirmRequest | Future<JsConfirmResponse?> | 否 | 是 |

---

### ChromeSafariBrowser 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| open | 使用指定 URL 打开浏览器 | function | WebUri? url, Map<String, String>? headers, List<WebUri>? otherLikelyURLs, ChromeSafariBrowserSettings? settings | Future<void> | 否 | 否 |
| launchUrl | 启动指定的 URL | function | WebUri url, Map<String, String>? headers, List<WebUri>? otherLikelyURLs | Future<void> | 否 | 否 |
| close | 关闭浏览器 | function | / | Future<void> | 否 | 否 |
| isAvailable | 检查浏览器可用性 | static function | / | Future<bool> | 否 | 否 |
| clearWebsiteData | 清除网站数据 | static function | / | Future<void> | 否 | 否 |
| prewarmConnections | 预热连接 | static function | List<WebUri> URLs | Future<PrewarmingToken?> | 否 | 否 |
| onClosed | 浏览器关闭回调 | function | / | void | 否 | 否 |
| onOpened | 浏览器打开回调 | function | / | void | 否 | 否 |
| onCompletedInitialLoad | 初始加载完成回调 | function | bool? didLoadSuccessfully | void | 否 | 否 |
| onNavigationEvent | 导航事件回调 | function | CustomTabsNavigationEventType? navigationEvent | void | 否 | 否 |
| onPostMessage | postMessage 回调 | function | String message | void | 否 | 否 |
| setActionButton | 设置操作按钮 | function | ChromeSafariBrowserActionButton actionButton | void | 否 | 否 |
| setSecondaryToolbar | 设置二级工具栏 | function | ChromeSafariBrowserSecondaryToolbar secondaryToolbar | void | 否 | 否 |
| addMenuItem | 添加菜单项 | function | ChromeSafariBrowserMenuItem menuItem | void | 否 | 否 |
| requestPostMessageChannel | 请求消息通道 | function | WebUri sourceOrigin, WebUri? targetOrigin | Future<bool> | 否 | 否 |
| validateRelationship | 验证关系 | function | CustomTabsRelationType relation, WebUri origin | Future<bool> | 否 | 否 |

---

### InAppLocalhostServer 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| InAppLocalhostServer | 创建本地服务器实例 | constructor | int port = 8080, String directoryIndex = "index.html", String documentRoot = "./", bool shared = false | InAppLocalhostServer | 否 | 否 |
| start | 启动本地服务器 | function | / | Future<void> | 否 | 否 |
| close | 停止本地服务器 | function | / | Future<void> | 否 | 否 |
| isRunning | 检查服务器是否正在运行 | function | / | bool | 否 | 否 |
| port | 获取服务器端口号 | int | / | int | 否 | 否 |
| directoryIndex | 获取目录索引文件名 | String | / | String | 否 | 否 |
| documentRoot | 获取文档根目录 | String | / | String | 否 | 否 |
| shared | 检查实例是否为共享实例 | bool | / | bool | 否 | 否 |

---

### CookieManager 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| setCookie | 为指定 URL 设置 Cookie | function | WebUri url, String name, String value, String path = "/", String? domain, int? expiresDate, int? maxAge, bool? isSecure, bool? isHttpOnly, HTTPCookieSameSitePolicy? sameSite, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<bool> | 否 | 是 |
| getCookies | 获取指定 URL 的所有 Cookie | function | WebUri url, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<List<Cookie>> | 否 | 是 |
| getCookie | 按名称获取 Cookie | function | WebUri url, String name, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<Cookie?> | 否 | 是 |
| deleteCookie | 删除指定的 Cookie | function | WebUri url, String name, String path = "/", String? domain, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<bool> | 否 | 是 |
| deleteCookies | 删除指定 URL 的所有 Cookie | function | WebUri url, String path = "/", String? domain, InAppWebViewController? iosBelow11WebViewController, InAppWebViewController? webViewController | Future<bool> | 否 | 是 |
| deleteAllCookies | 删除所有 Cookie | static function | / | Future<bool> | 否 | 是 |
| getAllCookies | 获取所有 Cookie（仅 iOS/macOS 支持） | static function | / | Future<List<Cookie>> | 否 | 否 |
| removeSessionCookies | 删除会话 Cookie | static function | / | Future<bool> | 否 | 是 |
| IOSCookieManager | iOS 特定的 Cookie 管理类（已弃用） | Object | / | IOSCookieManager | 否 | 否 |

---

### HttpAuthCredentialDatabase 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| getAllAuthCredentials | 获取所有 HTTP 认证凭据 | function | / | Future<List<URLProtectionSpaceHttpAuthCredentials>> | 否 | 是 |
| getHttpAuthCredentials | 获取指定保护空间的 HTTP 凭据 | function | URLProtectionSpace protectionSpace | Future<List<URLCredential>> | 否 | 是 |
| setHttpAuthCredential | 设置 HTTP 认证凭据 | function | URLProtectionSpace protectionSpace, URLCredential credential | Future<void> | 否 | 是 |
| removeHttpAuthCredential | 移除指定的 HTTP 认证凭据 | function | URLProtectionSpace protectionSpace, URLCredential credential | Future<void> | 否 | 是 |
| removeHttpAuthCredentials | 移除指定保护空间的所有凭据 | function | URLProtectionSpace protectionSpace | Future<void> | 否 | 是 |
| clearAllAuthCredentials | 清除所有认证凭据 | function | / | Future<void> | 否 | 是 |
| dispose | 释放资源 | function | / | Future<void> | 否 | 是 |

---

### WebAuthenticationSession 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| create | 创建 Web 认证会话 | function | WebUri url, String? callbackURLScheme, WebAuthenticationSessionCompletionHandler onComplete, WebAuthenticationSessionSettings? initialSettings | Future<WebAuthenticationSession> | 否 | 否 |
| canStart | 检查是否可以启动会话 | function | / | Future<bool> | 否 | 否 |
| start | 启动 Web 认证会话 | function | / | Future<bool> | 否 | 否 |
| cancel | 取消正在进行的认证会话 | function | / | Future<void> | 否 | 否 |
| dispose | 释放会话资源 | function | / | Future<void> | 否 | 否 |
| isAvailable | 检查设备是否支持 Web 认证 | static function | / | Future<bool> | 否 | 否 |
| id | 获取会话唯一标识符 | String | / | String | 否 | 否 |
| url | 获取认证会话的 URL | WebUri | / | WebUri | 否 | 否 |
| callbackURLScheme | 获取回调 URL 方案 | String | / | String? | 否 | 否 |
| initialSettings | 获取初始会话配置 | WebAuthenticationSessionSettings | / | WebAuthenticationSessionSettings? | 否 | 否 |
| onComplete | 认证完成处理程序 | WebAuthenticationSessionCompletionHandler | / | WebAuthenticationSessionCompletionHandler | 否 | 否 |

---

### WebUri 

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OpenHarmony平台支持 |
|------|------|------|----------|--------|------|-------------------|
| authority | 获取 URI 的权限部分（主机:端口格式） | String | / | String | 否 | 是 |
| data | 获取 URI 的数据部分 | UriData? | / | UriData? | 否 | 是 |
| fragment | 获取 URI 的片段标识符 | String | / | String | 否 | 是 |
| hasAbsolutePath | 检查路径是否为绝对路径 | bool | / | bool | 否 | 是 |
| hasAuthority | 检查是否存在权限信息 | bool | / | bool | 否 | 是 |
| hasEmptyPath | 检查路径是否为空 | bool | / | bool | 否 | 是 |
| hasFragment | 检查是否存在片段 | bool | / | bool | 否 | 是 |
| hasPort | 检查是否存在端口号 | bool | / | bool | 否 | 是 |
| hasQuery | 检查是否存在查询参数 | bool | / | bool | 否 | 是 |
| hasScheme | 检查是否存在协议方案 | bool | / | bool | 否 | 是 |
| host | 获取主机名（区分大小写） | String | / | String | 否 | 是 |
| isAbsolute | 检查 URI 是否为绝对路径 | bool | / | bool | 否 | 是 |
| isScheme | 检查协议方案是否匹配 | function | String scheme | bool | 否 | 是 |
| normalizePath | 标准化路径（去除冗余） | function | / | Uri | 否 | 是 |
| origin | 获取源（scheme+authority） | String | / | String | 否 | 是 |
| path | 获取路径（区分大小写） | String | / | String | 否 | 是 |
| pathSegments | 获取路径段的列表 | List<String> | / | List<String> | 否 | 是 |
| port | 获取端口号 | int | / | int | 否 | 是 |
| query | 获取原始查询字符串 | String | / | String | 否 | 是 |
| queryParameters | 获取查询参数映射（仅第一个值） | Map<String, String> | / | Map<String, String> | 否 | 是 |
| queryParametersAll | 获取完整的查询参数映射 | Map<String, List<String>> | / | Map<String, List<String>> | 否 | 是 |
| removeFragment | 创建一个移除了片段的新 URI | function | / | Uri | 否 | 是 |
| replace | 替换 URI 的组成部分 | function | String? scheme, String? userInfo, String? host, int? port, String? path, Iterable<String>? pathSegments, String? query, Map<String, dynamic>? queryParameters, String? fragment | Uri | 否 | 是 |
| resolve | 解析相对 URI | function | String reference | Uri | 否 | 是 |
| resolveUri | 解析相对的 URI 对象 | function | Uri reference | Uri | 否 | 是 |
| scheme | 获取协议方案（例如 http） | String | / | String | 否 | 是 |
| toFilePath | 转换为文件路径 | function | bool? windows | String | 否 | 是 |
| userInfo | 获取用户信息组件 | String | / | String | 否 | 是 |
| rawValue | 获取原始未解析的 URI 字符串 | String | / | String | 否 | 是 |
| uriValue | 获取解析后的标准 URI 对象 | Uri | / | Uri | 否 | 是 |
| isValidUri | 表示 URI 解析是否成功 | bool | / | bool | 否 | 是 |
| forceToStringRawValue | 控制 `toString()` 是否使用原始值 | bool | / | bool | 否 | 是 |
| normalizePath() | 返回标准化后的新路径 URI | function | / | Uri | 否 | 是 |
| toString() | 字符串表示（可配置为使用原始值） | function | / | String | 否 | 是 |

---

## 遗留问题

无

## 目录结构

```text
flutter_inappwebview/                  # 主包，对外统一导出 API
flutter_inappwebview_ohos/             # OpenHarmony 平台实现（ArkTS）
flutter_inappwebview_platform_interface/  # 跨平台接口定义
flutter_inappwebview_android/          # Android 平台实现
flutter_inappwebview_ios/              # iOS 平台实现
flutter_inappwebview_macos/            # macOS 平台实现
flutter_inappwebview_web/              # Web 平台实现
flutter_inappwebview_windows/          # Windows 平台实现
dev_packages/                          # 内部开发工具包
```

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/CPF-Flutter/flutter_inappwebview/issues)，当然，也非常欢迎发 [PR](https://gitcode.com/CPF-Flutter/flutter_inappwebview/pulls) 共建。

## 开源协议

本项目基于 [Apache-2.0](https://github.com/pichillilorenzo/flutter_inappwebview/blob/master/LICENSE)，请自由地享受和参与开源。
