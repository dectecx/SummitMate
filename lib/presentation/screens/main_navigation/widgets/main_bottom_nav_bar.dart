import 'package:flutter/material.dart';
import '../../../utils/tutorial_keys.dart';

class MainBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const MainBottomNavigationBar({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          key: TutorialKeys.tabItinerary,
          icon: const Icon(Icons.schedule),
          selectedIcon: const Icon(Icons.schedule),
          label: '行程',
        ),
        NavigationDestination(
          key: TutorialKeys.tabGear,
          icon: const Icon(Icons.backpack_outlined),
          selectedIcon: const Icon(Icons.backpack),
          label: '裝備',
        ),
        NavigationDestination(
          key: TutorialKeys.tabMessage,
          icon: const Icon(Icons.forum_outlined),
          selectedIcon: const Icon(Icons.forum),
          label: '互動',
        ),
        NavigationDestination(
          key: TutorialKeys.tabInfo,
          icon: const Icon(Icons.info_outline),
          selectedIcon: const Icon(Icons.info),
          label: '資訊',
        ),
      ],
    );
  }
}
