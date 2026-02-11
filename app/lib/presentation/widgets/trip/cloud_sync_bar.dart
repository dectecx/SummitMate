import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../screens/trip_cloud_screen.dart';

/// 雲端同步狀態列
///
/// 顯示上次同步時間，並提供導航至雲端同步頁面的入口。
class CloudSyncBar extends StatelessWidget {
  /// 上次同步時間 (若為 null 則顯示「尚未同步」)
  final DateTime? lastSyncTime;

  const CloudSyncBar({super.key, this.lastSyncTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripCloudScreen())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_sync, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('雲端同步狀態', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  if (lastSyncTime != null)
                    Text(
                      '上次同步: ${dateFormat.format(lastSyncTime!)}',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    )
                  else
                    Text('尚未同步', style: TextStyle(color: theme.hintColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
