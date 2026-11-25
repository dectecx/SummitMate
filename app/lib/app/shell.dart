import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/events/providers.dart';

/// The position of the "揪團" tab, matching the order of the router's branches.
const _eventsIndex = 1;

/// The five top-level tabs. Each keeps its own navigation stack and scroll position.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingApplicationsProvider).value ?? 0;
    Widget badged(IconData icon) => Badge.count(count: pending, isLabelVisible: pending > 0, child: Icon(icon));
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // Tapping the current tab goes back to its first screen.
        onDestinationSelected: (i) {
          if (i == _eventsIndex) ref.invalidate(pendingApplicationsProvider);
          navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.hiking_outlined), selectedIcon: Icon(Icons.hiking), label: '行程'),
          NavigationDestination(icon: badged(Icons.groups_outlined), selectedIcon: badged(Icons.groups), label: '揪團'),
          const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: '地圖'),
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: '探索'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我'),
        ],
      ),
    );
  }
}
