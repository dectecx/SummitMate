import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/page_accents.dart';
import '../../../core/db/app_database.dart';
import '../../trips/providers.dart';
import '../data/shared_sets_api.dart';
import '../providers.dart';
import 'shared_sets_page.dart';
import 'template_actions.dart';

/// One shared set: its content and what can be done with it.
class SharedSetDetailPage extends ConsumerStatefulWidget {
  const SharedSetDetailPage({super.key, required this.setId});
  final String setId;

  @override
  ConsumerState<SharedSetDetailPage> createState() => _SharedSetDetailPageState();
}

class _SharedSetDetailPageState extends ConsumerState<SharedSetDetailPage> {
  SharedSetDetail? _detail;
  SharedSetsException? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _open();
  }

  /// Opens the set, asking for the Key when the set needs one.
  Future<void> _open({String? key}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ref.read(sharedSetsApiProvider).get(widget.setId, key: key);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } on SharedSetsException catch (e) {
      if (!mounted) return;
      if (e.needsKey || e.wrongKey) {
        final typed = await _askKey(wrong: e.wrongKey);
        if (!mounted) return;
        if (typed != null) return _open(key: typed);
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<String?> _askKey({required bool wrong}) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('這份組合需要 Key'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Key', errorText: wrong ? 'Key 不正確' : null),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('開啟'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsTemplate(SharedSetDetail d) async {
    await ref.read(templateRepositoryProvider).create(title: d.summary.title, items: d.items);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已存成我的範本「${d.summary.title}」')));
  }

  Future<void> _addToTrip(SharedSetDetail d) async {
    final messenger = ScaffoldMessenger.of(context);
    // Read the database: the shared stream pauses while the trips tab is out of view, so its value can be stale.
    final trips = await ref.read(tripRepositoryProvider).watchAll().first;
    if (!mounted) return;
    if (trips.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('還沒有行程可以加入。')));
      return;
    }
    final trip = await showModalBottomSheet<Trip>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('加到哪個行程？', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final t in trips)
              ListTile(key: ValueKey('add-trip-${t.id}'), title: Text(t.name), onTap: () => Navigator.pop(ctx, t)),
          ],
        ),
      ),
    );
    if (trip == null) return;
    final r = await ref.read(templateRepositoryProvider).applyToTrip(trip.id, d.items);
    messenger.showSnackBar(SnackBar(content: Text('${trip.name}：${resultText(r)}')));
  }

  Future<void> _delete(SharedSetDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消分享？'),
        content: Text('「${d.summary.title}」會從雲端刪除，其他人就看不到了。你自己的範本不受影響。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 44),
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('取消分享'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(sharedSetsApiProvider).delete(d.summary.id);
      if (mounted) context.pop();
    } on SharedSetsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = _detail;
    if (d == null) {
      return PageAccents.inner(child: Scaffold(
        appBar: AppBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error?.text ?? '無法開啟', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: () => _open(), child: const Text('重試')),
                    ],
                  ),
                ),
              ),
      ));
    }
    return PageAccents.inner(child: Scaffold(
      appBar: AppBar(title: Text(d.summary.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${d.summary.authorName}  ·  ${d.summary.visibility.label}\n${summaryText(d.summary)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('shared-save'),
                      onPressed: () => _saveAsTemplate(d),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('存成我的範本'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      key: const ValueKey('shared-add'),
                      onPressed: () => _addToTrip(d),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('加到行程'),
                    ),
                    if (d.summary.mine) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        key: const ValueKey('shared-delete'),
                        onPressed: () => _delete(d),
                        icon: const Icon(Icons.cloud_off_outlined),
                        label: const Text('取消分享'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SetItemSections(items: d.items),
        ],
      ),
    ));
  }
}
