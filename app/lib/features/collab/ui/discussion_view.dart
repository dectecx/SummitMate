import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import '../domain/collab_logic.dart';
import '../providers.dart';
import 'poll_card.dart';
import 'poll_form_sheet.dart';

/// "討論": the message board on top, the polls below.
class DiscussionView extends ConsumerStatefulWidget {
  const DiscussionView({super.key, required this.trip, required this.role});
  final Trip trip;
  final TripRole role;

  @override
  ConsumerState<DiscussionView> createState() => _DiscussionViewState();
}

class _DiscussionViewState extends ConsumerState<DiscussionView> {
  final _text = TextEditingController();
  TripMessage? _replyTo;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = validateMessageBody(_text.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(messageRepositoryProvider)
          .add(widget.trip.id, _text.text, parentId: _replyTo?.id);
      _text.clear();
      if (mounted) setState(() => _replyTo = null);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = '${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(TripMessage m) async {
    final ok = await confirmDialog(
      context,
      title: '刪除這則留言？',
      message: '刪除後所有成員都看不到。',
      action: '刪除',
    );
    if (ok) {
      if (_replyTo?.id == m.id) setState(() => _replyTo = null);
      await ref.read(messageRepositoryProvider).delete(m.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final theme = Theme.of(context);
    final members =
        ref.watch(tripMembersProvider(trip.id)).value ?? const <TripMember>[];
    final me = ref.watch(myProfileProvider);
    final messages =
        ref.watch(messagesProvider(trip.id)).value ?? const <TripMessage>[];
    final polls = ref.watch(pollsProvider(trip.id)).value ?? const <Poll>[];
    final threads = buildThreads(messages);
    Author author(String? userId) => resolveAuthor(
      userId,
      members: members,
      myId: me.id,
      myName: me.name,
      myAvatar: me.avatar,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text('留言板', style: theme.textTheme.titleMedium),
        ),
        if (threads.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              '還沒有留言，說點什麼吧',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final t in threads) ...[
          _MessageTile(
            message: t.message,
            author: author(t.message.userId),
            canDelete: canDeleteMessage(
              role: widget.role,
              isMine: isMineUser(t.message.userId, me.id),
            ),
            onReply: canReplyTo(t.message)
                ? () => setState(() => _replyTo = t.message)
                : null,
            onDelete: () => _delete(t.message),
          ),
          for (final r in t.replies)
            _MessageTile(
              message: r,
              author: author(r.userId),
              canDelete: canDeleteMessage(
                role: widget.role,
                isMine: isMineUser(r.userId, me.id),
              ),
              indent: true,
              onDelete: () => _delete(r),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_replyTo != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '回覆 ${author(_replyTo!.userId).name}：${_replyTo!.body}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: '取消回覆',
                      onPressed: () => setState(() => _replyTo = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: messageMaxLength,
                      buildCounter: (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: _replyTo == null ? '寫留言' : '寫回覆',
                        errorText: _error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '送出',
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 40),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Row(
            children: [
              Expanded(child: Text('投票', style: theme.textTheme.titleMedium)),
              if (canManagePolls(widget.role))
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => showPollFormSheet(context, tripId: trip.id),
                  icon: const Icon(Icons.how_to_vote_outlined),
                  label: const Text('建立投票'),
                ),
            ],
          ),
        ),
        if (polls.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              canManagePolls(widget.role) ? '還沒有投票，建立一個讓大家決定吧' : '還沒有投票',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final p in polls)
          PollCard(key: ValueKey(p.id), poll: p, role: widget.role),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.author,
    required this.canDelete,
    required this.onDelete,
    this.onReply,
    this.indent = false,
  });
  final TripMessage message;
  final Author author;
  final bool canDelete;
  final bool indent;
  final VoidCallback? onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(indent ? 52 : 16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(author.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: author.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: author.departed
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      TextSpan(
                        text: '  ${formatStamp(message.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(message.body),
                if (onReply != null || canDelete)
                  Row(
                    children: [
                      if (onReply != null)
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: onReply,
                          child: const Text('回覆'),
                        ),
                      if (canDelete)
                        IconButton(
                          tooltip: '刪除留言',
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 20),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "M/d HH:mm" in local time.
String formatStamp(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.month}/${l.day} ${two(l.hour)}:${two(l.minute)}';
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 44),
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}
