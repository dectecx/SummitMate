import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/group_event.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/group_event/group_event_cubit.dart';
import '../cubits/group_event/group_event_state.dart';
import '../../data/models/enums/group_event_status.dart';
import '../../infrastructure/tools/toast_service.dart';
import 'group_event_detail_screen.dart';
import 'create_group_event_screen.dart';

/// 揪團列表畫面
///
/// 顯示所有揪團活動，支援篩選 (全部、熱門、即將出發)。
/// 訪客模式下僅顯示列表，無法進入詳情。
class GroupEventsListScreen extends StatefulWidget {
  const GroupEventsListScreen({super.key});

  @override
  State<GroupEventsListScreen> createState() => _GroupEventsListScreenState();
}

class _GroupEventsListScreenState extends State<GroupEventsListScreen> {
  // 0: 全部, 1: 熱門, 2: 即將出發
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    context.read<GroupEventCubit>().fetchEvents(isAuto: true);
  }

  Widget _buildEventCard(BuildContext context, GroupEvent event, String currentUserId, bool isGuest) {
    final isCreator = event.creatorId == currentUserId;
    final statusColor = _getStatusColor(event.status);
    final statusText = _getStatusText(event.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (isGuest) {
            ToastService.warning('請登入以查看揪團詳情');
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => GroupEventDetailScreen(event: event)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題 Row
              Row(
                children: [
                  const Icon(Icons.hiking, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 狀態 Chip
                  Chip(
                    label: Text(statusText, style: TextStyle(fontSize: 10, color: statusColor)),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: statusColor),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 日期
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formatDateRange(event.startDate, event.endDate), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),

              // 地點
              if (event.location.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // 底部資訊 Row
              Row(
                children: [
                  // 主辦人
                  Text(event.creatorAvatar, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(isCreator ? '我' : event.creatorName, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  const Text('·', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),

                  // 報名人數
                  const Icon(Icons.people, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    isGuest ? '?/?' : '${event.applicationCount}/${event.maxMembers}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const Spacer(),

                  // 喜歡數
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: event.isLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text('${event.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // 留言數
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text('${event.commentCount}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),

              // 訪客模式提示
              if (isGuest)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('需登入查看', style: TextStyle(fontSize: 11, color: Colors.orange)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(GroupEventStatus status) {
    switch (status) {
      case GroupEventStatus.open:
        return Colors.green;
      case GroupEventStatus.closed:
        return Colors.grey;
      case GroupEventStatus.cancelled:
        return Colors.red;
    }
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

  String _formatDateRange(DateTime start, DateTime? end) {
    final startStr = DateFormat('yyyy/MM/dd').format(start);
    if (end == null || start == end) {
      return startStr;
    }
    final endStr = DateFormat('MM/dd').format(end);
    return '$startStr - $endStr';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupEventCubit, GroupEventState>(
      listener: (context, state) {
        // Handle errors if needed
      },
      builder: (context, state) {
        if (state is GroupEventLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('揪團活動')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        List<GroupEvent> events = [];
        String currentUserId = '';
        DateTime? lastSyncTime;
        bool isSyncing = false;
        bool isGuest = false;
        String? errorMessage;

        if (state is GroupEventLoaded) {
          events = state.events;
          currentUserId = state.currentUserId;
          lastSyncTime = state.lastSyncTime;
          isSyncing = state.isSyncing;
          isGuest = state.isGuest;
        } else if (state is GroupEventError) {
          errorMessage = state.message;
        }

        if (errorMessage != null && events.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('揪團活動')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('載入失敗: $errorMessage'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.read<GroupEventCubit>().fetchEvents(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重試'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter logic
        List<GroupEvent> filteredEvents;
        switch (_selectedFilter) {
          case 0: // 全部
            filteredEvents = events.where((e) => e.status == GroupEventStatus.open).toList();
            break;
          case 1: // 熱門 (by likeCount)
            filteredEvents = events.where((e) => e.status == GroupEventStatus.open).toList()
              ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
            break;
          case 2: // 即將出發 (by startDate)
            final now = DateTime.now();
            filteredEvents = events.where((e) => e.status == GroupEventStatus.open && e.startDate.isAfter(now)).toList()
              ..sort((a, b) => a.startDate.compareTo(b.startDate));
            break;
          default:
            filteredEvents = events.where((e) => e.status == GroupEventStatus.open).toList();
        }

        return Scaffold(
          body: Column(
            children: [
              // Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('全部')),
                          ButtonSegment(value: 1, label: Text('🔥 熱門')),
                          ButtonSegment(value: 2, label: Text('📅 即將出發')),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() => _selectedFilter = newSelection.first);
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sync indicator
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsState) {
                        final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
                        return Material(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              if (isOffline) {
                                ToastService.warning('離線模式無法同步');
                                return;
                              }
                              context.read<GroupEventCubit>().fetchEvents();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isOffline
                                        ? '離線'
                                        : (lastSyncTime != null
                                              ? DateFormat('HH:mm').format(lastSyncTime.toLocal())
                                              : '同步'),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isSyncing)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    const Icon(Icons.sync, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 訪客模式提示
              if (isGuest)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('請登入以查看揪團詳情', style: TextStyle(fontSize: 12, color: Colors.amber)),
                    ],
                  ),
                ),

              // Event List
              Expanded(
                child: filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hiking, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              '目前沒有揪團活動',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<GroupEventCubit>().fetchEvents(),
                        child: ListView.builder(
                          itemCount: filteredEvents.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            return _buildEventCard(context, filteredEvents[index], currentUserId, isGuest);
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

              // 訪客模式下隱藏 FAB
              if (isGuest) {
                return const SizedBox.shrink();
              }

              return FloatingActionButton.extended(
                onPressed: () {
                  if (isOffline) {
                    ToastService.warning('離線模式無法建立揪團');
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupEventScreen()));
                },
                backgroundColor: isOffline ? Colors.grey : null,
                icon: const Icon(Icons.add),
                label: const Text('建立揪團'),
              );
            },
          ),
        );
      },
    );
  }
}
