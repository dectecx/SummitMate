import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/data/data.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/itinerary/itinerary_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'itinerary_edit_dialog.dart';
import 'itinerary/itinerary_day_selector.dart';
import 'itinerary/itinerary_list_view.dart';

/// Tab 1: 行程頁
class ItineraryTab extends StatefulWidget {
  const ItineraryTab({super.key});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  // 加上自動同步冷卻檢查 (於 initState 觸發)
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSync();
    });
  }

  /// 自動同步 (冷卻檢查由 Cubit 處理)
  Future<void> _autoSync() async {
    if (!mounted) return;
    final cubit = context.read<SyncCubit>();
    final settingsCubit = context.read<SettingsCubit>();

    final settingsState = settingsCubit.state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
    if (isOffline) return;

    if (!mounted) return;

    // 首次載入 (尚未同步過) 時，不觸發自動同步
    // Use SyncCubit state to check lastSyncTime
    final syncState = context.read<SyncCubit>().state;
    // Assuming SyncInitial means never synced, or we check if we have data.
    // If logic was 'lastSyncTime == null' don't sync... wait.
    // If lastSyncTime is null, it usually MEANS we haven't synced.
    // The original logic `if (settingsInfo.lastSyncTime == null) return;` suggests:
    // "If we haven't synced before (or it's null), DON'T auto-sync." -> This sounds like avoiding overwriting local with empty remote on first launch?
    // Or maybe it means "If we strictly have no record of sync, don't auto sync blindly".
    // However, usually we WANT to sync on startup if we have a token.
    // Let's replicate strict logic:
    // If SyncCubit doesn't expose lastSyncTime easily in Initial state (it does via property often), use it.
    // SyncInitial has lastSyncTime property.
    DateTime? lastSyncTime;
    if (syncState is SyncInitial) lastSyncTime = syncState.lastSyncTime;
    if (syncState is SyncSuccess) lastSyncTime = syncState.timestamp;

    // If we can't find it, assume null.
    if (lastSyncTime == null) return;

    // 使用 SyncCubit 進行自動同步
    cubit.syncAll();
  }

  /// 手動觸發同步
  Future<void> _manualSync(BuildContext context) async {
    context.read<SyncCubit>().syncAll(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        return BlocBuilder<SyncCubit, SyncState>(
          builder: (context, syncState) {
            // Cubit Logic
            bool isLoading = state is ItineraryLoading;
            List<ItineraryItem> items = [];
            String selectedDay = 'D1';
            bool isEditMode = false;

            if (state is ItineraryLoaded) {
              items = state.currentDayItems;
              selectedDay = state.selectedDay;
              isEditMode = state.isEditMode;
            }

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final dayNames = state is ItineraryLoaded ? state.dayNames : <String>[];

            Widget content = Column(
              children: [
                if (dayNames.isNotEmpty)
                  ItineraryDaySelector(
                    dayNames: dayNames,
                    selectedDay: selectedDay,
                    onManualSync: () => _manualSync(context),
                  ),

                Expanded(
                  child: ItineraryListView(
                    items: items,
                    selectedDay: selectedDay,
                    isEditMode: isEditMode,
                    onConfirmDelete: _confirmDelete,
                    onShowEditDialog: (ctx, item, day) => _showEditDialog(ctx, item, day),
                    onShowCheckInDialog: (ctx, item) => _showCheckInDialog(ctx, item),
                  ),
                ),
              ],
            );

            return RefreshIndicator(onRefresh: () => _manualSync(context), child: content);
          },
        );
      },
    );
  }

  /// 確認並刪除行程節點
  void _confirmDelete(BuildContext context, dynamic key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除行程'),
        content: const Text('確定要刪除此行程節點嗎？此動作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<ItineraryCubit>().deleteItem(key);
              Navigator.pop(context);
            },
            child: Text('刪除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  /// 顯示編輯行程節點對話框
  void _showEditDialog(BuildContext context, dynamic item, String currentDay) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ItineraryEditDialog(item: item, defaultDay: currentDay),
    );

    if (result != null && context.mounted) {
      final updatedItem = item.copyWith(
        name: result['name'],
        estTime: result['estTime'],
        altitude: result['altitude'],
        distance: result['distance'],
        note: result['note'],
      );

      context.read<ItineraryCubit>().updateItem(item.key, updatedItem);
    }
  }

  /// 顯示打卡對話框
  void _showCheckInDialog(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.terrain, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.schedule, label: '預計 ${item.estTime}'),
                _InfoChip(icon: Icons.landscape, label: '海拔 ${item.altitude}m'),
                _InfoChip(icon: Icons.straighten, label: '距離 ${item.distance} km'),
              ],
            ),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(item.note, style: const TextStyle(fontSize: 14)),
              ),
            ],
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('現在時間打卡'),
              onTap: () {
                context.read<ItineraryCubit>().checkIn(item.key);
                ToastService.success('已打卡：${item.name}');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('指定時間'),
              onTap: () async {
                Navigator.pop(context);
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) {
                  if (context.mounted) {
                    final now = DateTime.now();
                    context.read<ItineraryCubit>().checkIn(
                      item.key,
                      time: DateTime(now.year, now.month, now.day, time.hour, time.minute),
                    );
                    ToastService.success('已打卡：${item.name}');
                  }
                }
              },
            ),
            if (item.isCheckedIn)
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('清除打卡'),
                onTap: () {
                  context.read<ItineraryCubit>().clearCheckIn(item.key);
                  ToastService.info('已清除打卡');
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label), visualDensity: VisualDensity.compact);
  }
}
