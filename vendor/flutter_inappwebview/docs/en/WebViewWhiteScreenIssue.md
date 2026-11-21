# InAppWebView White Screen Caused by Excessive Content Height

> Target platform: OHOS
> Related components: `InAppWebView` / `OhosWebView`
> Official references: [Web Component Rendering Modes](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-render-mode), [Web Component layoutMode Attribute](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-attributes#layoutmode11)

---

## 1. Symptom

When using `flutter_inappwebview` to load H5 pages on OHOS, a white screen appears once the page content height exceeds approximately **2600vp** (when the device dpr=3).

White screen characteristics:

- The affected area displays nothing;
- **No error, no crash, no log**;
- The threshold varies with `devicePixelRatio` and cannot be hard-coded as a fixed vp value.

---

## 2. Root Cause

`InAppWebView` integrates with Flutter through a PlatformView (`NodeContainer` + `WebNodeController`) via the texture-composition path. A single edge of the ArkUI Surface node's texture has a physical-pixel limit of approximately **7680px** (device/SDK dependent). The texture physical height = Web component logical height × devicePixelRatio.

- **Official basis for the 7680px limit**: This is an officially published HarmonyOS constraint, not a black-box guess. Both [Web Component Rendering Modes](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-render-mode) (async rendering section) and [Web Component layoutMode Attribute](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-attributes#layoutmode11) explicitly state that when the Web component acts as a surface node (async rendering / texture-composition path), its physical-pixel height must not exceed 7,680px, otherwise a white screen will occur.
- When `WebLayoutMode.FIT_CONTENT` is enabled, the Web component auto-sizes its layout to the full content height of the page;
- If the application sets the container height to the full page content height (common when dynamically obtaining `contentHeight` and expanding to it), logical height × dpr will exceed 7680px. The GPU fails to allocate the texture buffer, `NodeContainer` returns an empty texture, the Flutter engine samples empty data, and ultimately renders a white screen.

Threshold: logical height limit ≈ 7680 ÷ dpr (about 2560vp when dpr=3, consistent with observed behavior).

---

## 3. Solutions

### Solution 1: Do Not Enable FIT_CONTENT (Default)

Keep `layoutMode = WebLayoutMode.NONE` (the default). The Web component height is then determined by the parent container constraints and will not expand with content, avoiding the limit at the source. Suitable for scenarios where the WebView height can be fixed by outer constraints.

### Solution 2: Occupy a Full Screen (Recommended, Simplest)

The WebView is not mixed with other Flutter components, and the container height always equals the screen visible height. Screen height × dpr is far below 7680px, which is naturally safe.

> Note: For large-screen / foldable devices, you still need to verify that `screen height × dpr < 7680`.

### Solution 3: Mixed Layout — Decouple "Layout Height" from "Texture Size"

When the WebView must be stacked vertically with other Flutter components and the page content is long:

- **Layout layer**: Use `SizedBox`/`Container` to occupy the full page height, participating in Flutter layout but producing no texture itself (i.e., do not place the WebView in this node);
- **Texture layer**: The `InAppWebView` height is fixed to "viewport + one screen of overscan" (ensure `(viewport + overscan) × dpr < 7680`), and translate this window to follow scrolling via `Positioned.top`;
- **Scroll synchronization**: Listen to Flutter `ScrollController.offset` and call `controller.scrollTo(offset)` to drive the web content scrolling, keeping the visuals continuous.

Cautions:

- Solution 3 must use `layoutMode = NONE`; it is mutually exclusive with `FIT_CONTENT`;
- Scroll synchronization must handle two sets of rendering timing to avoid tearing; it is recommended to drive scrolling from a single source (either Flutter or Web);
- The overscan value should be ≤ one screen and verified against the threshold on the target device;
- Gesture ownership must be clearly defined to avoid scrolling contention between Web and Flutter.

---

## 4. Threshold Quick Reference

| devicePixelRatio | Critical vp (7680 ÷ dpr) | Does 2600vp white-screen? |
|---|---|---|
| 2.0 | 3840 | ✅ Normal |
| 3.0 | 2560 | ❌ White screen (2600 > 2560) |
| 3.5 | ≈2194 | ❌ White screen |

---

## 5. Related Links

- HarmonyOS official: [Web Component Rendering Modes](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-render-mode)
- HarmonyOS official: [Web Component layoutMode Attribute](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-basic-components-web-attributes#layoutmode11)
