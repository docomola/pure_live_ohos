<div align="center">

<img src="assets/icons/icon.png" width="120" alt="Pure Live 图标"/>

# 纯粹直播 · HarmonyOS NEXT 版

**把上游 Flutter 直播聚合器真正跑通在鸿蒙上的移植分支**

一个应用看遍全网直播 —— 这是 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live) 的鸿蒙原生移植版，遵循上游的 AGPL-3.0 协议开源。

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-HarmonyOS%20NEXT-0A59F7)](https://consumer.huawei.com/cn/phones/harmonyos/)
[![Flutter](https://img.shields.io/badge/Flutter-OH%203.47-02569B)](https://gitee.com/openharmony-sig/flutter_flutter)
[![Release](https://img.shields.io/github/v/release/docomola/pure_live_ohos?label=%E5%AE%89%E8%A3%85%E5%8C%85)](https://github.com/docomola/pure_live_ohos/releases)

<img src="assets/images/banner.png" width="720" alt="Pure Live 界面预览"/>

</div>

---

## 为什么有这个分支

上游 pure_live 支持 Android / TV / Windows / Linux / macOS / iOS，但鸿蒙（HarmonyOS NEXT）不在其中。真正的障碍不是 UI，而是**播放内核**：上游默认走 libmpv（media-kit），而 Flutter-OH 的 native-assets hook 不认识鸿蒙 target，`native_bundles.json` 里那条 `ohos_arm64` 的 libmpv 产物根本不会被命中。

这个分支换了一条路：**用鸿蒙系统自带的 AVPlayer 当播放内核，用 Flutter 外接纹理出画**。Dart 业务代码基本沿用上游，改动集中在播放后端、应用壳和一批为鸿蒙打了补丁的 vendor 依赖。

> 本文只讲鸿蒙端的改动与差异。上游完整的站点清单、功能说明、平台兼容性表格请见 [上游 README](https://github.com/liuchuancong/pure_live#readme)，这里不再重复。

## 鸿蒙端做了哪些改动

### 1. 播放内核：从 libmpv 换成系统 AVPlayer

新增 `vendor/media_core_avplayer/` —— 一个实现 `media_core` 的 `PlayerAdapter` 契约的插件：

| | 上游 | 本分支（Ohos） |
| --- | --- | --- |
| 播放内核 | libmpv / media-kit | 系统 `@ohos.multimedia.media.AVPlayer` |
| 视频渲染 | libmpv 自带输出 | Flutter 外接纹理（`TextureRegistry` → `SurfaceTextureEntry.getSurfaceId()`） |
| 通信 | native assets / FFI | `MethodChannel` + `EventChannel` |
| 解码 | 软解为主 | 硬件解码 |
| 包体增量 | +15MB libmpv.so | 0（系统能力） |

在 `PlayerKernel` 里，鸿蒙平台只注册 AVPlayer 后端；`backendIdOfEngine` 把 `mediaKit` 引擎映射到 AVPlayer。后端状态机为 `prepared → playing`，`onOpen` 会等待 `prepared` 才返回，避免黑屏。

**一个实际的坑**：纹理几何（`setTextureBufferSize`）如果在 AVPlayer 已经开始送帧之后设置，会让在途 buffer 失效，画面永久黑。修复方式是把几何设置挪到 `create()` 阶段（无帧在途），`onVideoSize()` 只记录尺寸。这个问题只在首次打开特定流时出现，第二次因尺寸去重反而不复现。

### 2. 能力边界差异

- 直播支持 **HLS / HTTP-FLV**，点播支持 http/https/hls/dash。
- **不支持 RTMP**（鸿蒙 AVPlayer 限制）。如果确实需要 RTMP，只能另接 libmpv 后端。
- 鸿蒙端没有 connectivity 插件的原生实现，取流链路加了超时兜底，链路不阻塞。

### 3. 应用壳：FlutterAbility + FlutterPage

`ohos/` 是一个 Flutter-OH 工程：`EntryAbility extends FlutterAbility`，ArkTS 页面 `Index.ets` 里用 `FlutterPage({viewId})` 承载 Dart UI，返回键通过 `eventHub` 转发。这是一套标准的 ArkTS 与 Flutter 混编结构，后续要用原生页面或原生组件（PlatformView）接进来都很容易。

### 4. 本地 vendor fork

为了让别人 clone 后能构建出同样的结果，几个为鸿蒙打了补丁的依赖直接随仓库分发：

```
vendor/
  media_core/          播放内核（鸿蒙适配）
  media_core_avplayer/ 本分支新增的 AVPlayer 后端
  media_kit/           native assets hook 适配
  flutter_inappwebview/ cookie manager 等 Ohos 补丁
  flutter_packages/    path_provider / shared_preferences 的 Ohos 实现
```

每个 vendored 组件保留自己的 LICENSE。

### 5. 构建脚本参数化

`tool/env.sh` 用 `${VAR:-默认值}` 的形式，覆盖 `FLUTTER_OHOS_ROOT` / `DEVECO_SDK_HOME` / `JAVA_HOME` / `ohpmBin` 等路径。`tool/build_hap.sh` 清理了宿主环境注入的 `NODE_OPTIONS` 和 sandbox shim（它们会让 hvigor 的临时清理超时），一条命令出 HAP。

### 6. 原生悬浮底栏（HDS 沉浸光感）

底部导航不是 Flutter 画的，而是 ArkTS 组件 `GlassNavBar` 叠在 Flutter 画面之上：

- 材质走官方 `@kit.UIDesignKit` 的 `HdsTabs` + `barFloatingStyle.systemMaterialEffect`（`IMMERSIVE` + `EXQUISITE`）。SDK 里 `systemMaterialEffect` 只挂在 `TitleBarStyleOptions` 和 `HdsTabsFloatingStyle` 两个宿主上，手调 `backgroundEffect` 或半透明色块都拿不到材质流光与按压点光源。
- `HdsTabs` 只承担页签栏，`TabContent` 内容层是空 `Stack` 并加 `hitTestBehavior(HitTestMode.None)`，触摸继续落到下层 Flutter；`.scrollable(false)` 不抢列表手势。
- 栏目清单、选中项、显隐由 Dart 侧通过 MethodChannel（`pure_live/glass_nav`）下推，点击回传同一个通道，ArkTS 用 `AppStorage` / `@StorageLink` 驱动渲染。
- `FlutterPage` 必须用 `XComponentType.TEXTURE` 合成：SURFACE 型 `XComponent` 是独立原生图层，Flutter 重新布局后会压到 ArkUI 之上，底栏会被吃掉。

Dart 侧的桥在 `lib/core/platform/glass_nav_bar.dart`，各列表页在末尾补 `GlassNavBar.contentInset`，让内容能滚到胶囊底下穿过。

## 安装

从 [Releases](https://github.com/docomola/pure_live_ohos/releases) 下载最新的 `pure_live_ohos-*.hap`（**debug 签名**，需开启开发者模式）：

```bash
hdc install -r pure_live_ohos-1.1.0.hap
hdc shell aa start -b com.purelive.pure_live -a EntryAbility
```

> debug 签名 HAP 仅供开发测试，不能上架应用市场。做正式发布需要换成自己的发布证书与 Profile。

各版本的改动见 [RELEASE_NOTES_OHOS.md](RELEASE_NOTES_OHOS.md)。

## 从源码构建

环境：Flutter-OH `flutter_flutter` 3.47.7+ohos-0.0.1-canary（Dart ^3.13）、DevEco Studio / HarmonyOS NEXT SDK、JDK（DevEco 自带 JBR）。

```bash
# 1. 按自己的机器设置路径（见 tool/env.sh 注释）
export FLUTTER_OHOS_ROOT="/path/to/flutter_ohos"
export DEVECO_SDK_HOME="/path/to/DevEco Studio/sdk"
export JAVA_HOME="/path/to/DevEco Studio/jbr"

# 2. 构建
bash tool/build_hap.sh
# 产物：build/ohos/hap/entry-default-signed.hap
```

更细的环境说明、已验证范围与已知限制见 [README_HARMONYOS.md](README_HARMONYOS.md)。

## 已验证

真机 nova 14 Pro（HarmonyOS 7.0.0.111 / API 26）：

- release 与 debug HAP 覆盖安装、冷启动正常，启动阶段无白屏与 logo
- 首页热门列表、分区网格、关注列表、录制中心四个页签切换正常，悬浮底栏全程在位
- 底部导航为官方 HDS 沉浸光感材质（`IMMERSIVE` + `EXQUISITE`），背景实时模糊，Flutter 触摸未被原生层拦截
- 直播全屏可强制横屏，退出全屏回竖屏
- B 站 HTTP-FLV 直播流可播放，外接纹理正常出画，弹幕叠加正常

## 已知限制

- 不支持 RTMP（AVPlayer 限制）
- 部分 plus 系列插件缺少 Ohos 实现，当前用超时兜底
- 代码中保留了少量诊断日志（`nativeTrace`），稳定后可移除
- 上游的 TV 端、桌面端功能本分支未做鸿蒙适配

## 协议与致谢

本项目派生自 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live)，按 **GNU Affero General Public License v3.0** 开源。原版权归上游作者所有，鸿蒙端的改动同样在 AGPL-3.0 框架下发布。详见 [LICENSE](LICENSE) 与 [NOTICE](NOTICE)。

本项目为独立社区移植，与上游作者无隶属或背书关系。仅供学习与技术交流，请使用合法授权的直播源。
