import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/core.dart';
import '../../../cubits/settings/settings_cubit.dart';
import '../../../cubits/settings/settings_state.dart';
import '../../../cubits/auth/auth_cubit.dart';
import '../../../cubits/auth/auth_state.dart';
import '../../../../data/models/trip.dart';
import '../../../utils/tutorial_keys.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Trip? activeTrip;
  final bool isOffline;
  final bool isLoading;
  final int currentIndex;
  final bool isEditMode;
  final VoidCallback onMenuPressed;
  final VoidCallback onEditToggle;
  final VoidCallback onUpload;
  final VoidCallback onMap;
  final VoidCallback onSettings;

  const MainAppBar({
    super.key,
    required this.activeTrip,
    required this.isOffline,
    required this.isLoading,
    required this.currentIndex,
    required this.isEditMode,
    required this.onMenuPressed,
    required this.onEditToggle,
    required this.onUpload,
    required this.onMap,
    required this.onSettings,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (isLoading ? 4.0 : 0.0));

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final themeType = settingsState is SettingsLoaded ? settingsState.settings.theme : AppThemeType.nature;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor, // Fallback
          gradient: AppTheme.getStrategy(themeType).appBarGradient,
        ),
      ),
      leading: IconButton(
        key: TutorialKeys.mainDrawerMenu,
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
        tooltip: '選單',
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(activeTrip?.name ?? 'SummitMate 山友', overflow: TextOverflow.ellipsis)),
          if (activeTrip != null) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                // Determine Role
                final authState = context.read<AuthCubit>().state;
                final userId = (authState is AuthAuthenticated) ? authState.userId : '';
                final isOwner = activeTrip!.userId == userId;
                final roleLabel = isOwner
                    ? RoleConstants.displayName[RoleConstants.leader] ?? 'Leader'
                    : RoleConstants.displayName[RoleConstants.member] ?? 'Member';

                // Use Theme Colors for Role Badge
                final color = isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary;
                final onColor = isOwner
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSecondary;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: onColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(fontSize: 11, color: onColor, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
          if (isOffline) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error, // Use error color for offline warning
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 12, color: Theme.of(context).colorScheme.onError),
                  const SizedBox(width: 4),
                  Text('離線', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onError)),
                ],
              ),
            ),
          ],
        ],
      ),
      bottom: isLoading
          ? const PreferredSize(preferredSize: Size.fromHeight(4.0), child: LinearProgressIndicator())
          : null,
      actions: [
        // Tab 0: 行程編輯與地圖 (僅在有行程時顯示)
        if (currentIndex == 0) ...[
          IconButton(
            icon: Icon(isEditMode ? Icons.check : Icons.edit),
            tooltip: isEditMode ? '完成' : '編輯行程',
            onPressed: onEditToggle,
          ),
          if (isEditMode)
            IconButton(icon: const Icon(Icons.cloud_upload_outlined), tooltip: '上傳至雲端', onPressed: onUpload),
          if (!isEditMode) ...[IconButton(icon: const Icon(Icons.map_outlined), tooltip: '查看地圖', onPressed: onMap)],
        ],
        // 設定按鈕
        IconButton(
          key: TutorialKeys.mainSettings,
          icon: const Icon(Icons.settings),
          onPressed: onSettings,
          tooltip: '設定',
        ),
      ],
    );
  }
}
