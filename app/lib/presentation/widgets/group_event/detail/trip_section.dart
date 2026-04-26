import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/group_event.dart';
import '../../../cubits/group_event/group_event_cubit.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

class TripSection extends StatelessWidget {
  final GroupEvent event;
  final bool isCreator;
  final bool isSyncing;

  const TripSection({super.key, required this.event, required this.isCreator, required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    if (event.linkedTripId == null && event.tripSnapshot == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snapshot = event.tripSnapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('行程預覽', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (isCreator && event.linkedTripId != null)
              TextButton.icon(
                onPressed: isSyncing
                    ? null
                    : () async {
                        final success = await context.read<GroupEventCubit>().updateSnapshot(event.id);
                        if (success && context.mounted) {
                          ToastService.success('行程快照已更新');
                        }
                      },
                icon: isSyncing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync, size: 18),
                label: const Text('更新快照'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (snapshot != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.map_outlined, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snapshot.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('yyyy/MM/dd').format(snapshot.startDate)}${snapshot.endDate != null ? ' - ${DateFormat('yyyy/MM/dd').format(snapshot.endDate!)}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (event.snapshotUpdatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '快照更新於: ${DateFormat('yyyy/MM/dd HH:mm').format(event.snapshotUpdatedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (snapshot.itinerary.isNotEmpty) ...[
                  ...snapshot.itinerary
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(item.name, style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                  if (snapshot.itinerary.length > 3)
                    Text(
                      '...還有 ${snapshot.itinerary.length - 3} 個行程點',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to read-only Trip detail or linked master trip if creator
                      ToastService.info('完整行程檢視功能開發中');
                    },
                    child: const Text('查看完整行程'),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: const Center(child: Text('行程連結中，尚未建立快照')),
          ),
      ],
    );
  }
}
