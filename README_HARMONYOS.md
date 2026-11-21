# 纯粹直播 · HarmonyOS NEXT 版

> 基于 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live) 的鸿蒙原生移植版本，遵循上游的 **AGPL-3.0** 协议开源。

这是一个社区移植分支，把上游 Flutter 直播聚合播放器跑通在 **HarmonyOS NEXT（Ohos）** 平台上。上游支持 Android / TV / Windows / Linux / macOS / iOS，本分支额外增加鸿蒙端，并针对鸿蒙的媒体与系统能力做了适配。

## 与原版的关系

- **上游**：[github.com/liuchuancong/pure_live](https://github.com/liuchuancong/pure_live)（AGPL-3.0）
- **本仓库**：鸿蒙 NEXT 移植分支，同协议开源
- **协议声明**：见 [LICENSE](LICENSE) 与 [NOTICE](NOTICE)。移植与改动均在 AGPL-3.0 第 5、13 条框架下进行。
- 本项目为独立社区移植，与上游作者无隶属或背书关系。

## 鸿蒙端做了什么

| 改动 | 说明 |
| --- | --- |
| 鸿蒙应用壳 `ohos/` | 基于 Flutter-OH，用 `FlutterAbility` + `FlutterPage` 承载 Dart UI |
| 播放内核 `vendor/media_core_avplayer` | 新增 AVPlayer 后端，调用系统 `@ohos.multimedia.media.AVPlayer`，通过 Flutter 外接纹理出画；在 Ohos 上替代上游的 libmpv / media-kit 后端 |
| 播放后端选择 | `PlayerKernel` 在 Ohos 上只注册 AVPlayer 后端；`backendIdOfEngine` 把 mediaKit 映射到 AVPlayer |
| 连接性检测兜底 | 鸿蒙端缺少 connectivity 插件时不再阻塞取流链路 |
| 本地 vendor fork | 为鸿蒙适配的 media_core / media_kit / flutter_inappwebview / flutter_packages，随仓库一起分发以保证可复现 |
| 构建脚本 `tool/` | `build_hap.sh` / `env.sh` 封装 SDK 路径与构建环境 |

### 关于播放后端的选择

上游默认用 libmpv（经 media-kit）。`native_bundles.json` 里虽然有 `ohos_arm64` 的 libmpv 产物条目，但 Flutter-OH 的 native-assets hook 无法识别 Ohos target，因此本分支改为使用**系统自带 AVPlayer**：

- 支持网络直播 **HLS / HTTP-FLV**、网络点播 http/https/hls/dash
- 不支持 RTMP（鸿蒙 AVPlayer 限制）
- 硬件解码，无需打包 15MB 的 libmpv.so

## 环境要求

| 依赖 | 版本 / 说明 |
| --- | --- |
| Flutter-OH | `flutter_flutter` 3.47.7+ohos-0.0.1-canary（见 `FLUTTER_GIT_URL`） |
| Dart | ^3.13.0 |
| DevEco Studio / SDK | HarmonyOS NEXT SDK（本机为 API 24 基线，`runtimeOS: HarmonyOS`） |
| OHPM | 通过 `ohpmBin` 指向 shim |
| JDK | DevEco 自带 JBR |

`tool/env.sh` 里的路径是本机环境示例，请按自己的机器修改：

```bash
export FLUTTER_OHOS_ROOT="/path/to/flutter_ohos"
export DEVECO_SDK_HOME="/path/to/DevEco Studio/sdk"
export JAVA_HOME="/path/to/DevEco Studio/jbr"
export ohpmBin="/path/to/ohpm shim"
```

## 构建

```bash
# 在配置好 tool/env.sh 后
bash tool/build_hap.sh          # 构建 debug HAP
# 产物：build/ohos/hap/entry-default-signed.hap
```

安装到真机：

```bash
hdc install -r build/ohos/hap/entry-default-signed.hap
hdc shell aa start -b com.purelive.pure_live -a EntryAbility
```

## 已验证范围

- Flutter-OH 工程编译通过，HAP 签名并安装到真机
- 应用启动、首页、直播间列表正常
- B 站 HTTP-FLV 直播流可播放，外接纹理正常出画，弹幕叠加正常
- 鸿蒙 AVPlayer 后端完成 `prepared → playing` 状态链路

## 已知限制

- **RTMP** 直播流不受支持（AVPlayer 限制）；如需 RTMP 需另接 libmpv 后端。
- 部分 `connectivity_plus` 等插件在鸿蒙端缺少原生实现，当前用超时兜底，链路不阻塞但日志可能有提示。
- 诊断用的 `nativeTrace` 日志调用保留在代码中，稳定后可统一移除。

## 目录结构

```
ohos/                         鸿蒙应用工程（Flutter-OH 壳）
  entry/src/main/ets/         ArkTS 插件注册与页面
vendor/
  media_core/                播放内核（鸿蒙适配 fork）
  media_core_avplayer/       新增 AVPlayer 后端插件
  media_kit/ / flutter_inappwebview/ / flutter_packages/   本地 fork
tool/env.sh / build_hap.sh   构建环境
lib/                         上游 Dart 业务代码（含少量鸿蒙适配）
```

各 vendored 组件保留各自的 LICENSE，详见其目录。

## 致谢与声明

- 感谢 [liuchuancong/pure_live](https://github.com/liuchuancong/pure_live) 提供优秀的开源基础。
- 本项目仅供学习与技术交流，请遵守当地法律法规，仅使用合法授权的直播源。

本项目按 **GNU Affero General Public License v3.0** 开源，详见 [LICENSE](LICENSE)。
