import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:summitmate/domain/domain.dart';
import '../cubits/group_event/group_event_cubit.dart';
import '../cubits/group_event/group_event_state.dart';
import '../widgets/common/summit_app_bar.dart';
import 'group_event_detail_screen.dart';

/// 「我的揪團」畫面 — 包含主辦 / 報名 / 喜歡 三個 Tab
/// 每個 Tab 透過後端 /group-events/my?type=xxx 取得分頁資料
class MyGroupEventsScreen extends StatefulWidget {
  const MyGroupEventsScreen({super.key});

  @override
  State<MyGroupEventsScreen> createState() => _MyGroupEventsScreenState();
}

class _MyGroupEventsScreenState extends State<MyGroupEventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    ('host',  Icons.star_rounded,         '主辦'),
    ('apply', Icons.assignment_turned_in, '報名'),
    ('like',  Icons.favorite_rounded,     '喜歡'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    // 初始載入第一個 tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupEventCubit>().fetchMyEvents(type: _tabs[0].$1);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<GroupEventCubit>().fetchMyEvents(type: _tabs[_tabController.index].$1);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SummitAppBar(
        title: const Text('我的揪團'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(icon: Icon(t.$2), text: t.$3)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _MyEventsTabBody(type: t.$1)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 內容 Widget
// ─────────────────────────────────────────────────────────────

class _MyEventsTabBody extends StatefulWidget {
  final String type;
  const _MyEventsTabBody({required this.type});

  @override
  State<_MyEventsTabBody> createState() => _MyEventsTabBodyState();
}

class _MyEventsTabBodyState extends State<_MyEventsTabBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<GroupEventCubit>().loadMoreMyEvents();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupEventCubit, GroupEventState>(
      buildWhen: (prev, cur) =>
          cur is MyEventsLoading ||
          cur is MyEventsLoaded ||
          cur is MyEventsError,
      builder: (context, state) {
        if (state is MyEventsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MyEventsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<GroupEventCubit>().fetchMyEvents(type: widget.type),
          );
        }

        // MyEventsLoaded — show only events matching this tab's type
        if (state is MyEventsLoaded && state.type == widget.type) {
          return _EventList(
            events: state.events,
            total: state.total,
            hasMore: state.hasMore,
            isLoadingMore: state.isLoadingMore,
            scrollController: _scrollController,
            type: widget.type,
            onRefresh: () =>
                context.read<GroupEventCubit>().fetchMyEvents(type: widget.type),
          );
        }

        // Stale state from another tab — show placeholder
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Event List
// ─────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<GroupEvent> events;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final String type;
  final Future<void> Function() onRefresh;

  const _EventList({
    required this.events,
    required this.total,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.type,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyView(type: type);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: events.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == events.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isLoadingMore
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : const SizedBox.shrink(),
            );
          }
          return _EventCard(event: events[index], type: type);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Single Event Card
// ─────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final GroupEvent event;
  final String type;
  const _EventCard({required this.event, required this.type});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(event.status);
    final statusText = _statusText(event.status);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupEventDetailScreen(event: event)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 標題 + 狀態 ──────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(label: statusText, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),

              // ── 日期 + 地點 ──────────────────
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(event.startDate, event.endDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // ── 報名人數 + 附加徽章 ──────────
              Row(
                children: [
                  const Icon(Icons.people, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${event.applicationCount}/${event.maxMembers}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (type == 'apply' && event.myApplicationStatus != null)
                    _AppStatusBadge(status: event.myApplicationStatus!),
                  if (type == 'like')
                    const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(GroupEventStatus s) => switch (s) {
        GroupEventStatus.open => Colors.green,
        GroupEventStatus.closed => Colors.grey,
        GroupEventStatus.cancelled => Colors.red,
      };

  String _statusText(GroupEventStatus s) => switch (s) {
        GroupEventStatus.open => '招募中',
        GroupEventStatus.closed => '已截止',
        GroupEventStatus.cancelled => '已取消',
      };

  String _formatDate(DateTime start, DateTime? end) {
    final s = DateFormat('yyyy/MM/dd').format(start);
    if (end == null || start == end) return s;
    return '$s – ${DateFormat('MM/dd').format(end)}';
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _AppStatusBadge extends StatelessWidget {
  final GroupEventApplicationStatus status;
  const _AppStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GroupEventApplicationStatus.pending   => ('待審核', Colors.orange),
      GroupEventApplicationStatus.approved  => ('已通過', Colors.green),
      GroupEventApplicationStatus.rejected  => ('已拒絕', Colors.red),
      GroupEventApplicationStatus.cancelled => ('已取消', Colors.grey),
    };
    return _StatusChip(label: label, color: color);
  }
}

class _EmptyView extends StatelessWidget {
  final String type;
  const _EmptyView({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      'host'  => (Icons.star_outline, '還沒有主辦的揪團'),
      'apply' => (Icons.assignment_outlined, '還沒有報名的揪團'),
      _       => (Icons.favorite_border, '還沒有喜歡的揪團'),
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重試'),
          ),
        ],
      ),
    );
  }
}
