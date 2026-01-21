import 'package:flutter/material.dart';
import 'package:summitmate/data/data.dart';

/// 行程列表視圖
///
/// 顯示特定天數的行程節點列表，支援查看與編輯模式。
class ItineraryListView extends StatelessWidget {
  /// 行程節點列表
  final List<ItineraryItem> items;

  /// 目前選中的天數
  final String selectedDay;

  /// 是否處於編輯模式
  final bool isEditMode;

  /// 顯示編輯對話框的回呼 (傳入 context, item, currentDay)
  final Function(BuildContext, ItineraryItem, String) onShowEditDialog;

  /// 顯示打卡對話框的回呼 (傳入 context, item)
  final Function(BuildContext, ItineraryItem) onShowCheckInDialog;

  /// 確認刪除的回呼 (傳入 context, itemKey)
  final Function(BuildContext, dynamic) onConfirmDelete; // Key might be string or dynamic

  /// 建構子
  const ItineraryListView({
    super.key,
    required this.items,
    required this.selectedDay,
    required this.isEditMode,
    required this.onShowEditDialog,
    required this.onShowCheckInDialog,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return CustomScrollView(
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
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // 計算累積距離
        double cumulativeDistance = 0;
        for (int i = 0; i <= index; i++) {
          cumulativeDistance += items[i].distance;
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
                    onPressed: () => onConfirmDelete(context, item.key),
                  )
                : (item.note.isNotEmpty ? const Icon(Icons.info_outline, size: 20) : null),
            onTap: () {
              if (isEditMode) {
                onShowEditDialog(context, item, selectedDay);
              } else {
                onShowCheckInDialog(context, item);
              }
            },
          ),
        );
      },
    );
  }
}
