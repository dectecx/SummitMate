import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/events/providers.dart';
import '../shared/animations.dart';
import '../shared/nav_glyph.dart';
import 'nav_bar.dart';
import 'router.dart';

/// The position of the "揪團" tab, matching the order of the router's branches.
const _eventsIndex = 1;

const _firstPages = {Routes.trips, Routes.events, Routes.map, Routes.explore, Routes.me};

/// The five top-level tabs. Each keeps its own navigation stack and scroll position.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell, required this.path});
  final StatefulNavigationShell navigationShell;

  /// Where the person is now.
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingApplicationsProvider).value ?? 0;
    Widget badged(Widget icon) => Badge.count(count: pending, isLabelVisible: pending > 0, child: icon);
    return Scaffold(
      body: navigationShell,
      // On the five first pages the list runs on behind the frosted bar; they leave room for it at their end.
      // Pages opened from them stop above it.
      extendBody: _firstPages.contains(path),
      bottomNavigationBar: AppNavBar(
        selected: navigationShell.currentIndex,
        animate: animationsOn(context, ref),
        // Tapping the current tab goes back to its first screen.
        onSelected: (i) {
          if (i == _eventsIndex) ref.invalidate(pendingApplicationsProvider);
          navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
        },
        items: [
          (icon: const NavGlyphIcon(NavGlyph.trips), label: '行程'),
          (icon: badged(const NavGlyphIcon(NavGlyph.events)), label: '揪團'),
          (icon: const NavGlyphIcon(NavGlyph.map), label: '地圖'),
          (icon: const NavGlyphIcon(NavGlyph.explore), label: '探索'),
          (icon: const NavGlyphIcon(NavGlyph.me), label: '我'),
        ],
      ),
    );
  }
}
