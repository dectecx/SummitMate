import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/poll.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/poll/poll_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// 投票詳情畫面
///
/// 顯示單一投票活動的詳細資訊，並提供投票、新增選項 (若允許)、管理投票 (若為發起人) 等功能。
/// 支援即時更新與離線模式檢查。
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
    // Logic to sync myVotes if updated externally?
    // Since we re-use widget.poll mostly or fetch from cubit, we might want to respect local edits.
    // If widget.poll.myVotes changes (e.g. from sync), we should update _selectedOptionIds unless submitting?
    // For simplicity, we'll keep local state isolated until submit.
  }

  void _toggleOption(String optionId, bool allowMultiple) {
    setState(() {
      if (allowMultiple) {
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

  Future<void> _submitVote(PollCubit cubit, String pollId) async {
    if (_selectedOptionIds.isEmpty) {
      ToastService.info('請至少選擇一個選項');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await cubit.votePoll(pollId: pollId, optionIds: _selectedOptionIds.toList());
      // Cubit handles toasts (via fetchPolls mostly).
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _addOption(PollCubit cubit, String pollId) async {
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
      try {
        await cubit.addOption(pollId: pollId, text: result);
        // Toast handled by cubit.
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PollCubit, PollState>(
      listener: (context, state) {
        // error handling handled by cubit usually
      },
      builder: (context, state) {
        final settingsState = context.watch<SettingsCubit>().state;
        final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

        Poll freshPoll = widget.poll;
        if (state is PollLoaded) {
          try {
            freshPoll = state.polls.firstWhere((p) => p.id == widget.poll.id);
          } catch (_) {
            // Poll not found in list (maybe deleted?), stick to widget.poll or show error?
            // sticking to widget.poll allows viewing what we have.
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('投票詳情')),
          body: _isSubmitting || (state is PollLoading && state is! PollLoaded)
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
                      if (isOffline) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '離線模式中，無法進行投票或編輯',
                                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          // option.voters is List<Map<String, dynamic>>
                          final votersList = option.voters.map((v) => v['user_name'] ?? v['user_id']).join(', ');
                          final canInteract = freshPoll.isActive && !isOffline;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: canInteract
                                    ? () => _toggleOption(option.id, freshPoll.allowMultipleVotes)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
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
                                                color: canInteract
                                                    ? (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey)
                                                    : Colors.grey.shade300,
                                                size: 20,
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              option.text,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: canInteract ? null : Colors.grey,
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
                                          if (freshPoll.isActive && option.voteCount == 0 && !isOffline)
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
                                                  if (!context.mounted) return;
                                                  setState(() => _isSubmitting = true);
                                                  try {
                                                    await context.read<PollCubit>().deleteOption(
                                                      pollId: freshPoll.id,
                                                      optionId: option.id,
                                                    );
                                                    // Toast handled by cubit.
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
                                  onPressed: isOffline
                                      ? null
                                      : () => _addOption(context.read<PollCubit>(), freshPoll.id),
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
                                onPressed: isOffline
                                    ? null
                                    : () => _submitVote(context.read<PollCubit>(), freshPoll.id),
                                icon: const Icon(Icons.check),
                                label: const Text('送出投票'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              ),
                            ),
                          ],
                        ),
                      // Management Actions (Visible to Creator)
                      // Logic: freshPoll.creatorId needed. But to check if I am creator, I need my ID.
                      // PollState has currentUserId if loaded.
                      if (state is PollLoaded && freshPoll.creatorId == state.currentUserId) ...[
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
                                onPressed: isOffline
                                    ? null
                                    : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('關閉投票'),
                                            content: const Text('確定要提早結束此投票嗎？'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(c, false),
                                                child: const Text('取消'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(c, true),
                                                child: const Text('確定'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          if (!context.mounted) return;
                                          setState(() => _isSubmitting = true);
                                          try {
                                            await context.read<PollCubit>().closePoll(pollId: freshPoll.id);
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
                                  disabledBackgroundColor: Colors.grey.shade200,
                                  disabledForegroundColor: Colors.grey,
                                ),
                              ),

                            OutlinedButton.icon(
                              onPressed: isOffline
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('刪除投票'),
                                          content: const Text('確定要刪除此投票嗎？此動作無法復原。'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(c, false),
                                              child: const Text('取消'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('刪除'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        if (!context.mounted) return;
                                        setState(() => _isSubmitting = true);
                                        try {
                                          await context.read<PollCubit>().deletePoll(pollId: freshPoll.id);
                                          if (context.mounted) Navigator.pop(context);
                                        } finally {
                                          if (context.mounted) setState(() => _isSubmitting = false);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('刪除投票'),
                              style:
                                  OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    disabledForegroundColor: Colors.grey,
                                  ).copyWith(
                                    side: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.disabled)) {
                                        return const BorderSide(color: Colors.grey);
                                      }
                                      return const BorderSide(color: Colors.red);
                                    }),
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
