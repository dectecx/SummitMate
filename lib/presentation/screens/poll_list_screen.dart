import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/poll_provider.dart';
import '../../data/models/poll.dart';
import 'create_poll_screen.dart';
import 'poll_detail_screen.dart';

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
      Future.microtask(() => context.read<PollProvider>().fetchPolls());
      _isInit = false;
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
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('進行中'), icon: Icon(Icons.how_to_vote)),
                    ButtonSegment(value: 1, label: Text('已結束'), icon: Icon(Icons.history)),
                    ButtonSegment(value: 2, label: Text('我的投票'), icon: Icon(Icons.person_outline)),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() => _selectedFilter = newSelection.first);
                  },
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
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    poll.totalVotes.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(poll.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  poll.description.isNotEmpty ? poll.description : '無描述',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: poll.isActive
                                    ? const Chip(
                                        label: Text('投票中', style: TextStyle(fontSize: 10)),
                                        backgroundColor: Colors.greenAccent,
                                      )
                                    : const Chip(label: Text('已結束', style: TextStyle(fontSize: 10))),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PollDetailScreen(poll: poll)),
                                  );
                                },
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
