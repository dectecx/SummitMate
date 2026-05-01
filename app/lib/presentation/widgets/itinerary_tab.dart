import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../domain/entities/itinerary_item.dart';
import '../cubits/sync/sync_cubit.dart';
import '../cubits/sync/sync_state.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/itinerary/itinerary_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import 'itinerary_edit_dialog.dart';
import 'itinerary/itinerary_day_selector.dart';
import 'itinerary/itinerary_list_view.dart';
import 'itinerary/itinerary_day_side_selector.dart';
import '../screens/group_event_detail_screen.dart';
import '../cubits/group_event/group_event_cubit.dart';
import 'responsive_layout.dart';

/// Tab 1: 行程頁
class ItineraryTab extends StatefulWidget {
  const ItineraryTab({super.key});

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSync();
    });
  }

  /// 自動同步
  Future<void> _autoSync() async {
    if (!mounted) return;
    final cubit = context.read<SyncCubit>();
    final settingsCubit = context.read<SettingsCubit>();

    final settingsState = settingsCubit.state;
    final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
    if (isOffline) return;

    if (!mounted) return;

    final syncState = context.read<SyncCubit>().state;
    DateTime? lastSyncTime;
    if (syncState is SyncInitial) lastSyncTime = syncState.lastSyncTime;
    if (syncState is SyncSuccess) lastSyncTime = syncState.timestamp;

    if (lastSyncTime == null) return;

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

            Widget content = BlocBuilder<TripCubit, TripState>(
              builder: (context, tripState) {
                final activeTrip = tripState is TripLoaded ? tripState.activeTrip : null;
                final linkedEventId = activeTrip?.linkedEventId;

                Widget buildSharedBanner() {
                  if (linkedEventId == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '此行程已分享至揪團活動',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final eventId = linkedEventId;
                            final groupEventCubit = context.read<GroupEventCubit>();

                            final event = await groupEventCubit.getEventById(eventId);
                            if (event != null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => GroupEventDetailScreen(event: event)),
                              );
                            } else if (context.mounted) {
                              ToastService.error('無法取得揪團活動資訊');
                            }
                          },
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: const Text('查看活動', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                  );
                }

                return ResponsiveLayout(
                  mobile: Column(
                    children: [
                      buildSharedBanner(),
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
                  ),
                  desktop: Row(
                    children: [
                      if (dayNames.isNotEmpty)
                        SizedBox(
                          width: 280,
                          child: ItineraryDaySideSelector(dayNames: dayNames, selectedDay: selectedDay),
                        ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Column(
                          children: [
                            buildSharedBanner(),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 800),
                                  child: ItineraryListView(
                                    items: items,
                                    selectedDay: selectedDay,
                                    isEditMode: isEditMode,
                                    onConfirmDelete: _confirmDelete,
                                    onShowEditDialog: (ctx, item, day) => _showEditDialog(ctx, item, day),
                                    onShowCheckInDialog: (ctx, item) => _showCheckInDialog(ctx, item),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );

            return RefreshIndicator(onRefresh: () => _manualSync(context), child: content);
          },
        );
      },
    );
  }

  /// 確認並刪除行程節點
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除行程'),
        content: const Text('確定要刪除此行程節點嗎？此動作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<ItineraryCubit>().deleteItem(id);
              Navigator.pop(context);
            },
            child: Text('刪除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  /// 顯示編輯行程節點對話框
  void _showEditDialog(BuildContext context, ItineraryItem item, String currentDay) async {
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
        updatedAt: DateTime.now(),
      );

      context.read<ItineraryCubit>().updateItem(updatedItem);
    }
  }

  /// 顯示打卡對話框
  void _showCheckInDialog(BuildContext context, ItineraryItem item) {
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
              title: Text(item.isCheckedIn ? '取消打卡' : '現在時間打卡'),
              onTap: () {
                context.read<ItineraryCubit>().checkIn(item.id);
                ToastService.success(item.isCheckedIn ? '已取消打卡' : '已打卡：${item.name}');
                Navigator.pop(context);
              },
            ),
            if (!item.isCheckedIn)
              ListTile(
                leading: const Icon(Icons.edit_calendar),
                title: const Text('指定時間'),
                onTap: () async {
                  Navigator.pop(context);
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    if (context.mounted) {
                      final now = DateTime.now();
                      final checkInTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                      context.read<ItineraryCubit>().checkInWithTime(item.id, checkInTime);
                      ToastService.success('已打卡：${item.name}');
                    }
                  }
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
