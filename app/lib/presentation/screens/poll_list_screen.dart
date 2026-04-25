import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/poll.dart';
import 'create_poll_screen.dart';
import 'poll_detail_screen.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/poll/poll_state.dart';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// 投票列表畫面
///
/// 顯示所有投票活動，支援篩選 (進行中、已結束、我的)。
/// 提供側滑選單 (Slidable) 進行快速操作 (刪除、結束)。
class PollListScreen extends StatefulWidget {
  const PollListScreen({super.key});

  @override
  State<PollListScreen> createState() => _PollListScreenState();
}

class _PollListScreenState extends State<PollListScreen> {
  // 0: Active, 1: Ended, 2: My
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch if needed
    context.read<PollCubit>().fetchPolls(isAuto: true);
  }

  Future<void> _confirmAndDelete(BuildContext context, PollCubit cubit, Poll poll) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除投票'),
        content: Text('確定要刪除 "${poll.title}" 嗎？此動作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await cubit.deletePoll(pollId: poll.id);
      // Feedback handled by cubit (ToastService usually) or we can show snackbar here if needed.
      // PollCubit doesn't return success bool strictly, but handles errors via state or toasts.
      // Assuming Cubit handles toast for success/failure or we listen to state.
      // For now, relies on Cubit's ToastService.
    }
  }

  Widget _buildListTile(BuildContext context, Poll poll, String currentUserId) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.poll),
      ),
      title: Text(poll.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.description.isNotEmpty ? poll.description : '無描述', maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${poll.totalVotes} 票', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    poll.creatorId == currentUserId ? '我' : poll.creatorId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          poll.isActive
              ? const Chip(
                  label: Text('投票中', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.greenAccent,
                )
              : const Chip(
                  label: Text('已結束', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                ),
        ],
      ),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => PollDetailScreen(poll: poll)));
        // No need to manually refetch if PollDetailScreen uses Cubit and updates state.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PollCubit, PollState>(
      listener: (context, state) {
        if (state is PollError) {
          // Show error toast if needed, but usually Cubit handles it or we show UI error
          // If we want to show a snackbar for critical errors not handled by ToastService
        }
      },
      builder: (context, state) {
        if (state is PollLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Poll> polls = [];
        String currentUserId = '';
        DateTime? lastSyncTime;
        bool isSyncing = false;
        String? errorMessage;

        if (state is PollLoaded) {
          polls = state.polls;
          currentUserId = state.currentUserId;
          lastSyncTime = state.lastSyncTime;
          isSyncing = state.isSyncing;
        } else if (state is PollError) {
          errorMessage = state.message;
          // We might still have polls if we persist them?
          // PollState doesn't define polls in PollError.
          // In PollCubit implementation, on error it might emit PollError without data.
          // Ideally we should keep data. But based on current simple implementation:
        }

        if (errorMessage != null && polls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('載入失敗: $errorMessage'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.read<PollCubit>().fetchPolls(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重試'),
                ),
              ],
            ),
          );
        }

        List<Poll> filteredPolls;
        switch (_selectedFilter) {
          case 0:
            filteredPolls = polls.where((p) => p.isActive).toList();
            break;
          case 1:
            filteredPolls = polls.where((p) => !p.isActive).toList();
            break;
          case 2:
            filteredPolls = polls.where((p) => p.creatorId == currentUserId).toList();
            break;
          default:
            filteredPolls = polls.where((p) => p.isActive).toList();
        }

        // Sort: Active/Ended usually by date desc?
        // provider used getters which sorted. "Newest first"
        filteredPolls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('🔥 進行中')),
                          ButtonSegment(value: 1, label: Text('✔️ 已結束')),
                          ButtonSegment(value: 2, label: Text('⭐ 我的')),
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
                          side: WidgetStateProperty.all(const BorderSide(color: Colors.grey, width: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sync time + refresh button
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsState) {
                        final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
                        return Material(
                          color: isOffline ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              if (isOffline) {
                                ToastService.warning('離線模式無法同步');
                                return;
                              }
                              context.read<PollCubit>().fetchPolls();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isOffline
                                        ? '離線模式'
                                        : (lastSyncTime != null
                                              ? DateFormat('MM/dd HH:mm').format(lastSyncTime.toLocal())
                                              : '未同步'),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 4),
                                  if (isSyncing)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    Icon(Icons.sync, size: 16, color: isOffline ? Colors.grey : Colors.grey),
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

              // List
              Expanded(
                child: filteredPolls.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 0 ? '沒有進行中的投票' : '沒有相關投票',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<PollCubit>().fetchPolls(),
                        child: ListView.builder(
                          itemCount: filteredPolls.length,
                          padding: const EdgeInsets.only(bottom: 80), // Fab space
                          itemBuilder: (context, index) {
                            final poll = filteredPolls[index];
                            final isCreator = poll.creatorId == currentUserId;

                            if (!isCreator) {
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: _buildListTile(context, poll, currentUserId),
                              );
                            }

                            // Define actions based on poll status
                            final actions = <Widget>[];
                            final settingsState = context.read<SettingsCubit>().state;
                            final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

                            if (!isOffline) {
                              actions.add(
                                SlidableAction(
                                  onPressed: (context) async {
                                    await _confirmAndDelete(context, context.read<PollCubit>(), poll);
                                  },
                                  backgroundColor: const Color(0xFFFE4A49),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: '刪除',
                                  // Adjust border radius based on position
                                  borderRadius:
                                      (poll.isActive && !isOffline) // Re-check if previous button exists
                                      ? const BorderRadius.horizontal(right: Radius.circular(12))
                                      : BorderRadius.circular(12),
                                ),
                              );
                            }

                            if (isOffline) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: _buildListTile(context, poll, currentUserId),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Slidable(
                                key: Key(poll.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  // 0.25 per action
                                  extentRatio: actions.length * 0.25,
                                  children: actions,
                                ),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: _buildListTile(context, poll, currentUserId),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
              return FloatingActionButton.extended(
                onPressed: () {
                  if (isOffline) {
                    ToastService.warning('離線模式無法發起投票');
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePollScreen()));
                },
                backgroundColor: isOffline ? Colors.grey : null,
                icon: const Icon(Icons.add),
                label: const Text('發起投票'),
              );
            },
          ),
        );
      },
    );
  }
}
