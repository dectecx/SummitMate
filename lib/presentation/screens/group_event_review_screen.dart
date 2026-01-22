import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../data/models/group_event.dart';
import '../../../data/models/enums/group_event_application_status.dart';
import '../cubits/group_event/review/group_event_review_cubit.dart';
import '../../../data/repositories/interfaces/i_group_event_repository.dart';

class GroupEventReviewScreen extends StatelessWidget {
  final String eventId;
  final String currentUserId;

  const GroupEventReviewScreen({super.key, required this.eventId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GroupEventReviewCubit(repository: getIt<IGroupEventRepository>(), eventId: eventId, userId: currentUserId)
            ..loadApplications(),
      child: Scaffold(
        appBar: AppBar(title: const Text('審核報名')),
        body: BlocConsumer<GroupEventReviewCubit, GroupEventReviewState>(
          listener: (context, state) {
            if (state is GroupEventReviewError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          builder: (context, state) {
            if (state is GroupEventReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GroupEventReviewLoaded || state is GroupEventReviewSyncing) {
              final applications = state is GroupEventReviewLoaded
                  ? state.applications
                  : (state as GroupEventReviewSyncing).applications;

              if (applications.isEmpty) {
                return const Center(child: Text('目前沒有報名申請'));
              }

              final isSyncing = state is GroupEventReviewSyncing;

              return Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      final app = applications[index];
                      return _buildApplicationCard(context, app, isSyncing);
                    },
                  ),
                  if (isSyncing) const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            return const Center(child: Text('無法載入資料'));
          },
        ),
      ),
    );
  }

  /// 建構報名者卡片
  Widget _buildApplicationCard(BuildContext context, GroupEventApplication app, bool isSyncing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(app.userAvatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('申請時間: ${_formatDate(app.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _buildStatusChip(app.status),
              ],
            ),
            if (app.message.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('留言:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(app.message),
            ],
            if (app.isPending) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: isSyncing
                        ? null
                        : () {
                            context.read<GroupEventReviewCubit>().reviewApplication(app.id, 'reject');
                          },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('拒絕'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: isSyncing
                        ? null
                        : () {
                            context.read<GroupEventReviewCubit>().reviewApplication(app.id, 'approve');
                          },
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('通過'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 建構狀態標籤
  Widget _buildStatusChip(GroupEventApplicationStatus status) {
    Color color;
    String text;
    switch (status) {
      case GroupEventApplicationStatus.pending:
        color = Colors.orange;
        text = '審核中';
        break;
      case GroupEventApplicationStatus.approved:
        color = Colors.green;
        text = '已通過';
        break;
      case GroupEventApplicationStatus.rejected:
        color = Colors.red;
        text = '已拒絕';
        break;
      case GroupEventApplicationStatus.cancelled:
        color = Colors.grey;
        text = '已取消';
        break;
    }
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
