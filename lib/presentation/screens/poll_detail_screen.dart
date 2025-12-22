import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/poll.dart';
import '../../providers/poll_provider.dart';
import '../../services/toast_service.dart';

class PollDetailScreen extends StatefulWidget {
  final Poll poll;

  const PollDetailScreen({super.key, required this.poll});

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  late Set<String> _selectedOptionIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize selection with existing votes
    _selectedOptionIds = Set.from(widget.poll.myVotes);
  }

  @override
  void didUpdateWidget(PollDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local selection if poll data updates (e.g. after refresh)
    // Only update if myVotes changed, to avoid overwriting user's current unsaved selection
    // Note: This logic assumes poll.myVotes is the source of truth for "saved" state.
    if (widget.poll.myVotes.length != oldWidget.poll.myVotes.length ||
        !widget.poll.myVotes.every((element) => oldWidget.poll.myVotes.contains(element))) {
      // Ideally we might want to sync, but if user is editing, it's tricky.
      // For now, let's just keep user's local state unless valid submission happened.
    }
  }

  void _toggleOption(String optionId) {
    setState(() {
      if (widget.poll.allowMultipleVotes) {
        if (_selectedOptionIds.contains(optionId)) {
          _selectedOptionIds.remove(optionId);
        } else {
          _selectedOptionIds.add(optionId);
        }
      } else {
        _selectedOptionIds.clear();
        _selectedOptionIds.add(optionId);
      }
    });
  }

  Future<void> _submitVote() async {
    if (_selectedOptionIds.isEmpty) {
      ToastService.info('請至少選擇一個選項');
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<PollProvider>();

    try {
      final success = await provider.votePoll(pollId: widget.poll.id, optionIds: _selectedOptionIds.toList());

      if (success) {
        ToastService.success('投票成功');
        if (mounted) Navigator.pop(context); // Optional: go back or stay to see results
      } else {
        ToastService.error(provider.error ?? '投票失敗');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _addOption() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增選項'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '選項內容', hintText: '輸入新的投票選項'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('新增')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isSubmitting = true);
      final provider = context.read<PollProvider>();
      try {
        final success = await provider.addOption(pollId: widget.poll.id, text: result);
        if (success) {
          ToastService.success('已新增選項: $result');
          // No need to pop, UI will update via Consumer/Parent
        } else {
          ToastService.error(provider.error ?? '新增失敗');
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the poll instance to use.
    // We should use the one from Provider effectively if we want real-time updates while on this screen.
    // But widget.poll is passed in. Let's rely on Consumer in parent or just use widget.poll if parent rebuilds.
    // For simplicity, we use widget.poll which is updated when parent rebuilds.
    // Actually, to get updates, we should probably find the poll from provider by ID.
    // But since Screen is usually pushed with a snapshot, let's wrap body in Consumer to find fresh data.

    return Consumer<PollProvider>(
      builder: (context, provider, child) {
        // Find the fresh poll object from provider
        final freshPoll = provider.polls.firstWhere(
          (p) => p.id == widget.poll.id,
          orElse: () => widget.poll, // Fallback
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('投票詳情'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isSubmitting ? null : () => provider.fetchPolls(),
              ),
            ],
          ),
          body: _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header info
                      Row(
                        children: [
                          if (freshPoll.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('進行中', style: TextStyle(color: Colors.green.shade800, fontSize: 12)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('已結束', style: TextStyle(fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          if (freshPoll.deadline != null)
                            Text(
                              '截止: ${DateFormat('yyyy/MM/dd HH:mm').format(freshPoll.deadline!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        freshPoll.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (freshPoll.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(freshPoll.description, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (freshPoll.allowMultipleVotes)
                            Chip(
                              label: const Text('可多選'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: TextStyle(color: Colors.blue.shade800),
                            ),
                          if (freshPoll.isAllowAddOption)
                            Chip(
                              label: const Text('可新增選項'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.orange.shade50,
                              labelStyle: TextStyle(color: Colors.orange.shade800),
                            ),
                          Chip(label: Text('總票數: ${freshPoll.totalVotes}'), visualDensity: VisualDensity.compact),
                        ],
                      ),
                      const Divider(height: 32),

                      // Options List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: freshPoll.options.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final option = freshPoll.options[index];
                          final isSelected = _selectedOptionIds.contains(option.id);
                          final percentage = freshPoll.totalVotes > 0 ? option.voteCount / freshPoll.totalVotes : 0.0;

                          return InkWell(
                            onTap: freshPoll.isActive ? () => _toggleOption(option.id) : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                    : Theme.of(context).cardColor,
                                border: Border.all(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (freshPoll.isActive)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8, top: 2),
                                          child: Icon(
                                            freshPoll.allowMultipleVotes
                                                ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                                                : (isSelected ? Icons.radio_button_checked : Icons.radio_button_off),
                                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          option.text,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(percentage * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Progress Bar
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          minHeight: 8,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${option.voteCount} 票',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      if (freshPoll.isActive)
                        Row(
                          children: [
                            if (freshPoll.isAllowAddOption) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _addOption,
                                  icon: const Icon(Icons.add),
                                  label: const Text('新增選項'),
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _submitVote,
                                icon: const Icon(Icons.check),
                                label: const Text('送出投票'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
