import { SymbolGlyphModifier } from '@kit.ArkUI';
import {
  hdsMaterial,
  HdsTabs,
  HdsTabsBackgroundStyle,
  HdsTabsController,
  HdsTabsFloatingStyle
} from '@kit.UIDesignKit';
import { GlassNavItem } from '../common/GlassNavBridge';

/**
 * 沉浸光感悬浮底栏（官方 HDS 版本）。
 *
 * 走 `@kit.UIDesignKit` 的 `HdsTabs` + `barFloatingStyle.systemMaterialEffect`，
 * 这是官方「沉浸光感」体系里唯一能拿到**材质流光 / 按压弹性形变 / 按压点光源 /
 * 智能反色**的入口（文档入口：最佳实践「沉浸光感」/ UI Design Kit「沉浸光感」）。
 * 手调 `backgroundEffect` 只能得到一层静态模糊，出不来流光。
 *
 * 档位拉到最高：`MaterialType.IMMERSIVE`（沉浸风格）+ `MaterialLevel.EXQUISITE`（最强强度）。
 * 按官方要求先 `getSystemMaterialTypes()` 探测设备能力，不支持 IMMERSIVE 时降级到
 * SMOOTH，否则会出现卡顿与发热。
 *
 * 几何全部用官方 HDS 悬浮页签栏默认值，不自己写尺寸：barHeight 56vp、
 * 4 页签时最大宽 328vp、barSideMargin 16vp。
 */

/** 悬浮页签栏高度（官方默认，设置悬浮样式时为 56vp）。 */
const BAR_HEIGHT: number = 56;
/** 页签栏与屏幕左右边缘的距离（官方宽 <600vp 档的默认值）。 */
const BAR_SIDE_MARGIN: number = 16;
/** 页签栏与屏幕底边的距离。 */
const BAR_BOTTOM_MARGIN: number = 16;

/** 选中态：纯白。 */
const COLOR_ACTIVE: string = '#FFFFFFFF';
/** 未选中态：62% 白。 */
const COLOR_INACTIVE: string = '#9EFFFFFF';
/** 官方 lightColor 深色默认值：让材质流光有一层冷白底色。 */
const LIGHT_COLOR: string = '#33E5E5E5';

/**
 * HdsTabs 容器高度。
 *
 * 这个组件在本项目里只承担「底栏」，内容区是空的（画面由下层 Flutter 提供）。
 * 容器高度 = 页签栏 56 + 底边距 16 + 一点余量，把空内容区压到最小，
 * 避免它在 Flutter 画面上吃掉一块触摸区。
 */
const TABS_HEIGHT: number = BAR_HEIGHT + BAR_BOTTOM_MARGIN + 4;

/**
 * 页签栏宽度。官方 4 项时上限 328vp，会把四个栏目摊得很散
 * （本项目只有四个短标签，留白太多显空），收到 252vp：
 * 每项 63vp，图标与文字都放得下，胶囊依然是官方 HDS 的圆角规格。
 */
const BAR_WIDTH: number = 252;

@Component
export struct GlassNavBar {
  @Prop items: GlassNavItem[] = [];
  @Prop selectedIndex: number = 0;
  onSelect: (index: number) => void = (index: number): void => {
  };

  private controller: HdsTabsController = new HdsTabsController();
  /** 默认最高档：沉浸风格 + 最强强度。 */
  @State materialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;

  aboutToAppear(): void {
    // 官方明文要求：先查设备支持的材质类型再选档位，不支持 IMMERSIVE 必须降级。
    const types: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    if (types.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
      this.materialLevel = hdsMaterial.MaterialLevel.SMOOTH;
    }
  }

  /** $r 是编译期资源，只能写字面量分支，不能拼变量。 */
  private symbolFor(key: string, selected: boolean): Resource {
    if (key === 'popular') {
      return selected ? $r('sys.symbol.flame_fill') : $r('sys.symbol.flame');
    }
    if (key === 'areas') {
      return selected ? $r('sys.symbol.square_fill_grid_2x2') : $r('sys.symbol.square_grid_2x2');
    }
    if (key === 'favorites') {
      return selected ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart');
    }
    if (key === 'record') {
      return selected ? $r('sys.symbol.download_fill') : $r('sys.symbol.download');
    }
    return $r('sys.symbol.dot_grid_2x2');
  }

  /**
   * 页签样式。文字配色只认 `BottomTabBarStyle.labelStyle()`——
   * 不写就永远是系统蓝 #FF007DFF，主题 token 改不动它。
   * 图标走 `TabBarSymbol`，两者各管一段。
   */
  private tabStyle(item: GlassNavItem): BottomTabBarStyle {
    const symbol: TabBarSymbol = {
      normal: new SymbolGlyphModifier(this.symbolFor(item.key, false))
        .fontColor([COLOR_INACTIVE])
        .fontSize(22),
      selected: new SymbolGlyphModifier(this.symbolFor(item.key, true))
        .fontColor([COLOR_ACTIVE])
        .fontSize(22)
    };
    const style: BottomTabBarStyle = new BottomTabBarStyle(symbol, item.label);
    const label: LabelStyle = {
      selectedColor: COLOR_ACTIVE,
      unselectedColor: COLOR_INACTIVE
    };
    style.labelStyle(label);
    return style;
  }

  /** 蒙层结构保留但置透明：内容要能干净地穿过胶囊。 */
  private maskStyle(): HdsTabsBackgroundStyle {
    return { maskColor: '#00000000' };
  }

  /** 官方最高档：沉浸风格 + 最强强度。 */
  private floatingStyle(): HdsTabsFloatingStyle {
    return {
      barSideMargin: BAR_SIDE_MARGIN,
      barBottomMargin: BAR_BOTTOM_MARGIN,
      adaptToHandedness: true,
      lightColor: LIGHT_COLOR,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: this.materialLevel
      }
    };
  }

  build() {
    HdsTabs({ index: this.selectedIndex, controller: this.controller }) {
      ForEach(this.items, (item: GlassNavItem) => {
        // 内容层永远是空的：画面由下层 Flutter 提供，这里只要页签栏。
        // None 让这块空区域不参与命中测试，触摸继续落到 Flutter 上。
        TabContent() {
          Stack()
            .width('100%')
            .height('100%')
            .hitTestBehavior(HitTestMode.None)
        }
        .tabBar(this.tabStyle(item))
      }, (item: GlassNavItem) => item.key)
    }
    .barPosition(BarPosition.End)
    .vertical(false)
    // 收紧胶囊：官方默认把四个栏目按 328vp 均分，留白太大。
    .barWidth(BAR_WIDTH)
    // 空内容区不需要横滑，关掉后也不会跟 Flutter 的列表手势抢事件。
    .scrollable(false)
    // 官方前置条件：不开就没有背后模糊与叠加，材质完全不出现。
    .barOverlap(true)
    .barBackgroundColor(Color.Transparent)
    .barBackgroundStyle(this.maskStyle())
    .barFloatingStyle(this.floatingStyle())
    .onTabBarClick((index: number) => {
      this.onSelect(index);
    })
    .width('100%')
    .height(TABS_HEIGHT)
  }
}
