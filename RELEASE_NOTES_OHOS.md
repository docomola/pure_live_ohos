# Pure Live 鸿蒙版更新说明

本文件只记录 HarmonyOS NEXT 移植分支的版本。上游各平台（Windows / Android / Linux / macOS）的版本说明见 [RELEASE_NOTES.md](RELEASE_NOTES.md)。

## v1.1.0（2026-11-22）

把底部导航换成官方 HDS 沉浸光感材质，补齐应用外壳的品牌化与启动体验。

### 新增

- **官方 HDS 沉浸光感悬浮底栏**：改用 `@kit.UIDesignKit` 的 `HdsTabs` + `barFloatingStyle.systemMaterialEffect`，材质档位 `MaterialType.IMMERSIVE` + `MaterialLevel.EXQUISITE`（设备不支持时自动降级到 `SMOOTH`）。底栏是浮在内容之上的全圆角胶囊，背景实时模糊，选中项用实心图标加淡高光。
  - 之前手调 `uiMaterial.ImmersiveMaterial` + `systemMaterial()` 的写法拿不到材质流光与按压点光源，已整体替换。SDK 里 `systemMaterialEffect` 只挂在两个宿主上（`TitleBarStyleOptions`、`HdsTabsFloatingStyle`），手调半透明色块无法等效。
  - `module.json5` 增加 `ohos.arkui.UIMaterial.state: enable`，避免系统按算力档位或省电策略把材质降级成纯色块。
- **四个栏目全页常驻底栏**：热门 / 分区 / 关注 / 录制中心任何一页都有底栏，选中态跟随页面。
- **底部沉浸**：内容可以滚到胶囊底下穿过，玻璃才有东西可折射；各列表在末尾补足留白，「回到顶部」悬浮按钮抬到胶囊之上。
- **应用图标与名称**：图标换成新的「纯净直播」图，应用名统一为 `Pure Live`（含 `zh_CN` / `en_US` 本地化）。
- **启动阶段不再有白屏与 logo**：启动窗口图标改为全透明占位、背景改为应用底色 `#101418`，点开直接落在首页。

### 修复

- **点全屏不横屏**：Flutter-OH 的 `decodeOrientations` 是位掩码，传左右两个方向只会得到「跟随系统自动旋转」；改成只传 `landscapeLeft` 拿强制 `LANDSCAPE`。同时 `PlatformUtils.isMobile` 补上 ohos，全屏判定不再落到 unsupported 分支并被吞掉。
- **切页签后底栏被画面盖住**：SURFACE 型 `XComponent` 是独立原生图层，Flutter 重新布局后会压到 ArkUI 之上。`FlutterPage` 改用 `XComponentType.TEXTURE`，走 ArkUI 渲染树，层序稳定。
- **桌面应用名显示为 `pure_live`**：中文环境取的是 `zh_CN/element/string.json`，此前只改了 `base`。三个语言目录已统一。

### 变更

- **底部导航默认顺序改为 热门 → 分区 → 关注 → 录制中心**，冷启动固定落在热门。旧安装只有在仍是旧默认排列时才迁移，用户自己拖过的顺序不动。
- **SDK 基线提到 API 26**（`compatibleSdkVersion` / `targetSdkVersion` 均为 `26.0.0`），HDS 沉浸材质要求 API 26。

### 验证

真机 nova 14 Pro（HarmonyOS 7.0.0.111 / API 26）：四个页签逐页确认底栏在位、选中态正确、切页与滚动正常，Flutter 触摸未被 `HdsTabs` 拦截（空 `TabContent` 加 `HitTestMode.None` 穿透）；胶囊把身后的封面真实模糊成色块，带圆角高光边缘。

### 已知限制

- debug 签名 HAP，仅用于开发测试，不能上架应用市场。
- 不支持 RTMP（AVPlayer 限制）。
- 仅适配手机，未适配 TV / 桌面端。

## v1.0.0（2026-11-21）

首个可安装版本：AVPlayer 播放内核 + Flutter 外接纹理出画，release（AOT）单文件 HAP，68.4 MB。
