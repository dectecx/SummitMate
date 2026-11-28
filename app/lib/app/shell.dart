import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/events/providers.dart';
import '../shared/animations.dart';
import '../shared/nav_glyph.dart';
import 'nav_bar.dart';

/// The position of the "揪團" tab, matching the order of the router's branches.
const _eventsIndex = 1;

/// The five top-level tabs. Each keeps its own navigation stack and scroll position.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingApplicationsProvider).value ?? 0;
    Widget badged(Widget icon) => Badge.count(count: pending, isLabelVisible: pending > 0, child: icon);
    final items = <AppNavItem>[
      (icon: const NavGlyphIcon(NavGlyph.home), label: '首頁'),
      (icon: badged(const NavGlyphIcon(NavGlyph.events)), label: '揪團'),
      (icon: const NavGlyphIcon(NavGlyph.map), label: '地圖'),
      (icon: const NavGlyphIcon(NavGlyph.explore), label: '探索'),
      (icon: const NavGlyphIcon(NavGlyph.me), label: '我'),
    ];
    // Tapping the current tab goes back to its first screen.
    void select(int i) {
      if (i == _eventsIndex) ref.invalidate(pendingApplicationsProvider);
      navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
    }

    return Scaffold(
      // Every page runs on behind the floating bar. Its height reaches them as bottom padding, which their lists
      // leave free at the end; floating buttons and sheets pinned to the bottom rest above it.
      extendBody: true,
      body: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(viewPadding: media.viewPadding.copyWith(bottom: math.max(media.viewPadding.bottom, media.padding.bottom))),
            child: navigationShell,
          );
        },
      ),
      bottomNavigationBar: AppNavBar(items: items, selected: navigationShell.currentIndex, onSelected: select, animate: animationsOn(context, ref)),
    );
  }
}
