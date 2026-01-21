import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/presentation/cubits/sync/sync_cubit.dart';

class CloudUploadHelper {
  static Future<void> handleCloudUpload(BuildContext context) async {
    // 檢查離線模式
    final state = context.read<SettingsCubit>().state;
    final settingsIsOffline = state is SettingsLoaded && state.isOfflineMode;
    if (settingsIsOffline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 目前為離線模式，無法上傳行程'), backgroundColor: Colors.orange));
      return;
    }

    // 1. 顯示檢查中 Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. 檢查衝突 (Use SyncCubit)
    final hasConflict = await context.read<SyncCubit>().checkItineraryConflict();

    if (!context.mounted) return;
    Navigator.pop(context); // 關閉 Loading

    if (hasConflict) {
      // 3. 有衝突，顯示警告
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ 雲端資料衝突'),
          content: const Text(
            '雲端上的行程資料與您目前的版本不同。\n\n'
            '若選擇「強制覆蓋」，雲端的資料將被您的版本完全取代。\n'
            '確定要繼續嗎？',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // 關閉 Dialog
                context.read<SyncCubit>().uploadItinerary(); // 執行上傳
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('強制覆蓋'),
            ),
          ],
        ),
      );
    } else {
      // 4. 無衝突，直接確認上傳
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
}
