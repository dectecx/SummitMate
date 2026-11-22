import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/offline_manager.dart';
import '../domain/offline_regions.dart';
import '../domain/offline_view.dart';
import '../providers.dart';

/// Everything about offline maps on one screen: what is downloading, what is on the phone, and what
/// can still be downloaded. Progress is stored in the database, so it is all still here when the
/// person comes back to the screen.
class OfflineMapsPage extends ConsumerWidget {
  const OfflineMapsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(offlineRegionsProvider).value ?? const [];
    final sections = buildOfflineSections(rows);
    final manager = ref.watch(offlineManagerProvider);
    final theme = Theme.of(context);

    Widget header(String text) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 4), child: Text(text, style: theme.textTheme.titleSmall));

    return Scaffold(
      appBar: AppBar(title: const Text('離線地圖')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已下載 ${sections.done.length} 個區域，使用 ${formatBytes(sections.usedBytes)}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('地圖來源：內政部國土測繪中心。山上沒有訊號，出發前先下載。建議使用 Wi-Fi，下載會在背景繼續進行。', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          if (sections.active.isNotEmpty) ...[
            header('下載中與待處理'),
            for (final e in sections.active) _ActiveTile(entry: e, manager: manager),
          ],
          if (sections.done.isNotEmpty) ...[
            header('已下載'),
            for (final e in sections.done) _DoneTile(entry: e, manager: manager),
          ],
          header('可下載'),
          if (sections.available.isEmpty) const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 0), child: Text('所有區域都已下載或正在下載。')),
          for (final e in sections.available) _AvailableTile(entry: e, manager: manager),
        ],
      ),
    );
  }
}

class _AvailableTile extends StatelessWidget {
  const _AvailableTile({required this.entry, required this.manager});
  final OfflineEntry entry;
  final OfflineMapsManager manager;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('available-${entry.def.id}'),
      title: Text(entry.def.name),
      subtitle: Text('${entry.def.description}\n約 ${formatBytes(entry.def.estimatedBytes)}'),
      isThreeLine: true,
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(minimumSize: const Size(72, 40)),
        onPressed: () {
          manager.start(entry.def.id);
          // The row moves to the section at the top, which may be out of view: say what happened.
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已加入下載：${entry.def.name}（可切到背景，進度在畫面上方）')));
        },
        child: const Text('下載'),
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({required this.entry, required this.manager});
  final OfflineEntry entry;
  final OfflineMapsManager manager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = entry.row!;
    final percent = (entry.progress * 100).round();
    final (label, actions) = switch (row.state) {
      OfflineState.downloading => ('下載中 $percent%（${formatBytes(row.bytes)}）', <Widget>[_Action('取消', () => manager.cancel(entry.def.id))]),
      OfflineState.queued => ('等待中', <Widget>[_Action('取消', () => manager.cancel(entry.def.id))]),
      OfflineState.interrupted => ('已中斷 $percent%', <Widget>[_Action('繼續', () => manager.start(entry.def.id)), _Action('取消', () => manager.cancel(entry.def.id))]),
      _ => ('下載失敗${row.error == null ? '' : '：${row.error}'}', <Widget>[_Action('重試', () => manager.start(entry.def.id)), _Action('取消', () => manager.cancel(entry.def.id))]),
    };
    return Padding(
      key: ValueKey('active-${entry.def.id}'),
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(entry.def.name, style: theme.textTheme.titleMedium)), ...actions]),
          const SizedBox(height: 4),
          if (row.state == OfflineState.downloading || row.state == OfflineState.interrupted) LinearProgressIndicator(value: entry.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: row.state == OfflineState.failed ? theme.colorScheme.error : null)),
        ],
      ),
    );
  }
}

class _DoneTile extends StatelessWidget {
  const _DoneTile({required this.entry, required this.manager});
  final OfflineEntry entry;
  final OfflineMapsManager manager;

  @override
  Widget build(BuildContext context) {
    final row = entry.row!;
    return ListTile(
      key: ValueKey('done-${entry.def.id}'),
      leading: const Icon(Icons.check_circle, color: Colors.green),
      title: Text(entry.def.name),
      subtitle: Text('${formatBytes(row.bytes)}  ·  ${row.updatedAt.year}/${row.updatedAt.month}/${row.updatedAt.day}'),
      trailing: IconButton(
        tooltip: '刪除 ${entry.def.name}',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('刪除「${entry.def.name}」？'),
              content: const Text('這個區域的離線地圖會從手機移除（和其他區域共用的圖磚會保留）。'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(88, 44)), onPressed: () => Navigator.pop(ctx, true), child: const Text('刪除')),
              ],
            ),
          );
          if (ok == true) await manager.delete(entry.def.id);
        },
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(onPressed: onPressed, child: Text(label));
}
