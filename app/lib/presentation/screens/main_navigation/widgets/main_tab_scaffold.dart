import 'package:flutter/material.dart';
import 'package:summitmate/domain/domain.dart';

import '../../../widgets/app_drawer.dart';
import '../../../widgets/app_drawer_content.dart';
import '../../../widgets/ads/banner_ad_widget.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/common/offline_status_banner.dart';
import '../../../widgets/trip/cloud_sync_bar.dart';
import 'main_app_bar.dart';
import 'main_bottom_nav_bar.dart';

/// 有行程時的主 Scaffold（包含底部導覽、TabBar、FAB）
///
/// 負責 mobile / tablet / desktop 三種佈局的響應式切換。
class MainTabScaffold extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Trip? activeTrip;
  final bool isLoading;
  final int currentIndex;
  final bool isEditMode;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onEditToggle;
  final VoidCallback onUpload;
  final VoidCallback onMap;
  final VoidCallback onSettings;
  final VoidCallback onAddItinerary;
  final Widget Function(int index) buildTabContent;

  const MainTabScaffold({
    super.key,
    required this.scaffoldKey,
    required this.activeTrip,
    required this.isLoading,
    required this.currentIndex,
    required this.isEditMode,
    required this.onTabChanged,
    required this.onEditToggle,
    required this.onUpload,
    required this.onMap,
    required this.onSettings,
    required this.onAddItinerary,
    required this.buildTabContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: ResponsiveLayout.isDesktop(context) ? null : const AppDrawer(),
      drawerEnableOpenDragGesture: !ResponsiveLayout.isDesktop(context),
      appBar: MainAppBar(
        activeTrip: activeTrip,
        isLoading: isLoading,
        currentIndex: currentIndex,
        isEditMode: isEditMode,
        showLeading: !ResponsiveLayout.isDesktop(context),
        onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
        onEditToggle: onEditToggle,
        onUpload: onUpload,
        onMap: onMap,
        onSettings: onSettings,
      ),
      body: ResponsiveLayout(
        mobile: _MobileBody(currentIndex: currentIndex, buildTabContent: buildTabContent),
        desktop: _DesktopBody(
          currentIndex: currentIndex,
          onTabChanged: onTabChanged,
          buildTabContent: buildTabContent,
        ),
        tablet: _TabletBody(
          scaffoldKey: scaffoldKey,
          currentIndex: currentIndex,
          onTabChanged: onTabChanged,
          buildTabContent: buildTabContent,
        ),
      ),
      bottomNavigationBar: ResponsiveLayout(
        mobile: MainBottomNavigationBar(
          currentIndex: currentIndex,
          onDestinationSelected: onTabChanged,
        ),
        desktop: const SizedBox.shrink(),
      ),
      floatingActionButton: (currentIndex == 0 && isEditMode)
          ? FloatingActionButton(
              onPressed: onAddItinerary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _MobileBody extends StatelessWidget {
  final int currentIndex;
  final Widget Function(int) buildTabContent;

  const _MobileBody({required this.currentIndex, required this.buildTabContent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineStatusBanner(),
        const CloudSyncBanner(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: buildTabContent(currentIndex),
          ),
        ),
        const BannerAdWidget(location: 'navigation_bottom'),
      ],
    );
  }
}

class _DesktopBody extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final Widget Function(int) buildTabContent;

  const _DesktopBody({
    required this.currentIndex,
    required this.onTabChanged,
    required this.buildTabContent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppDrawerContent(
          isSidebar: true,
          currentIndex: currentIndex,
          onTabSelected: onTabChanged,
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            children: [
              const OfflineStatusBanner(),
              const CloudSyncBanner(),
              Expanded(child: buildTabContent(currentIndex)),
              const BannerAdWidget(location: 'navigation_bottom'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabletBody extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final Widget Function(int) buildTabContent;

  const _TabletBody({
    required this.scaffoldKey,
    required this.currentIndex,
    required this.onTabChanged,
    required this.buildTabContent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onTabChanged,
          labelType: NavigationRailLabelType.all,
          leading: Column(
            children: [
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
                tooltip: '選單',
              ),
              const SizedBox(height: 20),
            ],
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.hiking),
              selectedIcon: Icon(Icons.hiking),
              label: Text('行程'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.backpack_outlined),
              selectedIcon: Icon(Icons.backpack),
              label: Text('裝備'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: Text('揪團/訊息'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: Text('資訊'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            children: [
              const OfflineStatusBanner(),
              const CloudSyncBanner(),
              Expanded(child: buildTabContent(currentIndex)),
              const BannerAdWidget(location: 'navigation_bottom'),
            ],
          ),
        ),
      ],
    );
  }
}
