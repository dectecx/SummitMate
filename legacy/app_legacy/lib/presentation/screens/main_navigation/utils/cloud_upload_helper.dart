import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';

class CloudUploadHelper {
  static Future<void> handleCloudUpload(BuildContext context) async {
    // 檢查行程編輯權限
    final authState = context.read<AuthCubit>().state;
    final user = (authState is AuthAuthenticated) ? authState.user : null;
    final tripState = context.read<TripCubit>().state;
    final activeTrip = (tripState is TripLoaded) ? tripState.activeTrip : null;
    if (activeTrip != null) {
      final permissionService = getIt<PermissionService>();
      if (!permissionService.canEditTripSync(user, activeTrip)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('⚠️ 您沒有權限上傳或修改此行程'), backgroundColor: Colors.red));
        return;
      }
    }

    // 檢查離線模式
    final state = context.read<SettingsCubit>().state;
    final settingsIsOffline = state is SettingsLoaded && state.isOfflineMode;
    if (settingsIsOffline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 目前為離線模式，無法上傳行程'), backgroundColor: Colors.orange));
      return;
    }

    // 確認後上傳
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上傳行程'),
        content: const Text('確定將目前的行程計畫上傳至雲端嗎？此操作將覆寫雲端資料。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SyncCubit>().uploadItinerary();
            },
            child: const Text('上傳'),
          ),
        ],
      ),
    );
  }
}
