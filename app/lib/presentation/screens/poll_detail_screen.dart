import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/poll.dart';
import '../cubits/poll/poll_cubit.dart';
import '../cubits/poll/poll_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../widgets/common/summit_app_bar.dart';

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
    _selectedOptionIds = Set.from(widget.poll.myVotes);
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
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PollCubit, PollState>(
      listener: (context, state) {},
      builder: (context, state) {
        final settingsState = context.watch<SettingsCubit>().state;
        final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

        Poll freshPoll = widget.poll;
        if (state is PollLoaded) {
          try {
            freshPoll = state.polls.firstWhere((p) => p.id == widget.poll.id);
          } catch (_) {}
        }

        return Scaffold(
          appBar: SummitAppBar(title: const Text('投票詳情')),
          body: _isSubmitting || (state is PollLoading && state is! PollLoaded)
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 800;

                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main Content (Left)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHeaderSection(context, freshPoll),
                                      const Divider(height: 48),
                                      _buildOptionsList(freshPoll, isOffline),
                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                // Sidebar (Right)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoCard(context, freshPoll, isOffline),
                                      const SizedBox(height: 24),
                                      _buildActionButtons(context, freshPoll, isOffline),
                                      if (state is PollLoaded && freshPoll.creatorId == state.currentUserId) ...[
                                        const SizedBox(height: 24),
                                        _buildManagementActions(context, freshPoll, isOffline),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          // Mobile View
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(context, freshPoll),
                              if (isOffline) ...[const SizedBox(height: 16), _buildOfflineWarning()],
                              const Divider(height: 32),
                              _buildOptionsList(freshPoll, isOffline),
                              const SizedBox(height: 32),
                              _buildActionButtons(context, freshPoll, isOffline),
                              if (state is PollLoaded && freshPoll.creatorId == state.currentUserId) ...[
                                const SizedBox(height: 24),
                                _buildManagementActions(context, freshPoll, isOffline),
                              ],
                              const SizedBox(height: 100),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, Poll poll) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (poll.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text('進行中', style: TextStyle(color: Colors.green.shade800, fontSize: 12)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                child: const Text('已結束', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(poll.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          '發起人: ${poll.creatorId}  •  ${DateFormat('yyyy/MM/dd HH:mm').format(poll.createdAt)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
        if (poll.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(poll.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            if (poll.allowMultipleVotes)
              Chip(
                label: const Text('多選'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.blue.shade50,
                labelStyle: TextStyle(color: Colors.blue.shade800),
                side: BorderSide.none,
              ),
            if (poll.isAllowAddOption)
              Chip(
                label: const Text('允許新增'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.orange.shade50,
                labelStyle: TextStyle(color: Colors.orange.shade800),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, Poll poll, bool isOffline) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (poll.deadline != null) ...[
              _buildInfoRow(Icons.timer_outlined, '截止時間', DateFormat('yyyy/MM/dd HH:mm').format(poll.deadline!)),
              const Divider(height: 24),
            ],
            _buildInfoRow(Icons.how_to_vote_outlined, '目前總票數', '${poll.totalVotes} 票'),
            if (isOffline) ...[const SizedBox(height: 16), _buildOfflineWarning()],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildOfflineWarning() {
    return Container(
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
            child: Text('離線模式中，無法投票或編輯', style: TextStyle(color: Colors.orange.shade900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList(Poll poll, bool isOffline) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: poll.options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final option = poll.options[index];
        final isSelected = _selectedOptionIds.contains(option.id);
        final percentage = poll.totalVotes > 0 ? option.voteCount / poll.totalVotes : 0.0;
        final votersList = option.voters.map((v) => v['user_name'] ?? v['user_id']).join(', ');
        final canInteract = poll.isActive && !isOffline;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: canInteract ? () => _toggleOption(option.id, poll.allowMultipleVotes) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (poll.isActive)
                          Padding(
                            padding: const EdgeInsets.only(right: 12, top: 2),
                            child: Icon(
                              poll.allowMultipleVotes
                                  ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                                  : (isSelected ? Icons.radio_button_checked : Icons.radio_button_off),
                              color: canInteract
                                  ? (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey)
                                  : Colors.grey.shade300,
                              size: 24,
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
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
                        if (poll.isActive && option.voteCount == 0 && !isOffline)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('刪除選項'),
                                  content: Text('確定要刪除 "${option.text}" 嗎？'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('刪除')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                if (!context.mounted) return;
                                setState(() => _isSubmitting = true);
                                try {
                                  await context.read<PollCubit>().deleteOption(pollId: poll.id, optionId: option.id);
                                } finally {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (votersList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                child: Text(
                  '投票者: $votersList',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, Poll poll, bool isOffline) {
    if (!poll.isActive) return const SizedBox.shrink();

    return Column(
      children: [
        if (poll.isAllowAddOption) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isOffline ? null : () => _addOption(context.read<PollCubit>(), poll.id),
              icon: const Icon(Icons.add),
              label: const Text('新增選項'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isOffline ? null : () => _submitVote(context.read<PollCubit>(), poll.id),
            icon: const Icon(Icons.check),
            label: const Text('送出投票'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementActions(BuildContext context, Poll poll, bool isOffline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text('管理投票', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isOffline
                ? null
                : () async {
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
                      if (!context.mounted) return;
                      setState(() => _isSubmitting = true);
                      try {
                        await context.read<PollCubit>().deletePoll(pollId: poll.id);
                        if (context.mounted) Navigator.pop(context);
                      } finally {
                        if (context.mounted) setState(() => _isSubmitting = false);
                      }
                    }
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('刪除投票'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
