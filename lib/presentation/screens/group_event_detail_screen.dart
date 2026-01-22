import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/group_event.dart';
import '../cubits/group_event/group_event_state.dart';
import '../../data/models/enums/group_event_status.dart';
import '../../data/models/enums/group_event_application_status.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/group_event/group_event_cubit.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../widgets/group_event/group_event_comment_sheet.dart';

/// 揪團詳情畫面
class GroupEventDetailScreen extends StatefulWidget {
  final GroupEvent event;

  const GroupEventDetailScreen({super.key, required this.event});

  @override
  State<GroupEventDetailScreen> createState() => _GroupEventDetailScreenState();
}

class _GroupEventDetailScreenState extends State<GroupEventDetailScreen> {
  late GroupEvent _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _handleApply() async {
    final cubit = context.read<GroupEventCubit>();
    final success = await cubit.applyEvent(eventId: _event.id);
    if (success && mounted) {
      ToastService.success('報名成功！');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubitState = context.watch<GroupEventCubit>().state;
    final isSyncing = cubitState is GroupEventLoaded && cubitState.isSyncing;

    // Use event from state if available for verified freshness
    if (cubitState is GroupEventLoaded) {
      final loadedEvent = cubitState.events.where((e) => e.id == widget.event.id).firstOrNull;
      if (loadedEvent != null) {
        _event = loadedEvent;
      }
    }

    final isCreator = _event.isCreator(cubitState is GroupEventLoaded ? cubitState.currentUserId : '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('揪團詳情'),
        actions: [
          IconButton(
            icon: Icon(
              _event.isLiked ? Icons.favorite : Icons.favorite_border,
              color: _event.isLiked ? Colors.red : null,
            ),
            onPressed: () {
              context.read<GroupEventCubit>().likeEvent(eventId: _event.id);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Text(_event.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 申請狀態卡片
            if (_event.myApplicationStatus != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildStatusCard(_event.myApplicationStatus!),
              ),

            // 基本資訊 Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today, '日期', _formatDateRange(_event.startDate, _event.endDate)),
                    const Divider(),
                    _buildInfoRow(Icons.location_on, '地點', _event.location.isNotEmpty ? _event.location : '未指定'),
                    const Divider(),
                    // 人數 Row (更新顯示)
                    _buildPeopleRow(),
                    const Divider(),
                    _buildInfoRow(Icons.info_outline, '狀態', _getStatusText(_event.status)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 主辦人
            Card(
              child: ListTile(
                leading: Text(_event.creatorAvatar, style: const TextStyle(fontSize: 28)),
                title: const Text('主辦人'),
                subtitle: Text(_event.creatorName),
                trailing: isCreator ? const Chip(label: Text('我'), visualDensity: VisualDensity.compact) : null,
              ),
            ),
            const SizedBox(height: 16),

            // 活動說明
            Text('活動說明', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _event.description.isNotEmpty ? _event.description : '無說明',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 報名成功訊息 (審核通過後顯示)
            if (_event.myApplicationStatus == GroupEventApplicationStatus.approved && _event.privateMessage.isNotEmpty)
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('報名成功訊息', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_event.privateMessage),
                    ],
                  ),
                ),
              ),

            // 留言區
            const SizedBox(height: 16),
            Text('留言 (${_event.commentCount})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: InkWell(
                onTap: () => GroupEventCommentSheet.show(context, _event.id),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('查看所有留言...', style: TextStyle(color: Colors.grey)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

          // 已報名或創建者不顯示報名按鈕
          if (isCreator || _event.myApplicationStatus != null) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: isOffline || !_event.canApply || isSyncing ? null : _handleApply,
              icon: isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add),
              label: Text(
                isSyncing ? '處理中...' : (_event.isFull ? '已額滿 (仍可報名)' : (_event.approvalRequired ? '送出報名申請' : '我要報名')),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(GroupEventApplicationStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case GroupEventApplicationStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        text = '報名審核中';
        break;
      case GroupEventApplicationStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        text = '報名已通過';
        break;
      case GroupEventApplicationStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = '報名未通過';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        text = '未知狀態';
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.people, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          const Text('人數', style: TextStyle(color: Colors.grey)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 主要顯示: 用 "確定 / 預計" 格式
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${_event.applicationCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const TextSpan(text: ' / '),
                    TextSpan(
                      text: '${_event.maxMembers}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(
                      text: ' 人 (預計)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 次要顯示: 總報名數 (如果有差異)
              if (_event.totalApplicationCount > _event.applicationCount)
                Text(
                  '總報名: ${_event.totalApplicationCount} 人',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final startStr = DateFormat('yyyy/MM/dd (E)', 'zh_TW').format(start);
    if (end == null || start == end) {
      return startStr;
    }
    final endStr = DateFormat('MM/dd (E)', 'zh_TW').format(end);
    return '$startStr - $endStr';
  }

  String _getStatusText(GroupEventStatus status) {
    switch (status) {
      case GroupEventStatus.open:
        return '招募中';
      case GroupEventStatus.closed:
        return '已截止';
      case GroupEventStatus.cancelled:
        return '已取消';
    }
  }
}
