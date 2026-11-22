import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import '../domain/collab_logic.dart';
import '../providers.dart';
import 'discussion_view.dart';

/// One poll: its options with vote buttons and result bars, plus the actions the role allows.
class PollCard extends ConsumerStatefulWidget {
  const PollCard({super.key, required this.poll, required this.role});
  final Poll poll;
  final TripRole role;

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  final _newOption = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _newOption.dispose();
    super.dispose();
  }

  Future<void> _addOption() async {
    final text = _newOption.text;
    final error = validateOptionText(text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    try {
      await ref.read(pollRepositoryProvider).addOption(widget.poll.id, text);
      _newOption.clear();
      if (mounted) setState(() => _error = null);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = '${e.message}');
    }
  }

  Future<void> _deletePoll() async {
    final ok = await confirmDialog(
      context,
      title: '刪除這個投票？',
      message: '選項與所有人的投票都會一併刪除。',
      action: '刪除',
    );
    if (ok) await ref.read(pollRepositoryProvider).delete(widget.poll.id);
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = ref.watch(clockProvider)();
    final me = ref.watch(myProfileProvider);
    final members =
        ref.watch(tripMembersProvider(poll.tripId)).value ??
        const <TripMember>[];
    final options =
        ref.watch(pollOptionsProvider(poll.tripId)).value ??
        const <PollOption>[];
    final votes =
        ref.watch(pollVotesProvider(poll.tripId)).value ?? const <PollVote>[];
    final state = pollStateOf(poll, now);
    final tally = tallyPoll(
      poll: poll,
      options: options,
      votes: votes,
      state: state,
      myId: me.id,
    );
    final repo = ref.read(pollRepositoryProvider);
    final voting = canVote(state);
    final manage = canManagePolls(widget.role);
    String nameOf(String id) => id == guestVoterId
        ? (me.name.isEmpty ? '我' : me.name)
        : resolveAuthor(
            id,
            members: members,
            myId: me.id,
            myName: me.name,
            myAvatar: me.avatar,
          ).name;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(poll.title, style: theme.textTheme.titleMedium),
                  ),
                ),
                if (manage)
                  PopupMenuButton<String>(
                    tooltip: '投票選單',
                    onSelected: (v) {
                      if (v == 'close') repo.setClosed(poll.id, true);
                      if (v == 'reopen') repo.setClosed(poll.id, false);
                      if (v == 'delete') _deletePoll();
                    },
                    itemBuilder: (_) => [
                      if (poll.status == 'open')
                        const PopupMenuItem(value: 'close', child: Text('結束投票'))
                      else
                        const PopupMenuItem(
                          value: 'reopen',
                          child: Text('重新開啟'),
                        ),
                      const PopupMenuItem(value: 'delete', child: Text('刪除投票')),
                    ],
                  ),
              ],
            ),
            if (poll.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Text(poll.description),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Tag(switch (state) {
                    PollState.open => '進行中',
                    PollState.closed => '已結束',
                    PollState.expired => '已截止',
                  }, strong: voting),
                  _Tag(poll.allowMultiple ? '可多選' : '單選'),
                  if (poll.blind) const _Tag('盲投'),
                  if (poll.deadline != null)
                    _Tag('截止 ${formatStamp(poll.deadline!)}'),
                ],
              ),
            ),
            if (!tally.showResults)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Text(
                  '盲投：結果會在投票結束或截止後公開',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            for (final t in tally.options)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: voting ? () => repo.toggle(t.option.id) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 10),
                        child: Icon(
                          poll.allowMultiple
                              ? (t.mine
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank)
                              : (t.mine
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked),
                          color: t.mine
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          semanticLabel: t.mine ? '已投' : '未投',
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(t.option.label)),
                                if (tally.showResults)
                                  Text(
                                    '${t.count} 票',
                                    style: theme.textTheme.labelLarge,
                                  ),
                              ],
                            ),
                            if (tally.showResults) ...[
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: tally.voterCount == 0
                                    ? 0
                                    : t.count / tally.voterCount,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              if (t.voterIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    t.voterIds.map(nameOf).join('、'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      if (canDeleteOption(
                        role: widget.role,
                        option: t.option,
                        myId: me.id,
                      ))
                        IconButton(
                          tooltip: '刪除選項',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => repo.deleteOption(t.option.id),
                          icon: const Icon(Icons.close, size: 18),
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            if (canAddOption(role: widget.role, poll: poll, state: state))
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newOption,
                        maxLength: pollOptionMaxLength,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                        decoration: InputDecoration(
                          labelText: '新增選項',
                          errorText: _error,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addOption(),
                      ),
                    ),
                    IconButton(
                      tooltip: '加入選項',
                      onPressed: _addOption,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.strong = false});
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: strong
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
