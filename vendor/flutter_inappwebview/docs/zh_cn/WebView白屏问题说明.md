# InAppWebView 内容高度过大导致白屏说明

> 适用平台：OHOS
> 关联组件：`InAppWebView` / `OhosWebView`
> 官方依据：[Web 组件渲染模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-render-mode)、[Web 组件 layoutMode 属性](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-attributes#layoutmode11)

---

## 1. 问题现象

使用 `flutter_inappwebview` 在 OHOS 端加载 H5 页面时，当网页内容高度超过约 **2600vp**（设备 dpr=3 时）出现白屏。

白屏特征：

- 白屏区域什么都不显示；
- **无报错、无崩溃、无日志**；
- 阈值随 `devicePixelRatio` 变化，不能硬编码为固定 vp 值。

---

## 2. 根因

`InAppWebView` 通过 PlatformView（`NodeContainer` + `WebNodeController`）接入 Flutter，走纹理合成路径。ArkUI Surface 节点的单边纹理物理像素上限约为 **7680px**（设备/SDK 相关）。纹理物理高度 = Web 组件逻辑高度 × devicePixelRatio。

- **7680px 上限的官方依据**：该限制为鸿蒙官方公开约束，非黑盒推测。《[Web 组件渲染模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-render-mode)》（异步渲染章节）与《[Web 组件 layoutMode 属性](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-attributes#layoutmode11)》均明确指出：当 Web 组件作为 surface 节点（异步渲染 / 纹理合成路径）时，其物理像素高度不得超过 7,680px，否则将白屏。
- 当 `WebLayoutMode.FIT_CONTENT` 被启用时，Web 组件会按网页内容全高自适应布局；
- 若业务侧将容器高度设为网页内容全高（常见于动态获取 contentHeight 后撑开），逻辑高度 × dpr 将超过 7680px，GPU 纹理缓冲申请失败，NodeContainer 返回空纹理，Flutter 引擎采样到空数据，最终渲染为白屏。

阈值：逻辑高度上限 ≈ 7680 ÷ dpr（dpr=3 时约 2560vp，与观测现象一致）。

---

## 3. 解决方案

### 方案 1：不启用 FIT_CONTENT（默认）

保持 `layoutMode = WebLayoutMode.NONE`（默认值），Web 组件高度由父容器约束决定，不随内容撑开，从源头规避超限。适用于 WebView 高度可由外层约束固定住的场景。

### 方案 2：独占一屏（推荐，最简单）

WebView 不与其它 Flutter 组件混排，容器高度恒等于屏幕可视高度。屏高 × dpr 远低于 7680px，天然安全。

> 注意：大屏/折叠屏设备仍需校验 `屏高 × dpr < 7680`。

### 方案 3：混排场景——解耦"布局高度"与"纹理尺寸"

当 WebView 需与其它 Flutter 组件纵向混排、且网页内容很长时：

- **布局层**：用 `SizedBox`/`Container` 占据网页全高，参与 Flutter 布局但本身不产生纹理（即不在此节点放置 WebView）；
- **纹理层**：`InAppWebView` 高度恒定为「视口 viewport + 一屏 overscan」（须保证 `(视口 + overscan) × dpr < 7680`），通过 `Positioned.top` 平移该窗口跟随滚动；
- **滚动同步**：监听 Flutter `ScrollController.offset`，同步调用 `controller.scrollTo(offset)` 驱动网页内容滚动，保证视觉连续。

注意事项：

- 方案 3 必须搭配 `layoutMode = NONE`，与 `FIT_CONTENT` 互斥；
- 滚动同步需处理两套渲染时序，避免撕裂；建议以单一滚动源（Flutter 或 Web）驱动；
- overscan 取值应 ≤ 一屏，并在目标设备上验证不超阈值；
- 手势事件归属需明确，避免 Web 与 Flutter 滚动竞争。

---

## 4. 临界阈值速查

| devicePixelRatio | 临界 vp（7680 ÷ dpr） | 2600vp 是否白屏 |
|---|---|---|
| 2.0 | 3840 | ✅ 正常 |
| 3.0 | 2560 | ❌ 白屏（2600 > 2560） |
| 3.5 | ≈2194 | ❌ 白屏 |

---

## 5. 相关链接

- 鸿蒙官方：[Web 组件渲染模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-render-mode)
- 鸿蒙官方：[Web 组件 layoutMode 属性](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-attributes#layoutmode11)
