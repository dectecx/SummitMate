import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/sync/sync_cubit.dart';
import '../../cubits/sync/sync_state.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../core/di/injection.dart';

class SyncStatusDetailSheet extends StatelessWidget {
  const SyncStatusDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: BlocBuilder<SyncCubit, SyncState>(
        builder: (context, state) {
          DateTime? lastSync;
          if (state is SyncInitial) {
            lastSync = state.lastSyncTime;
          } else if (state is SyncSuccess) {
            lastSync = state.timestamp;
          } else if (state is SyncFailure) {
            lastSync = state.lastSuccessTime;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('同步狀態', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (state.isInProgress)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    IconButton(
                      onPressed: state.isOnline ? () => context.read<SyncCubit>().syncAll(force: true) : null,
                      icon: const Icon(Icons.refresh),
                      tooltip: '立即同步',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.access_time,
                '上次同步',
                lastSync != null ? DateFormat('yyyy/MM/dd HH:mm').format(lastSync) : '尚未同步',
              ),
              _buildInfoRow(
                context,
                state.isOnline ? Icons.wifi : Icons.wifi_off,
                '網路狀態',
                state.isOnline ? '在線' : '離線',
                color: state.isOnline ? Colors.green : Colors.red,
              ),
              const Divider(height: 32),
              const Text('待同步項目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTableSyncStatus(context, 'itinerary_items_table', '行程項目'),
              _buildTableSyncStatus(context, 'gear_items_table', '裝備清單'),
              _buildTableSyncStatus(context, 'messages_table', '聊天訊息'),
              _buildTableSyncStatus(context, 'group_events_table', '揪團活動'),
              _buildTableSyncStatus(context, 'group_event_applications_table', '報名申請'),
              if (state.isFailure) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (state as SyncFailure).errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isOnline && !state.isInProgress
                      ? () => context.read<SyncCubit>().syncAll(force: true)
                      : null,
                  icon: const Icon(Icons.sync),
                  label: const Text('立即完整同步'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: color ?? Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSyncStatus(BuildContext context, String tableName, String label) {
    return StreamBuilder<SyncStatus>(
      stream: getIt<ISyncService>().watchSyncStatus(tableName),
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.synced;
        final isPending = status != SyncStatus.synced;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(label),
              const Spacer(),
              if (isPending)
                const Icon(Icons.pending_outlined, size: 16, color: Colors.orange)
              else
                const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                isPending ? '等待同步' : '已同步',
                style: TextStyle(
                  fontSize: 12,
                  color: isPending ? Colors.orange : Colors.green,
                  fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
