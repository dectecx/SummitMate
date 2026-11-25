import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/events_api.dart';
import '../domain/event_logic.dart';
import '../providers.dart';
import 'event_widgets.dart';
import '../../friends/ui/add_friend_button.dart';

/// The host's list of applications: approve, reject (with a reason) and remove members.
class ApplicationsPage extends ConsumerStatefulWidget {
  const ApplicationsPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends ConsumerState<ApplicationsPage> {
  EventDetail? _event;
  List<Application> _apps = const [];
  EventsException? _error;
  bool _loading = true;
  bool _busy = false;

  EventsApi get _api => ref.read(eventsApiProvider);
  String get _id => widget.eventId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final event = await _api.get(_id);
      final apps = await _api.applications(_id);
      if (!mounted) return;
      setState(() {
        _event = event;
        _apps = apps;
        _loading = false;
        _error = null;
      });
    } on EventsException catch (e) {
      if (!mounted) return;
      if (silent) return _snack(e.text);
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _act(Future<void> Function() body, {required String done}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await body();
      if (mounted) _snack(done);
    } on EventsException catch (e) {
      if (mounted) _snack(e.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    ref.invalidate(pendingApplicationsProvider);
    await _load(silent: true);
  }

  Future<void> _approve(Application a) =>
      _act(() => _api.review(_id, a.id, approve: true), done: '已通過 ${a.user.displayName}');

  Future<void> _reject(Application a) async {
    final reason = await askText(
      context,
      title: '拒絕 ${a.user.displayName}？',
      message: '可以留下原因，對方會在揪團頁看到。',
      hint: '拒絕原因（選填）',
      confirm: '拒絕',
      destructive: true,
      fieldKey: const ValueKey('reject-reason'),
      confirmKey: const ValueKey('reject-confirm'),
    );
    if (reason == null) return;
    await _act(() => _api.review(_id, a.id, approve: false, reason: reason), done: '已拒絕 ${a.user.displayName}');
  }

  Future<void> _remove(Application a) async {
    final yes = await confirmDialog(
      context,
      title: '移除 ${a.user.displayName}？',
      body: '對方會失去名額；若揪團連結了行程，也會被移出行程成員。',
      confirm: '移除',
      destructive: true,
    );
    if (!yes) return;
    await _act(() => _api.removeMember(_id, a.id), done: '已移除 ${a.user.displayName}');
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('管理申請')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: RetryMessage(text: _error?.text ?? '無法開啟', onRetry: _load),
              ),
      );
    }
    final theme = Theme.of(context);
    final pending = _apps.where((a) => a.status == ApplicationStatus.pending).toList();
    final approved = _apps.where((a) => a.status == ApplicationStatus.approved).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('管理申請')),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const IconTile(Icons.groups_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '已通過 ${peopleLabel(e.approvedCount, e.maxMembers)}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionCaption('待審核（${pending.length}）'),
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  '沒有待審核的申請。',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            for (final a in pending)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  key: ValueKey('app-${a.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: PersonLine(a.user, style: theme.textTheme.titleSmall)),
                            AddFriendButton(userId: a.user.id, name: a.user.displayName),
                          ],
                        ),
                        if (a.message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(a.message, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
                              key: ValueKey('reject-${a.id}'),
                              onPressed: _busy ? null : () => _reject(a),
                              child: const Text('拒絕'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                              key: ValueKey('approve-${a.id}'),
                              onPressed: _busy ? null : () => _approve(a),
                              child: const Text('通過'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SectionCaption('已通過（${approved.length}）'),
            if (approved.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  '還沒有成員。',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < approved.length; i++) ...[
                      if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant),
                      ListTile(
                        key: ValueKey('app-${approved[i].id}'),
                        shape: const RoundedRectangleBorder(),
                        title: PersonLine(approved[i].user, style: theme.textTheme.titleSmall),
                        subtitle: approved[i].message.isEmpty ? null : Text(approved[i].message),
                        trailing: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(88, 44),
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                          key: ValueKey('remove-${approved[i].id}'),
                          onPressed: _busy ? null : () => _remove(approved[i]),
                          child: const Text('移除成員'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
