import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/app_database.dart';
import '../data/gpx_library.dart';
import '../domain/gpx_models.dart';
import '../providers.dart';
import 'route_format.dart';

/// Above this total the panel suggests clearing out routes. Nothing is ever deleted on its own.
const gpxStorageWarningBytes = 200 * 1024 * 1024;

/// "我的路線": the GPX files kept in the app. Returns the id of the chosen route.
Future<String?> showRouteLibrary(BuildContext context, {String title = '我的路線'}) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _RouteLibrary(title: title),
);

class _RouteLibrary extends ConsumerStatefulWidget {
  const _RouteLibrary({required this.title});
  final String title;

  @override
  ConsumerState<_RouteLibrary> createState() => _RouteLibraryState();
}

class _RouteLibraryState extends ConsumerState<_RouteLibrary> {
  String? _message; // shown inside the panel: a snack bar would sit behind it
  bool _busy = false;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final file = await ref.read(gpxPickerProvider)();
      if (file == null) return;
      final added = await ref.read(gpxLibraryProvider).add(file.bytes, fileName: file.name);
      if (!mounted) return;
      if (!added.isNew) setState(() => _message = '這個檔案已經匯入過：「${added.route.name}」');
    } on GpxFormatException catch (e) {
      if (mounted) setState(() => _message = '這個檔案不能用：${e.message}');
    } on GpxTooLargeException {
      if (mounted) setState(() => _message = '檔案超過 ${formatBytesShort(maxGpxBytes)}，無法匯入。');
    } on Object catch (e, st) {
      debugPrint('GPX import failed: $e\n$st');
      if (mounted) setState(() => _message = '無法讀取這個檔案，請換一個 GPX 檔再試。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(GpxRoute r) async {
    final controller = TextEditingController(text: r.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('改名'),
        content: TextField(
          key: const ValueKey('route-name'),
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '路線名稱'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) await ref.read(gpxLibraryProvider).rename(r.id, name);
  }

  Future<void> _export(GpxRoute r) async {
    final file = await ref.read(gpxLibraryProvider).fileOf(r.id);
    if (!file.existsSync()) return;
    final safe = r.name.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/gpx+xml')],
        fileNameOverrides: ['${safe.isEmpty ? 'route' : safe}.gpx'],
        subject: r.name,
      ),
    );
  }

  Future<void> _delete(GpxRoute r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除這條路線？'),
        content: Text('「${r.name}」的檔案會從這支手機移除。行程上附加過的路線不受影響。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 44),
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(gpxLibraryProvider).delete(r.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final routes = ref.watch(gpxRoutesProvider).value ?? const <GpxRoute>[];
    final total = routes.fold<int>(0, (sum, r) => sum + r.sizeBytes);
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.title, style: theme.textTheme.titleLarge)),
                FilledButton.icon(
                  key: const ValueKey('route-import'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.file_upload_outlined, size: 20),
                  label: const Text('匯入 GPX'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (routes.isNotEmpty) Text('共 ${routes.length} 條  ·  占用 ${formatBytesShort(total)}', style: muted),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            if (_message case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message, style: TextStyle(color: scheme.error)),
              ),
            if (total > gpxStorageWarningBytes)
              Card(
                key: const ValueKey('route-storage-warning'),
                color: scheme.tertiaryContainer,
                margin: const EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('路線檔已占用 ${formatBytesShort(total)}，可以刪掉用不到的來清出空間。'),
                ),
              ),
            if (routes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '還沒有路線。\n匯入下載好的 GPX 檔，就能在魯地圖上看路線和高度圖。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            for (final r in routes)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  key: ValueKey('route-${r.id}'),
                  onTap: () => Navigator.pop(context, r.id),
                  title: Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  // The route first, the file second, so neither line breaks in the middle of a figure.
                  subtitle: Text(
                    '${formatKm(r.distanceKm)}  ·  ${r.ascent == null ? '沒有海拔資料' : '↑ ${formatMetres(r.ascent!)}'}\n'
                    '${r.hasTime ? '有時間紀錄  ·  ' : ''}${formatBytesShort(r.sizeBytes)}',
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: '管理 ${r.name}',
                    onSelected: (v) => switch (v) {
                      'rename' => _rename(r),
                      'export' => _export(r),
                      _ => _delete(r),
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('改名')),
                      PopupMenuItem(value: 'export', child: Text('匯出原檔')),
                      PopupMenuItem(value: 'delete', child: Text('刪除')),
                    ],
                  ),
                ),
              ),
            if (routes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('路線只存在這支手機。', style: muted),
              ),
          ],
        ),
      ),
    );
  }
}
