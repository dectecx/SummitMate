import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/poll_provider.dart';
import '../../data/models/poll.dart';
import 'create_poll_screen.dart';
import 'poll_detail_screen.dart';
import '../../presentation/providers/settings_provider.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

class PollListScreen extends StatefulWidget {
  const PollListScreen({super.key});

  @override
  State<PollListScreen> createState() => _PollListScreenState();
}

class _PollListScreenState extends State<PollListScreen> {
  // 0: Active, 1: Ended, 2: My
  int _selectedFilter = 0;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final isOffline = context.read<SettingsProvider>().isOfflineMode;
      if (!isOffline) {
        Future.microtask(() => context.read<PollProvider>().fetchPolls());
      }
      _isInit = false;
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, PollProvider provider, Poll poll) async {
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
      final success = await provider.deletePoll(pollId: poll.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投票已刪除')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('刪除失敗: ${provider.error}'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget _buildListTile(BuildContext context, Poll poll) {
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
                    poll.creatorId == context.read<PollProvider>().currentUserId ? '我' : poll.creatorId,
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
        if (context.mounted) {
          context.read<PollProvider>().fetchPolls();
        }
      },
    );
  }

  Future<void> _confirmAndClose(BuildContext context, PollProvider provider, Poll poll) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('結束投票'),
        content: Text('確定要結束 "${poll.title}" 嗎？\n結束後將無法再進行投票。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('結束'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await provider.closePoll(pollId: poll.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投票已結束')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('結束失敗: ${provider.error}'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PollProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.polls.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.polls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('載入失敗: ${provider.error}'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => provider.fetchPolls(),
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
            filteredPolls = provider.activePolls;
            break;
          case 1:
            filteredPolls = provider.endedPolls;
            break;
          case 2:
            filteredPolls = provider.myPolls;
            break;
          default:
            filteredPolls = provider.activePolls;
        }

        return Scaffold(
          body: Column(
            children: [
              // Filter Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('進行中'), icon: Icon(Icons.how_to_vote)),
                          ButtonSegment(value: 1, label: Text('已結束'), icon: Icon(Icons.history)),
                          ButtonSegment(value: 2, label: Text('我的'), icon: Icon(Icons.person_outline)),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() => _selectedFilter = newSelection.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => provider.fetchPolls(),
                      icon: const Icon(Icons.refresh),
                      tooltip: '重新整理',
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
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 0 ? '沒有進行中的投票' : '沒有相關投票',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchPolls(),
                        child: ListView.builder(
                          itemCount: filteredPolls.length,
                          padding: const EdgeInsets.only(bottom: 80), // Fab space
                          itemBuilder: (context, index) {
                            final poll = filteredPolls[index];
                            final isCreator = poll.creatorId == provider.currentUserId;

                            if (!isCreator) {
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: _buildListTile(context, poll),
                              );
                            }

                            // Define actions based on poll status
                            final actions = <Widget>[];
                            if (poll.isActive) {
                              actions.add(
                                SlidableAction(
                                  onPressed: (context) async {
                                    await _confirmAndClose(context, provider, poll);
                                  },
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  icon: Icons.lock_clock, // More appropriate for "Ending"
                                  label: '結束',
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                ),
                              );
                            }

                            actions.add(
                              SlidableAction(
                                onPressed: (context) async {
                                  await _confirmAndDelete(context, provider, poll);
                                },
                                backgroundColor: const Color(0xFFFE4A49),
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '刪除',
                                // Adjust border radius based on position
                                borderRadius: poll.isActive
                                    ? const BorderRadius.horizontal(right: Radius.circular(12))
                                    : BorderRadius.circular(12),
                              ),
                            );

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
                                child: Card(margin: EdgeInsets.zero, child: _buildListTile(context, poll)),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePollScreen()));
            },
            icon: const Icon(Icons.add),
            label: const Text('發起投票'),
          ),
        );
      },
    );
  }
}
