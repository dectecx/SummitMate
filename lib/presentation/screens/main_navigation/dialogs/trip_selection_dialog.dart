import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/core.dart';
import '../../../../data/models/trip.dart';
import '../../../cubits/sync/sync_cubit.dart';
import '../../../cubits/trip/trip_cubit.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

class TripSelectionDialog {
  static Future<void> show(BuildContext context) async {
    final tripCubit = context.read<TripCubit>();

    // 1. 顯示 Loading 並取得 Trip List
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await tripCubit.getCloudTrips();
    if (!context.mounted) return;
    Navigator.pop(context); // Close Loading

    if (result is Failure) {
      ToastService.error((result as Failure).exception.toString());
      return;
    }

    final cloudTrips = (result as Success<List<Trip>, Exception>).value;
    if (cloudTrips.isEmpty) {
      ToastService.info('雲端目前沒有行程資料');
      return;
    }

    // 2. 顯示選擇列表
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('選擇要匯入的行程'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cloudTrips.length,
              itemBuilder: (itemContext, index) {
                final trip = cloudTrips[index];
                return ListTile(
                  leading: const Icon(Icons.map),
                  title: Text(trip.name),
                  subtitle: Text(trip.startDate.toIso8601String().split('T').first),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    // 使用最外層穩定的 context (passed from show)
                    _importAndSwitchTrip(context, trip);
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消'))],
        ),
      );
    }
  }

  static Future<void> _importAndSwitchTrip(BuildContext context, Trip cloudTrip) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tripCubit = context.read<TripCubit>();

      // 1. 新增/更新 Trip Meta 到本地
      // 先檢查本地是否已有此 ID
      final existing = await tripCubit.getTripById(cloudTrip.id);
      if (existing != null) {
        await tripCubit.updateTrip(cloudTrip);
      } else {
        await tripCubit.importTrip(cloudTrip);
      }

      // 2. 切換為 Active
      await tripCubit.setActiveTrip(cloudTrip.id);

      // 3. 觸發 Sync (下載該 Trip 的 itinerary/messages)
      // 使用 SyncCubit 統一執行同步
      if (!context.mounted) return;
      await context.read<SyncCubit>().syncAll(force: true);

      if (context.mounted) {
        Navigator.pop(context); // Close Loading
      }
      ToastService.success('行程匯入成功');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ToastService.error('匯入失敗: $e');
    }
  }
}
