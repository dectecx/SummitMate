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
    _MessageTile tile(TripMessage m, {bool reply = false, bool continues = false}) => _MessageTile(
      message: m,
      author: author(m.userId),
      mine: isMineUser(m.userId, me.id),
      canDelete: canDeleteMessage(role: widget.role, isMine: isMineUser(m.userId, me.id)),
      indent: reply,
      continues: continues,
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
                  padding: EdgeInsets.only(top: 4, bottom: 32 + MediaQuery.paddingOf(context).bottom),
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
                      tile(t.message, continues: t.replies.isNotEmpty),
                      for (final (i, r) in t.replies.indexed) tile(r, reply: true, continues: i < t.replies.length - 1),
                    ],
                    SizedBox(key: _end, height: 1),
                  ],
                ),
        ),
        if (!_showPolls)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 10 + MediaQuery.paddingOf(context).bottom), // clear of the bar below
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

/// One message, all aligned on the left: picture, name and time, then the text. A line joins a message to the
/// replies under it, so a conversation reads as one piece.
class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.author,
    required this.mine,
    required this.canDelete,
    required this.onDelete,
    this.onReply,
    this.indent = false,
    this.continues = false,
  });
  final TripMessage message;
  final Author author;
  final bool mine;
  final bool canDelete;
  final VoidCallback? onReply;
  final VoidCallback onDelete;

  /// A reply, set in under its parent.
  final bool indent;

  /// Another message of the same thread follows.
  final bool continues;

  static const _side = 20.0;
  static const _gap = 6.0;
  static const _radius = 16.0;
  static const _replyRadius = 12.0;
  static const _replyInset = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = indent ? _replyRadius : _radius;
    final avatar = CircleAvatar(radius: radius, backgroundColor: scheme.secondaryContainer, child: Text(author.avatar, style: TextStyle(fontSize: radius)));
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: author.name,
                style: theme.textTheme.labelLarge?.copyWith(color: mine ? scheme.primary : (author.departed ? scheme.onSurfaceVariant : scheme.onSurface)),
              ),
              TextSpan(text: '  ${formatStamp(message.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        LinkText(message.body, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface, height: 1.45)),
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
    return CustomPaint(
      painter: _ThreadLine(color: scheme.outlineVariant, reply: indent, continues: continues),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_side, _gap, _side, _gap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (indent) const SizedBox(width: _replyInset),
            avatar,
            const SizedBox(width: 10),
            Expanded(child: column),
          ],
        ),
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

/// The line of a thread, drawn in the margin of one message.
class _ThreadLine extends CustomPainter {
  const _ThreadLine({required this.color, required this.reply, required this.continues});
  final Color color;
  final bool reply;
  final bool continues;

  @override
  void paint(Canvas canvas, Size size) {
    const x = _MessageTile._side + _MessageTile._radius;
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (!reply) {
      if (continues) canvas.drawLine(const Offset(x, _MessageTile._gap + _MessageTile._radius * 2 + 4), Offset(x, size.height), ink);
      return;
    }
    const middle = _MessageTile._gap + _MessageTile._replyRadius;
    const turn = 10.0;
    final branch = Path()
      ..moveTo(x, 0)
      ..lineTo(x, middle - turn)
      ..quadraticBezierTo(x, middle, x + turn, middle)
      ..lineTo(_MessageTile._side + _MessageTile._replyInset - 4, middle);
    canvas.drawPath(branch, ink);
    if (continues) canvas.drawLine(const Offset(x, middle - turn), Offset(x, size.height), ink);
  }

  @override
  bool shouldRepaint(_ThreadLine old) => old.color != color || old.reply != reply || old.continues != continues;
}
