import 'package:remixicon/remixicon.dart';
import 'package:pure_live/core/index.dart';
import 'package:pure_live/app/router/navigation_observer.dart';
import 'package:pure_live/core/consts/app_consts.dart';
import 'package:pure_live/core/platform/glass_nav_bar.dart';

/// 手机端首页外壳。
///
/// 鸿蒙上底栏交给原生 ArkTS（`uiMaterial.ImmersiveMaterial` 沉浸光感悬浮胶囊），
/// Flutter 只渲染页面主体，并给底栏留出让位高度；其它平台仍用 Material 的
/// [NavigationBar]，行为保持不变。
class HomeMobileView extends StatefulWidget {
  final Widget body;
  final int index;
  final void Function(int) onDestinationSelected;

  const HomeMobileView({
    super.key,
    required this.body,
    required this.index,
    required this.onDestinationSelected,
  });

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView> {
  /// 下推给原生底栏的栏目顺序 → [HomeMenu.index]，用于把点击换算回真实页签。
  List<int> _realIndexes = const <int>[];

  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (GlassNavBar.isSupported) {
      GlassNavBar.onSelected = _onNativeSelected;
      LiveRouteObserver.homeCovered.addListener(_syncVisibility);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncVisibility());
    }
  }

  @override
  void dispose() {
    if (GlassNavBar.isSupported) {
      LiveRouteObserver.homeCovered.removeListener(_syncVisibility);
      GlassNavBar.onSelected = null;
      GlassNavBar.setVisible(false);
    }
    super.dispose();
  }

  void _syncVisibility() {
    if (!mounted || !GlassNavBar.isSupported) return;
    final bool visible = !LiveRouteObserver.homeCovered.value;
    if (visible == _visible) return;
    _visible = visible;
    GlassNavBar.setVisible(visible);
  }

  void _onNativeSelected(int virtualIndex) {
    if (virtualIndex < 0 || virtualIndex >= _realIndexes.length) return;
    widget.onDestinationSelected(_realIndexes[virtualIndex]);
  }

  String _labelOf(HomeMenu menu) {
    switch (menu) {
      case HomeMenu.favorites:
        return i18n('favorites_title');
      case HomeMenu.popular:
        return i18n('popular_title');
      case HomeMenu.areas:
        return i18n('areas_title');
      case HomeMenu.record:
        return i18n('record_center');
    }
  }

  Widget _buildMaterialBar() {
    return Obx(() {
      final List<NavigationDestination> destinations = [];
      final List<int> virtualToRealMap = [];
      final activeMenuIds = SettingsService.to.app.savedMenuIds.v;
      for (String id in activeMenuIds) {
        final menu = HomeMenu.fromId(id);
        if (menu != null) {
          virtualToRealMap.add(menu.index);
          switch (menu) {
            case HomeMenu.favorites:
              destinations.add(
                NavigationDestination(
                  icon: const Icon(Remix.heart_3_line),
                  selectedIcon: const Icon(Remix.heart_3_fill),
                  label: _labelOf(menu),
                ),
              );
              break;
            case HomeMenu.popular:
              destinations.add(
                NavigationDestination(
                  icon: const Icon(Remix.fire_line),
                  selectedIcon: const Icon(Remix.fire_fill),
                  label: _labelOf(menu),
                ),
              );
              break;
            case HomeMenu.areas:
              destinations.add(
                NavigationDestination(
                  icon: const Icon(Remix.apps_2_line),
                  selectedIcon: const Icon(Remix.apps_2_fill),
                  label: _labelOf(menu),
                ),
              );
              break;
            case HomeMenu.record:
              destinations.add(
                NavigationDestination(
                  icon: const Icon(Remix.download_2_line),
                  selectedIcon: const Icon(Remix.download_2_fill),
                  label: _labelOf(menu),
                ),
              );
              break;
          }
        }
      }
      if (destinations.length <= 1) return const SizedBox.shrink();
      int activeSelectedIndex = virtualToRealMap.indexOf(widget.index);
      if (activeSelectedIndex == -1) {
        activeSelectedIndex = 0;
      }
      return NavigationBar(
        destinations: destinations,
        selectedIndex: activeSelectedIndex,
        onDestinationSelected: (int virtualIndex) {
          if (virtualIndex < virtualToRealMap.length) {
            widget.onDestinationSelected(virtualToRealMap[virtualIndex]);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!GlassNavBar.isSupported) {
      return Scaffold(
        bottomNavigationBar: _buildMaterialBar(),
        body: widget.body,
      );
    }

    return Obx(() {
      final List<GlassNavItem> items = <GlassNavItem>[];
      final List<int> realIndexes = <int>[];
      for (String id in SettingsService.to.app.savedMenuIds.v) {
        final menu = HomeMenu.fromId(id);
        if (menu == null) continue;
        realIndexes.add(menu.index);
        items.add(GlassNavItem(key: menu.id, label: _labelOf(menu)));
      }
      _realIndexes = realIndexes;

      int selected = realIndexes.indexOf(widget.index);
      if (selected == -1) selected = 0;

      final bool visible = _visible && items.length > 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        GlassNavBar.configure(items: items, selectedIndex: selected, visible: visible);
      });

      // 不做整体让位：内容要能滚到胶囊底下，玻璃才有东西可折射。
      // 各列表自己在末尾多留 GlassNavBar.contentInset，最后一行不会被压住。
      return Scaffold(body: widget.body);
    });
  }
}
