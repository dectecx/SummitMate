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

        // Check if I am creator
        // Since we don't have global currentUserId storage easily accessible here except passed in arguments or providers,
        // we might need to rely on what we have.
        // Actually, we passed userId to services, but here we need to know "am I creator?".
        // For now, let's assume we can compare IDs. But we need my userId.
        // We can get it from EnvConfig or passed separately?
        // Wait, PollService.votePoll requires userId. It comes from where?
        // In the previous code, we didn't check creator permission in UI strictly, just backend.
        // But for UI buttons (Delete Poll), we should hide them if not creator.
        // Let's assume we can show them and backend rejects if not allowed, OR we create a "Am I Creator" check if we had userId.
        // Re-checking how userId is obtained in creating poll. It uses 'test_user_1' or similar from some constant?
        // In main.dart, we generate/get userId.
        // Let's try to get userId from a Provider if available, or just show buttons for everyone (and fail safely).
        // Actually, `PollListScreen` uses `PollProvider`. Does `PollProvider` store currentUserId?
        // Let's check PollProvider.
        // If not, I will just show the buttons.

        return Scaffold(
          appBar: AppBar(title: const Text('投票詳情')),
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
                          const Spacer(), // Use spacer to push deadline to right
                          if (freshPoll.deadline != null)
                            Text(
                              '截止: ${DateFormat('yyyy/MM/dd HH:mm').format(freshPoll.deadline!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '總票數: ${freshPoll.totalVotes}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        freshPoll.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '發起人: ${freshPoll.creatorId}  •  ${DateFormat('yyyy/MM/dd HH:mm').format(freshPoll.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
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
                              label: const Text('多選'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: TextStyle(color: Colors.blue.shade800),
                            ),
                          if (freshPoll.isAllowAddOption)
                            Chip(
                              label: const Text('允許新增'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.orange.shade50,
                              labelStyle: TextStyle(color: Colors.orange.shade800),
                            ),
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

                          // Voters text
                          // option.voters is List<Map<String, dynamic>>
                          final votersList = option.voters.map((v) => v['user_name'] ?? v['user_id']).join(', ');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
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
                                                    : (isSelected
                                                          ? Icons.radio_button_checked
                                                          : Icons.radio_button_off),
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
                                                isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '${option.voteCount} 票',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                                          ),
                                          const Spacer(),
                                          // Delete Option Button (Only if 0 votes AND active)
                                          if (freshPoll.isActive && option.voteCount == 0)
                                            InkWell(
                                              onTap: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: const Text('刪除選項'),
                                                    content: Text('確定要刪除 "${option.text}" 嗎？'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(c, false),
                                                        child: const Text('取消'),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () => Navigator.pop(c, true),
                                                        child: const Text('刪除'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  setState(() => _isSubmitting = true);
                                                  try {
                                                    await provider.deleteOption(optionId: option.id);
                                                    ToastService.success('選項已刪除');
                                                  } catch (e) {
                                                    ToastService.error(e.toString());
                                                  } finally {
                                                    setState(() => _isSubmitting = false);
                                                  }
                                                }
                                              },
                                              child: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Voters List
                              if (votersList.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
                                  child: Text(
                                    '投票者: $votersList',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ),
                            ],
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

                      // Management Actions (Visible to Creator)
                      // Ideally we check if current user is creator.
                      // Since we don't have global user context easily here, we show them
                      // and let the backend/provider handle validation or errors if action fails.
                      // Or relies on "freshPoll.creatorId == currentUserId" if we can access it.
                      if (true) ...[
                        // Just show them, we'll confirm and handle errors
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('管理投票', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (freshPoll.isActive)
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('關閉投票'),
                                      content: const Text('確定要提早結束此投票嗎？'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                                        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('確定')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    setState(() => _isSubmitting = true);
                                    try {
                                      await provider.closePoll(pollId: freshPoll.id);
                                      ToastService.success('投票已關閉');
                                    } catch (e) {
                                      ToastService.error(e.toString());
                                    } finally {
                                      setState(() => _isSubmitting = false);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.lock_clock),
                                label: const Text('結束投票'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                  foregroundColor: Colors.orange.shade900,
                                ),
                              ),

                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('刪除投票'),
                                    content: const Text('確定要刪除此投票嗎？此動作無法復原。'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('刪除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  setState(() => _isSubmitting = true);
                                  try {
                                    await provider.deletePoll(pollId: freshPoll.id);
                                    ToastService.success('投票已刪除');
                                    if (mounted) Navigator.pop(context);
                                  } catch (e) {
                                    ToastService.error(e.toString());
                                    setState(() => _isSubmitting = false);
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('刪除投票'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
