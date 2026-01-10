import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../infrastructure/tools/toast_service.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/itinerary/itinerary_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'itinerary_edit_dialog.dart';

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

  Future<void> _autoSync() async {
    final context = this.context;
    if (!context.mounted) return;

    // 檢查離線模式
    final settingsState = context.read<SettingsCubit>().state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
    if (isOffline) return;

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
    context.read<SyncCubit>().syncAll();
  }

  Future<void> _manualSync(BuildContext context) async {
    context.read<SyncCubit>().syncAll(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryCubit, ItineraryState>(
      builder: (context, state) {
        return BlocBuilder<SyncCubit, SyncState>(
          builder: (context, syncState) {
            DateTime? lastSync;
            bool isSyncing = false;

            if (syncState is SyncInitial) {
              lastSync = syncState.lastSyncTime;
            } else if (syncState is SyncSuccess) {
              lastSync = syncState.timestamp;
            } else if (syncState is SyncInProgress) {
              isSyncing = true;
            } else if (syncState is SyncFailure) {
              lastSync = syncState.lastSuccessTime;
            }

            final timeStr = lastSync != null ? DateFormat('MM/dd HH:mm').format(lastSync.toLocal()) : '尚未同步';

            // Cubit Logic
            bool isLoading = state is ItineraryLoading;
            List items = [];
            String selectedDay = 'D1';
            bool isEditMode = false;

            if (state is ItineraryLoaded) {
              items = state.items;
              selectedDay = state.selectedDay;
              isEditMode = state.isEditMode;
            }

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            Widget content;
            if (items.isEmpty && state is! ItineraryLoading) {
              content = CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.schedule, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('尚無行程資料'),
                        Text('請下拉刷新以同步行程'),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Prepare specific day items
              final currentDayItems = (state is ItineraryLoaded) ? state.currentDayItems : [];

              content = Column(
                children: [
                  // 天數切換與狀態列
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 天數選擇器
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'D0', label: Text('D0')),
                              ButtonSegment(value: 'D1', label: Text('D1')),
                              ButtonSegment(value: 'D2', label: Text('D2')),
                            ],
                            selected: {selectedDay},
                            onSelectionChanged: (selected) {
                              context.read<ItineraryCubit>().selectDay(selected.first);
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding: WidgetStateProperty.all(EdgeInsets.zero),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: WidgetStateProperty.all(const BorderSide(color: Colors.grey, width: 0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 更新時間與按鈕 (置右)
                        Material(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _manualSync(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(width: 4),
                                  if (isSyncing)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    const Icon(Icons.sync, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 行程列表
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80), // 避免被 FAB 遮擋
                      itemCount: currentDayItems.length,
                      itemBuilder: (context, index) {
                        final item = currentDayItems[index];
                        // 計算累積距離
                        double cumulativeDistance = 0;
                        for (int i = 0; i <= index; i++) {
                          cumulativeDistance += currentDayItems[i].distance;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isCheckedIn ? Colors.green : Theme.of(context).colorScheme.primary,
                              child: item.isCheckedIn
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.isCheckedIn
                                      ? '✓ 打卡: ${item.actualTime?.hour.toString().padLeft(2, '0')}:${item.actualTime?.minute.toString().padLeft(2, '0')}'
                                      : '預計: ${item.estTime}',
                                  style: TextStyle(color: item.isCheckedIn ? Colors.green : null),
                                ),
                                Text(
                                  '海拔 ${item.altitude}m  |  累計 ${cumulativeDistance.toStringAsFixed(1)} km',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isEditMode
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, item.key),
                                  )
                                : (item.note.isNotEmpty ? const Icon(Icons.info_outline, size: 20) : null),
                            onTap: () {
                              if (isEditMode) {
                                _showEditDialog(context, item, selectedDay);
                              } else {
                                _showCheckInDialog(context, item);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return RefreshIndicator(onRefresh: () => _manualSync(context), child: content);
          },
        );
      },
    );
  }

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
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
