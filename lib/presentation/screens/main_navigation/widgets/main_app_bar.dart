import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/role_constants.dart';
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
    return AppBar(
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
                final color = isOwner ? Colors.orange : Colors.blueGrey;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color, // Solid color for better contrast
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
          if (isOffline) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('離線', style: TextStyle(fontSize: 11, color: Colors.white)),
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
