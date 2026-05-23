import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import 'package:summitmate/domain/domain.dart';
import '../cubits/group_event/review/group_event_review_cubit.dart';

class GroupEventReviewScreen extends StatelessWidget {
  final String eventId;
  final String currentUserId;

  const GroupEventReviewScreen({super.key, required this.eventId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GroupEventReviewCubit>(param1: eventId, param2: currentUserId)..loadApplications(),
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

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  final app = applications[index];
                  return _buildApplicationCard(context, app, isSyncing);
                },
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
            if (app.isRejected && app.rejectionReason.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                '拒絕原因:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 4),
              Text(app.rejectionReason, style: const TextStyle(color: Colors.red)),
            ],
            if (app.isPending) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: isSyncing
                        ? null
                        : () async {
                            final reason = await _showRejectReasonDialog(context);
                            if (reason != null) {
                              context.read<GroupEventReviewCubit>().reviewApplication(
                                app.id,
                                GroupEventReviewAction.reject,
                                note: reason,
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                          )
                        : const Text('拒絕'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: isSyncing
                        ? null
                        : () {
                            context.read<GroupEventReviewCubit>().reviewApplication(
                              app.id,
                              GroupEventReviewAction.approve,
                            );
                          },
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('通過'),
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

  Future<String?> _showRejectReasonDialog(BuildContext context) async {
    String reason = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拒絕申請'),
        content: TextField(
          decoration: const InputDecoration(hintText: '請輸入拒絕原因 (選填)', border: OutlineInputBorder()),
          maxLines: 3,
          onChanged: (value) => reason = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, reason),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('確認拒絕'),
          ),
        ],
      ),
    );
  }
}
