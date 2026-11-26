import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/events/providers.dart';
import '../shared/animations.dart';
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
    Widget badged(Widget icon) => Badge.count(count: pending, isLabelVisible: pending > 0, child: icon);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          animationDuration: animationsOn(context, ref) ? null : Duration.zero,
          // Tapping the current tab goes back to its first screen.
          onDestinationSelected: (i) {
            if (i == _eventsIndex) ref.invalidate(pendingApplicationsProvider);
            navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
          },
          destinations: [
            const NavigationDestination(icon: NavGlyphIcon(NavGlyph.trips), label: '行程'),
            NavigationDestination(icon: badged(const NavGlyphIcon(NavGlyph.events)), label: '揪團'),
            const NavigationDestination(icon: NavGlyphIcon(NavGlyph.map), label: '地圖'),
            const NavigationDestination(icon: NavGlyphIcon(NavGlyph.explore), label: '探索'),
            const NavigationDestination(icon: NavGlyphIcon(NavGlyph.me), label: '我'),
          ],
        ),
      ),
    );
  }
}
