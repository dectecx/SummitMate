import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/sync/sync_cubit.dart';
import '../../cubits/sync/sync_state.dart';
import 'sync_status_detail_sheet.dart';

class SyncStatusIndicator extends StatelessWidget {
  final bool showLabel;
  final Color? color;

  const SyncStatusIndicator({super.key, this.showLabel = false, this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final pendingCount = state.pendingCount;
        final isOnline = state.isOnline;
        final isInProgress = state.isInProgress;

        IconData icon;
        Color statusColor;
        String label = '';

        if (!isOnline) {
          icon = Icons.cloud_off;
          statusColor = Colors.grey;
          label = '離線';
        } else if (isInProgress) {
          icon = Icons.sync;
          statusColor = Theme.of(context).colorScheme.primary;
          label = '同步中';
        } else if (pendingCount > 0) {
          icon = Icons.cloud_upload;
          statusColor = Colors.orange;
          label = '$pendingCount 待同步';
        } else {
          icon = Icons.cloud_done;
          statusColor = Colors.green;
          label = '已同步';
        }

        final mainColor = color ?? statusColor;

        return InkWell(
          onTap: () => _showSyncDetail(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    isInProgress
                        ? RotationTransition(
                            turns: const AlwaysStoppedAnimation(0), // Would need a controller for animation
                            child: Icon(icon, color: mainColor, size: 20),
                          )
                        : Icon(icon, color: mainColor, size: 20),
                    if (pendingCount > 0 && !isInProgress)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          pendingCount > 99 ? '99+' : '$pendingCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(color: mainColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyncDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SyncStatusDetailSheet(),
    );
  }
}
