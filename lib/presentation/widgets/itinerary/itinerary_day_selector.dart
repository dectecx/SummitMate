import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../cubits/itinerary/itinerary_cubit.dart';
import '../../cubits/sync/sync_cubit.dart';
import '../../cubits/sync/sync_state.dart';
import '../day_management_dialog.dart';

/// 行程天數選擇器
///
/// 包含天數切換(Scrollable ChoiceChips)、管理天數按鈕、以及同步狀態顯示。
class ItineraryDaySelector extends StatelessWidget {
  /// 天數名稱列表 (如 D1, D2, D3...)
  final List<String> dayNames;

  /// 目前選中的天數
  final String selectedDay;

  /// 手動同步回呼函式
  final VoidCallback onManualSync;

  /// 建構子
  const ItineraryDaySelector({
    super.key,
    required this.dayNames,
    required this.selectedDay,
    required this.onManualSync,
  });

  @override
  Widget build(BuildContext context) {
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 天數選擇器 (可滑動)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dayNames.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) {
                        final dayName = dayNames[index];
                        final isSelected = dayName == selectedDay;
                        return ChoiceChip(
                          label: Text(dayName),
                          selected: isSelected,
                          onSelected: (_) => context.read<ItineraryCubit>().selectDay(dayName),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 管理天數按鈕
              IconButton(
                icon: const Icon(Icons.edit_calendar, size: 20),
                tooltip: '管理天數',
                onPressed: () => showDialog(context: context, builder: (_) => const DayManagementDialog()),
              ),
              const SizedBox(width: 4),
              // 更新時間與按鈕 (置右)
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onManualSync,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        if (isSyncing)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        else
                          Icon(Icons.sync, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
