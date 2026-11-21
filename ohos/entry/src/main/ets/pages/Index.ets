
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos'
import { GlassNavBar } from '../components/GlassNavBar';
import { GlassNavBridge, GlassNavItem } from '../common/GlassNavBridge';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";
  /** 栏目清单 / 选中项 / 显隐，全部由 Flutter 通过 MethodChannel 下推。 */
  @StorageLink('glassNavItems') navItems: GlassNavItem[] = [];
  @StorageLink('glassNavSelected') navSelected: number = 0;
  @StorageLink('glassNavVisible') navVisible: boolean = false;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 必须用 TEXTURE 合成：SURFACE 型 XComponent 是独立原生图层，
        // 一旦 Flutter 侧发生重新布局（例如切页签）就会盖到 ArkUI 之上，
        // 悬浮底栏被吃掉。TEXTURE 走 ArkUI 的渲染树，层序稳定。
        FlutterPage({ viewId: this.viewId, xComponentType: XComponentType.TEXTURE })
      }
      .width('100%')
      .height('100%')

      // 原生沉浸光感底栏浮在 Flutter 画面之上；少于两个栏目时（例如用户只留一项）
      // 保持原有全屏观感，不显示底栏。
      if (this.navVisible && this.navItems.length > 1) {
        GlassNavBar({
          items: this.navItems,
          selectedIndex: this.navSelected,
          onSelect: (index: number): void => {
            GlassNavBridge.getInstance().select(index);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
