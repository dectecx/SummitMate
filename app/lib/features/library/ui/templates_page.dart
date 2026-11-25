import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/settings_section.dart';
import '../../trips/providers.dart';
import '../domain/set_item.dart';
import '../providers.dart';
import 'template_actions.dart';
import '../../../shared/brand/illustrations.dart';

/// "我的範本": saved packing lists and meal plans.
class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).value ?? const <Template>[];
    return Scaffold(
      appBar: AppBar(title: const Text('我的範本')),
      body: templates.isEmpty
          ? const ComingSoon(
              illustration: Illustration.gear,
              message: '還沒有範本。\n在行程右上角選「存成範本」，就能把這個行程的裝備與餐點存起來，之後套用到別的行程。',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                SettingsSection(
                  children: [
                    for (final t in templates)
                      SettingsTile(
                        key: ValueKey('template-${t.id}'),
                        icon: Icons.inventory_2_outlined,
                        title: t.title,
                        subtitle: summaryOf(decodeSetItems(t.items)),
                        onTap: () => context.push(Routes.template(t.id)),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class TemplateDetailPage extends ConsumerWidget {
  const TemplateDetailPage({super.key, required this.templateId});
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(templateProvider(templateId)).value;
    if (t == null)
      return Scaffold(
        appBar: AppBar(),
        body: const ComingSoon(illustration: Illustration.search, message: '找不到這份範本，可能已被刪除'),
      );
    final items = decodeSetItems(t.items);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (v) async {
              final repo = ref.read(templateRepositoryProvider);
              if (v == 'rename') {
                final title = await askTemplateTitle(context, initial: t.title);
                if (title != null) await repo.update(t.id, title: title);
              } else if (v == 'share') {
                await shareTemplate(context, ref, t, signedIn: ref.read(accountIdProvider) != null);
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('刪除這份範本？'),
                    content: Text('「${t.title}」會被刪除，已經套用到行程的項目不受影響。'),
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
                if (ok == true) {
                  await repo.delete(t.id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('改名')),
              PopupMenuItem(value: 'share', child: Text('分享到雲端')),
              PopupMenuItem(value: 'delete', child: Text('刪除範本')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summaryOf(items),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('template-apply'),
                      onPressed: () => _applyToATrip(context, ref, items),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('套用到行程'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SetItemSections(items: items),
        ],
      ),
    );
  }

  Future<void> _applyToATrip(BuildContext context, WidgetRef ref, List<SetItem> items) async {
    final messenger = ScaffoldMessenger.of(context);
    final trips = ref.read(tripsProvider).value ?? const <Trip>[];
    if (trips.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('還沒有行程可以套用。')));
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
              child: Text('套用到哪個行程？', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final t in trips)
              ListTile(key: ValueKey('apply-trip-${t.id}'), title: Text(t.name), onTap: () => Navigator.pop(ctx, t)),
          ],
        ),
      ),
    );
    if (trip == null) return;
    final r = await ref.read(templateRepositoryProvider).applyToTrip(trip.id, items);
    messenger.showSnackBar(SnackBar(content: Text('${trip.name}：${resultText(r)}')));
  }
}
