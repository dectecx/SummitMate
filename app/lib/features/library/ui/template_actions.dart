import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../data/template_repository.dart';
import '../domain/set_item.dart';
import '../providers.dart';

/// Asks for a name and saves the trip's gear and meals as a template.
Future<void> saveTripAsTemplate(BuildContext context, WidgetRef ref, Trip trip) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(templateRepositoryProvider);
  final items = await repo.itemsOfTrip(trip.id);
  if (items.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('這個行程還沒有裝備或餐點，沒有東西可以存成範本。')));
    return;
  }
  if (!context.mounted) return;
  final title = await _askTitle(context, initial: trip.name);
  if (title == null) return;
  await repo.create(title: title, items: items);
  messenger.showSnackBar(SnackBar(content: Text('已存成範本「$title」（裝備 ${gearCountOf(items)}、餐點 ${mealCountOf(items)}）')));
}

/// Lets the person pick a template and adds its items to the trip.
Future<void> applyTemplateToTrip(BuildContext context, WidgetRef ref, Trip trip) async {
  final messenger = ScaffoldMessenger.of(context);
  final templates = await ref.read(templateRepositoryProvider).watchAll().first;
  if (!context.mounted) return;
  if (templates.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('還沒有範本。先在某個行程選「存成範本」。')));
    return;
  }
  final picked = await showModalBottomSheet<Template>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 8), child: Text('套用哪一份範本？', style: Theme.of(ctx).textTheme.titleLarge)),
          for (final t in templates)
            ListTile(
              key: ValueKey('apply-${t.id}'),
              title: Text(t.title),
              subtitle: Text(summaryOf(decodeSetItems(t.items))),
              onTap: () => Navigator.pop(ctx, t),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  final r = await ref.read(templateRepositoryProvider).applyToTrip(trip.id, decodeSetItems(picked.items));
  messenger.showSnackBar(SnackBar(content: Text(resultText(r))));
}

String summaryOf(List<SetItem> items) => '裝備 ${gearCountOf(items)} 件  ·  餐點 ${mealCountOf(items)} 項  ·  ${(gearWeightOf(items) / 1000).toStringAsFixed(1)} kg';

String resultText(ApplyResult r) {
  final parts = [
    if (r.gearAdded > 0) '裝備 ${r.gearAdded} 件',
    if (r.mealsAdded > 0) '餐點 ${r.mealsAdded} 項',
  ];
  final skipped = r.gearSkipped > 0 ? '（${r.gearSkipped} 件已有，略過）' : '';
  return parts.isEmpty ? '沒有新增任何項目$skipped' : '已加入 ${parts.join('、')}$skipped';
}

Future<String?> _askTitle(BuildContext context, {String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('範本名稱'),
      content: TextField(controller: controller, autofocus: true, maxLength: 200, decoration: const InputDecoration(hintText: '例如：兩天一夜夏季')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () {
            final t = controller.text.trim();
            if (t.isNotEmpty) Navigator.pop(ctx, t);
          },
          child: const Text('儲存'),
        ),
      ],
    ),
  );
}

/// Same dialog for renaming.
Future<String?> askTemplateTitle(BuildContext context, {String initial = ''}) => _askTitle(context, initial: initial);
