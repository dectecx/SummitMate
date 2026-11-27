import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import '../domain/collab_logic.dart';
import '../providers.dart';
import 'poll_card.dart';
import 'poll_form_sheet.dart';
import '../../../shared/pills.dart';
import '../../../shared/link_text.dart';
import '../../../shared/brand/illustrations.dart';

/// "討論": two views, the message board (writing box pinned at the bottom) and the polls.
class DiscussionView extends ConsumerStatefulWidget {
  const DiscussionView({super.key, required this.trip, required this.role});
  final Trip trip;
  final TripRole role;

  @override
  ConsumerState<DiscussionView> createState() => _DiscussionViewState();
}

class _DiscussionViewState extends ConsumerState<DiscussionView> {
  final _text = TextEditingController();
  final _end = GlobalKey(); // the bottom of the board, scrolled to after sending
  bool _showPolls = false;
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
      if (mounted) {
        setState(() => _replyTo = null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final end = _end.currentContext;
          if (end != null && end.mounted) Scrollable.ensureVisible(end, alignment: 1);
        });
      }
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

    final openPolls = polls.where((p) => pollStateOf(p, ref.watch(clockProvider)()) == PollState.open).length;
    _MessageTile tile(TripMessage m, {bool reply = false}) => _MessageTile(
      message: m,
      author: author(m.userId),
      mine: isMineUser(m.userId, me.id),
      canDelete: canDeleteMessage(role: widget.role, isMine: isMineUser(m.userId, me.id)),
      indent: reply,
      onReply: !reply && canReplyTo(m) ? () => setState(() => _replyTo = m) : null,
      onDelete: () => _delete(m),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: PillSwitch(
            labels: ['留言', openPolls > 0 ? '投票 $openPolls' : '投票'],
            keys: const [ValueKey('discussion-messages'), ValueKey('discussion-polls')],
            selected: _showPolls ? 1 : 0,
            onSelected: (i) {
              FocusScope.of(context).unfocus();
              setState(() => _showPolls = i == 1);
            },
          ),
        ),
        Expanded(
          child: _showPolls
              ? ListView(
                  key: const ValueKey('poll-list'),
                  padding: const EdgeInsets.only(top: 4, bottom: 32),
                  children: [
                    if (canManagePolls(widget.role))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.tertiary, foregroundColor: theme.colorScheme.onTertiary),
                          onPressed: () => showPollFormSheet(context, tripId: trip.id),
                          icon: const Icon(Icons.how_to_vote_outlined),
                          label: const Text('建立投票'),
                        ),
                      ),
                    if (polls.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                        child: Column(
                          children: [
                            const IllustrationView(Illustration.star, width: 132),
                            const SizedBox(height: 8),
                            Text(
                              canManagePolls(widget.role) ? '還沒有投票，建立一個讓大家決定吧' : '還沒有投票',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    for (final p in polls) PollCard(key: ValueKey(p.id), poll: p, role: widget.role),
                  ],
                )
              : ListView(
                  key: const ValueKey('message-list'),
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  children: [
                    if (threads.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Column(
                          children: [
                            const IllustrationView(Illustration.chat, width: 132),
                            const SizedBox(height: 8),
                            Text('還沒有留言，說點什麼吧', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    for (final t in threads) ...[
                      tile(t.message),
                      for (final r in t.replies) tile(r, reply: true),
                    ],
                    SizedBox(key: _end, height: 1),
                  ],
                ),
        ),
        if (!_showPolls)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
                      IconButton(tooltip: '取消回覆', onPressed: () => setState(() => _replyTo = null), icon: const Icon(Icons.close, size: 18)),
                    ],
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: messageMaxLength,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(labelText: _replyTo == null ? '寫留言' : '寫回覆', errorText: _error),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: IconButton.filled(
                        tooltip: '送出',
                        style: IconButton.styleFrom(backgroundColor: theme.colorScheme.tertiary, foregroundColor: theme.colorScheme.onTertiary, minimumSize: const Size(48, 48)),
                        onPressed: _busy ? null : _send,
                        icon: const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One message as a speech bubble: mine on the right, the others on the left with their avatar.
class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.author,
    required this.mine,
    required this.canDelete,
    required this.onDelete,
    this.onReply,
    this.indent = false,
  });
  final TripMessage message;
  final Author author;
  final bool mine;
  final bool canDelete;
  final bool indent;
  final VoidCallback? onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const round = Radius.circular(18);
    const tail = Radius.circular(5);
    final avatar = CircleAvatar(radius: 16, backgroundColor: scheme.secondaryContainer, child: Text(author.avatar));
    final column = Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: author.name, style: theme.textTheme.labelMedium?.copyWith(color: author.departed ? scheme.onSurfaceVariant : scheme.onSurface)),
              TextSpan(text: '  ${formatStamp(message.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerLowest,
            border: mine ? null : Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.only(topLeft: mine ? round : tail, topRight: round, bottomLeft: round, bottomRight: mine ? tail : round),
          ),
          child: LinkText(message.body, style: theme.textTheme.bodyMedium?.copyWith(color: mine ? scheme.onPrimaryContainer : scheme.onSurface)),
        ),
        if (onReply != null || canDelete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onReply != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(44, 36), padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: onReply,
                  child: const Text('回覆'),
                ),
              if (canDelete)
                IconButton(
                  tooltip: '刪除留言',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB((indent && !mine ? 44 : 16), 6, 16, 2),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mine) const SizedBox(width: 56),
          if (!mine) ...[avatar, const SizedBox(width: 10)],
          Flexible(child: column),
          if (!mine) const SizedBox(width: 40),
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
