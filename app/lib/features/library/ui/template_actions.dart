import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/settings_section.dart';
import '../../gear/domain/gear_logic.dart';
import '../../meals/domain/meal_logic.dart';
import '../data/shared_sets_api.dart';
import '../data/template_repository.dart';
import '../domain/set_item.dart';
import '../providers.dart';

/// Asks for a name and saves the trip's gear and meals as a template.
Future<void> saveTripAsTemplate(BuildContext context, WidgetRef ref, Trip trip) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(templateRepositoryProvider);
  final items = await repo.itemsOfTrip(trip.id);
  if (items.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('這個行程還沒有裝備或餐食，沒有東西可以存成範本。')));
    return;
  }
  if (!context.mounted) return;
  final title = await _askTitle(context, initial: trip.name);
  if (title == null) return;
  await repo.create(title: title, items: items);
  messenger.showSnackBar(SnackBar(content: Text('已存成範本「$title」（裝備 ${gearCountOf(items)}、餐食 ${mealCountOf(items)}）')));
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('套用哪一份範本？', style: Theme.of(ctx).textTheme.titleLarge),
          ),
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

String summaryOf(List<SetItem> items) =>
    '裝備 ${gearCountOf(items)} 件  ·  餐食 ${mealCountOf(items)} 項  ·  ${(gearWeightOf(items) / 1000).toStringAsFixed(1)} kg';

String resultText(ApplyResult r) {
  final parts = [if (r.gearAdded > 0) '裝備 ${r.gearAdded} 件', if (r.mealsAdded > 0) '餐食 ${r.mealsAdded} 項'];
  final skipped = r.gearSkipped > 0 ? '（${r.gearSkipped} 件已有，略過）' : '';
  return parts.isEmpty ? '沒有新增任何項目$skipped' : '已加入 ${parts.join('、')}$skipped';
}

Future<String?> _askTitle(BuildContext context, {String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('範本名稱'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 200,
        decoration: const InputDecoration(hintText: '例如：兩天一夜夏季'),
      ),
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

/// Shares a template to the cloud (needs a signed-in person and a connection).
Future<void> shareTemplate(BuildContext context, WidgetRef ref, Template template, {required bool signedIn}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!signedIn) {
    messenger.showSnackBar(const SnackBar(content: Text('登入後才能分享到雲端。')));
    return;
  }
  final items = decodeSetItems(template.items);
  if (items.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('這份範本是空的，沒有東西可以分享。')));
    return;
  }
  final choice = await showDialog<({String title, SharedVisibility visibility, String? key})>(
    context: context,
    builder: (_) => _ShareDialog(initialTitle: template.title),
  );
  if (choice == null) return;
  try {
    final s = await ref
        .read(sharedSetsApiProvider)
        .create(title: choice.title, visibility: choice.visibility, key: choice.key, items: items);
    final hint = s.visibility == SharedVisibility.protected ? '（Key：${choice.key}，請告訴想給的人）' : '';
    messenger.showSnackBar(SnackBar(content: Text('已分享「${s.title}」（${s.visibility.label}）$hint')));
  } on SharedSetsException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.text)));
  }
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.initialTitle});
  final String initialTitle;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  late final _title = TextEditingController(text: widget.initialTitle);
  final _key = TextEditingController();
  SharedVisibility _visibility = SharedVisibility.public;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _key.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final key = _key.text.trim();
    if (title.isEmpty) return setState(() => _error = '請輸入標題');
    if (_visibility == SharedVisibility.protected && !RegExp(r'^[A-Za-z0-9]{4,12}$').hasMatch(key)) {
      return setState(() => _error = 'Key 要 4 到 12 個英文字母或數字');
    }
    Navigator.pop(context, (
      title: title,
      visibility: _visibility,
      key: _visibility == SharedVisibility.protected ? key : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('分享到雲端'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              maxLength: 200,
              decoration: const InputDecoration(labelText: '標題'),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SharedVisibility>(
              key: const ValueKey('share-visibility'),
              segments: [for (final v in SharedVisibility.values) ButtonSegment(value: v, label: Text(v.label))],
              selected: {_visibility},
              onSelectionChanged: (s) => setState(() {
                _visibility = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 8),
            Text(switch (_visibility) {
              SharedVisibility.public => '所有人都找得到，也看得到內容。',
              SharedVisibility.protected => '所有人找得到標題，但要輸入 Key 才看得到內容。',
              SharedVisibility.private => '只有你看得到，等於雲端備份一份。',
            }, style: Theme.of(context).textTheme.bodySmall),
            if (_visibility == SharedVisibility.protected)
              TextField(
                controller: _key,
                decoration: const InputDecoration(labelText: 'Key（4 到 12 個英數字）'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          key: const ValueKey('share-confirm'),
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: _submit,
          child: const Text('分享'),
        ),
      ],
    );
  }
}

/// The gear and the meals of a set, each as a captioned card of rows (used by the template and shared-set pages).
class SetItemSections extends StatelessWidget {
  const SetItemSections({super.key, required this.items});
  final List<SetItem> items;

  @override
  Widget build(BuildContext context) {
    final gear = items.where((i) => i.isGear).toList();
    final meals = items.where((i) => i.isMeal).toList()..sort((a, b) => a.day.compareTo(b.day));
    String name(SetItem i) => i.quantity > 1 ? '${i.name} × ${i.quantity}' : i.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gear.isNotEmpty)
          SettingsSection(
            title: '裝備',
            children: [
              for (final i in gear)
                SettingsTile(
                  icon: Icons.backpack_outlined,
                  title: name(i),
                  subtitle: '${GearCategory.fromKey(i.category).label}  ·  ${formatWeight(i.weight)}',
                ),
            ],
          ),
        if (meals.isNotEmpty)
          SettingsSection(
            title: '餐食',
            children: [
              for (final i in meals)
                SettingsTile(
                  icon: Icons.restaurant_outlined,
                  title: name(i),
                  subtitle:
                      'D${i.day}  ·  ${MealType.fromKey(i.category).label}  ·  ${formatWeight(i.weight)}${i.calories > 0 ? '  ·  ${formatKcal(i.calories)}' : ''}',
                ),
            ],
          ),
      ],
    );
  }
}
