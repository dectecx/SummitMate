import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../favorites/ui/favorite_event_button.dart';
import '../../trips/providers.dart';
import '../data/events_api.dart';
import '../domain/event_logic.dart';
import '../providers.dart';
import 'event_widgets.dart';
import '../../../shared/link_text.dart';

/// One group event: its content, the route preview, comments, and the action that fits the viewer.
class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final _comment = TextEditingController();
  EventDetail? _detail;
  EventsException? _error;
  bool _loading = true;
  bool _busy = false;
  final _comments = <EventComment>[];
  String? _commentCursor;
  bool _commentsLoading = false;

  EventsApi get _api => ref.read(eventsApiProvider);
  String get _id => widget.eventId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = ref.read(clockProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Loads the event and its first comments. [silent] keeps the page as it is while loading.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await _api.get(_id);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
        _error = null;
      });
      await _loadComments(reset: true);
    } on EventsException catch (e) {
      if (!mounted) return;
      if (silent && _detail != null) return _snack(e.text);
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadComments({bool reset = false}) async {
    setState(() => _commentsLoading = true);
    try {
      final page = await _api.comments(_id, cursor: reset ? null : _commentCursor);
      if (!mounted) return;
      setState(() {
        if (reset) _comments.clear();
        _comments.addAll(page.items);
        _commentCursor = page.nextCursor;
        _commentsLoading = false;
      });
    } on EventsException catch (e) {
      if (!mounted) return;
      setState(() => _commentsLoading = false);
      _snack(e.text);
    }
  }

  /// Runs a server call, shows its error, and refreshes the event when the server said it changed.
  Future<bool> _run(Future<void> Function() body) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await body();
      return true;
    } on EventsException catch (e) {
      if (!mounted) return false;
      _snack(e.text);
      if (const {'event_full', 'registration_closed', 'already_applied'}.contains(e.code)) await _load(silent: true);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _signedIn => ref.read(eventsSignedInProvider);

  Future<bool> _needSignIn() async {
    if (_signedIn) return false;
    await promptSignIn(context, next: Routes.event(_id));
    return true;
  }

  // ------------------------------------------------------------------ actions

  Future<void> _apply(EventDetail d) async {
    final msg = await askText(
      context,
      title: '申請加入',
      message: d.approvalRequired ? '主辦人審核後才會通過，可以留一段自我介紹。' : '這個揪團不需審核，送出後就直接加入。',
      hint: '給主辦人的訊息（選填）',
      confirm: '送出申請',
      fieldKey: const ValueKey('apply-message'),
      confirmKey: const ValueKey('apply-confirm'),
    );
    if (msg == null) return;
    ApplicationStatus? result;
    final ok = await _run(() async => result = await _api.apply(_id, message: msg));
    if (!ok || !mounted) return;
    _snack(result == ApplicationStatus.approved ? '已加入這個揪團' : '已送出申請，等主辦人審核');
    await _load(silent: true);
  }

  Future<void> _cancelApplication(EventDetail d) async {
    final joined = d.myStatus == ApplicationStatus.approved;
    final yes = await confirmDialog(
      context,
      title: joined ? '退出這個揪團？' : '取消申請？',
      body: joined ? '退出後會失去名額，也看不到隊員專屬留言。之後可以再次申請。' : '取消後可以再次申請。',
      confirm: joined ? '退出' : '取消申請',
      cancel: '不要',
      destructive: true,
    );
    if (!yes) return;
    final ok = await _run(() => _api.cancelApply(_id));
    if (!ok || !mounted) return;
    _snack(joined ? '已退出' : '已取消申請');
    await _load(silent: true);
  }

  Future<void> _toggleLike(EventDetail d) async {
    if (await _needSignIn()) return;
    LikeResult? r;
    final ok = await _run(() async => r = d.liked ? await _api.unlike(_id) : await _api.like(_id));
    final result = r;
    if (ok && mounted && result != null) {
      setState(() => _detail = _detail!.copyWith(liked: result.liked, likeCount: result.likeCount));
    }
  }

  Future<void> _report({required ReportTarget target, required String targetId}) async {
    if (await _needSignIn()) return;
    if (!mounted) return;
    final reason = await askText(
      context,
      title: target == ReportTarget.groupEvent ? '舉報這個揪團' : '舉報這則留言',
      message: '請簡單說明原因。',
      hint: '原因',
      confirm: '送出舉報',
      required: true,
      fieldKey: const ValueKey('report-reason'),
      confirmKey: const ValueKey('report-confirm'),
    );
    if (reason == null) return;
    final ok = await _run(() => _api.report(target: target, targetId: targetId, reason: reason));
    if (ok && mounted) _snack('已送出舉報，謝謝你的回報');
  }

  Future<void> _postComment() async {
    if (await _needSignIn()) return;
    final body = _comment.text.trim();
    if (body.isEmpty) return;
    EventComment? c;
    final ok = await _run(() async => c = await _api.addComment(_id, body));
    if (!ok || !mounted || c == null) return;
    setState(() {
      _comments.add(c!);
      _detail = _detail!.copyWith(commentCount: _detail!.commentCount + 1);
      _comment.clear();
    });
  }

  Future<void> _deleteComment(EventComment c) async {
    final yes = await confirmDialog(context, title: '刪除留言？', body: '刪除後無法復原。', confirm: '刪除', destructive: true);
    if (!yes) return;
    final ok = await _run(() => _api.deleteComment(_id, c.id));
    if (!ok || !mounted) return;
    setState(() {
      _comments.removeWhere((x) => x.id == c.id);
      _detail = _detail!.copyWith(commentCount: (_detail!.commentCount - 1).clamp(0, 1 << 30));
    });
  }

  Future<void> _edit() async {
    await context.push(Routes.eventEdit(_id));
    if (mounted) _load(silent: true);
  }

  Future<void> _manage() async {
    await context.push(Routes.eventApplications(_id));
    if (mounted) _load(silent: true);
  }

  Future<void> _setClosed(EventDetail d) async {
    final closing = d.status == EventStatus.open;
    if (closing) {
      final yes = await confirmDialog(context, title: '關閉報名？', body: '關閉後不能再申請，現有成員不受影響。之後可以重新開放。', confirm: '關閉報名');
      if (!yes) return;
    }
    final ok = await _run(() => _api.update(_id, status: closing ? EventStatus.closed : EventStatus.open));
    if (!ok || !mounted) return;
    _snack(closing ? '已關閉報名' : '已重新開放報名');
    await _load(silent: true);
  }

  Future<void> _cancelEvent() async {
    final yes = await confirmDialog(
      context,
      title: '取消揪團？',
      body: '取消後揪團不會再出現在列表，已申請的人仍看得到。連結的行程與成員不會改變。',
      confirm: '取消揪團',
      cancel: '不要',
      destructive: true,
    );
    if (!yes) return;
    final ok = await _run(() => _api.cancel(_id));
    if (!ok || !mounted) return;
    _snack('已取消揪團');
    context.pop();
  }

  void _onBottom(EventDetail d, BottomAction a) {
    switch (a.kind) {
      case EventAction.host:
        _manage();
      case EventAction.signIn:
        _needSignIn();
      case EventAction.apply || EventAction.reapply:
        _apply(d);
      case EventAction.pending || EventAction.approved:
        _cancelApplication(d);
      case EventAction.closed || EventAction.full || EventAction.expired || EventAction.cancelled:
        break;
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: RetryMessage(text: _error?.text ?? '無法開啟', onRetry: _load),
              ),
      );
    }
    // Rebuild when signing in or out.
    final signedIn = ref.watch(eventsSignedInProvider);
    final action = bottomActionFor(d, signedIn: signedIn, today: _today);
    return Scaffold(
      appBar: AppBar(
        title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [FavoriteEventButton(eventId: d.id), _menu(d)],
      ),
      bottomNavigationBar: _bottomBar(d, action),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [..._header(d), ..._body(d, signedIn)],
        ),
      ),
    );
  }

  Widget _menu(EventDetail d) {
    final items = <PopupMenuEntry<String>>[
      if (d.isHost && d.status != EventStatus.cancelled) ...[
        const PopupMenuItem(value: 'edit', child: Text('編輯')),
        const PopupMenuItem(value: 'manage', child: Text('管理申請')),
        PopupMenuItem(value: 'close', child: Text(d.status == EventStatus.open ? '關閉報名' : '重新開放報名')),
        const PopupMenuItem(value: 'cancel', child: Text('取消揪團')),
      ],
      if (!d.isHost) const PopupMenuItem(value: 'report', child: Text('舉報這個揪團')),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      key: const ValueKey('event-menu'),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            _edit();
          case 'manage':
            _manage();
          case 'close':
            _setClosed(d);
          case 'cancel':
            _cancelEvent();
          case 'report':
            _report(target: ReportTarget.groupEvent, targetId: d.id);
        }
      },
      itemBuilder: (_) => items,
    );
  }

  List<Widget> _header(EventDetail d) {
    final theme = Theme.of(context);
    return [
      EventTags(d, today: _today),
      const SizedBox(height: 8),
      Text(d.title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 8),
      PersonLine(d.host, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 12),
      _InfoRow(Icons.calendar_month_outlined, formatEventDates(d.startDate, d.endDate)),
      if (d.location.isNotEmpty) _InfoRow(Icons.place_outlined, d.location),
      _InfoRow(
        Icons.group_outlined,
        '${peopleLabel(d.approvedCount, d.maxMembers)}  ·  ${d.approvalRequired ? '需主辦人審核' : '免審核，直接加入'}',
      ),
      if (d.description.isNotEmpty) ...[
        const SizedBox(height: 12),
        LinkText(d.description, style: theme.textTheme.bodyLarge),
      ],
    ];
  }

  List<Widget> _body(EventDetail d, bool signedIn) {
    final theme = Theme.of(context);
    final snap = d.tripSnapshot;
    final hasPrivate = (d.privateMessage ?? '').isNotEmpty && !d.privateMessageLocked;
    return [
      const SizedBox(height: 8),
      Row(
        children: [
          TextButton.icon(
            key: const ValueKey('event-like'),
            onPressed: _busy ? null : () => _toggleLike(d),
            icon: Icon(d.liked ? Icons.favorite : Icons.favorite_border),
            label: Text('${d.likeCount}'),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chat_bubble_outline, size: 18),
          const SizedBox(width: 6),
          Text('${d.commentCount}'),
        ],
      ),
      if (d.myStatus == ApplicationStatus.rejected && !d.isHost)
        Card(
          key: const ValueKey('event-rejected'),
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主辦人沒有通過你的申請',
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                ),
                if (d.myRejectionReason != null)
                  Text('原因：${d.myRejectionReason}', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ],
            ),
          ),
        ),
      if (snap != null) _SnapshotCard(snap),
      if (hasPrivate)
        Card(
          key: const ValueKey('event-private'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_open_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('隊員專屬留言', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 6),
                LinkText(d.privateMessage!),
              ],
            ),
          ),
        )
      else if (d.privateMessageLocked)
        Card(
          key: const ValueKey('event-private-locked'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('隊員專屬留言：通過申請後才看得到', style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      Text('留言（${d.commentCount}）', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (_comments.isEmpty && !_commentsLoading)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('還沒有留言。', style: theme.textTheme.bodyMedium),
        ),
      for (final c in _comments) _commentTile(c, d),
      if (_commentsLoading)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (!_commentsLoading && _commentCursor != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('comments-more'),
            onPressed: () => _loadComments(),
            child: const Text('載入更多留言'),
          ),
        ),
      const SizedBox(height: 8),
      if (signedIn)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('comment-input'),
                controller: _comment,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '寫下留言（公開）'),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filled(
                key: const ValueKey('comment-send'),
                tooltip: '送出留言',
                onPressed: _busy ? null : _postComment,
                icon: const Icon(Icons.send),
              ),
            ),
          ],
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const ValueKey('comment-signin'),
            onPressed: _needSignIn,
            child: const Text('登入後留言'),
          ),
        ),
    ];
  }

  Widget _commentTile(EventComment c, EventDetail d) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('comment-${c.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonLine(c.user, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                LinkText(c.body),
              ],
            ),
          ),
          if (c.mine || d.isHost)
            IconButton(
              key: ValueKey('comment-delete-${c.id}'),
              tooltip: '刪除留言',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : () => _deleteComment(c),
            ),
          if (!c.mine)
            IconButton(
              key: ValueKey('comment-report-${c.id}'),
              tooltip: '舉報留言',
              icon: const Icon(Icons.flag_outlined),
              onPressed: _busy ? null : () => _report(target: ReportTarget.groupEventComment, targetId: c.id),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar(EventDetail d, BottomAction a) {
    final onTap = a.enabled && !_busy ? () => _onBottom(d, a) : null;
    final tonal = a.kind == EventAction.pending || a.kind == EventAction.approved;
    final style = FilledButton.styleFrom(minimumSize: const Size.fromHeight(48));
    final hint = switch (a.kind) {
      EventAction.pending => '等待主辦人審核，點按鈕可以取消申請',
      EventAction.approved => '點按鈕可以退出這個揪團',
      _ => null,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(hint, style: Theme.of(context).textTheme.bodySmall),
              ),
            tonal
                ? FilledButton.tonal(
                    key: const ValueKey('event-action'),
                    style: style,
                    onPressed: onTap,
                    child: Text(a.label),
                  )
                : FilledButton(
                    key: const ValueKey('event-action'),
                    style: style,
                    onPressed: onTap,
                    child: Text(a.label),
                  ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// The route preview of the linked trip.
class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard(this.snapshot);
  final TripSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = snapshotByDay(snapshot);
    return Card(
      key: const ValueKey('event-snapshot'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('行程路線', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              '${snapshot.name}  ·  ${formatEventDates(snapshot.startDate, snapshot.endDate)}',
              style: theme.textTheme.bodySmall,
            ),
            if (days.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('還沒有節點。', style: theme.textTheme.bodyMedium),
              ),
            for (final e in days.entries) ...[
              const SizedBox(height: 10),
              Text('D${e.key}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
              for (final i in e.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(width: 52, child: Text(i.time ?? '––:––', style: theme.textTheme.bodySmall)),
                      Expanded(child: Text(i.name)),
                      if (i.altitude > 0) Text('${i.altitude} m', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
