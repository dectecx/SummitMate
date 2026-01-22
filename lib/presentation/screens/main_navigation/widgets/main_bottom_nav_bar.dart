import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme.dart';
import '../../../cubits/settings/settings_cubit.dart';
import '../../../cubits/settings/settings_state.dart';
import '../../../utils/tutorial_keys.dart';

class MainBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const MainBottomNavigationBar({super.key, required this.currentIndex, required this.onDestinationSelected});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final themeStrategy = AppTheme.getStrategy(
      settingsState is SettingsLoaded ? settingsState.settings.theme : AppThemeType.morandi,
    );

    return Container(
      decoration: BoxDecoration(gradient: themeStrategy.bottomBarGradient),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      ),
    );
  }
}
