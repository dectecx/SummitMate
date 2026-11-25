import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/events/providers.dart';
import '../shared/animations.dart';
import '../shared/land_nav_bar.dart';
import '../shared/nav_glyph.dart';

/// The position of the "揪團" tab, matching the order of the router's branches.
const _eventsIndex = 1;

/// The five top-level tabs. Each keeps its own navigation stack and scroll position.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingApplicationsProvider).value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: LandNavBar(
        selected: navigationShell.currentIndex,
        animate: animationsOn(context, ref),
        // Tapping the current tab goes back to its first screen.
        onSelected: (i) {
          if (i == _eventsIndex) ref.invalidate(pendingApplicationsProvider);
          navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
        },
        destinations: [
          (glyph: NavGlyph.trips, label: '行程', badge: 0),
          (glyph: NavGlyph.events, label: '揪團', badge: pending),
          (glyph: NavGlyph.map, label: '地圖', badge: 0),
          (glyph: NavGlyph.explore, label: '探索', badge: 0),
          (glyph: NavGlyph.me, label: '我', badge: 0),
        ],
      ),
    );
  }
}
