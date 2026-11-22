import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../library/providers.dart';
import '../../library/ui/library_suggestions.dart';
import '../domain/gear_logic.dart';
import '../providers.dart';

Future<void> showGearFormSheet(BuildContext context, {required String tripId, GearItem? item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => GearFormSheet(tripId: tripId, item: item),
  );
}

class GearFormSheet extends ConsumerStatefulWidget {
  const GearFormSheet({super.key, required this.tripId, this.item});
  final String tripId;
  final GearItem? item;

  @override
  ConsumerState<GearFormSheet> createState() => _GearFormSheetState();
}

class _GearFormSheetState extends ConsumerState<GearFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _weight = TextEditingController(text: (widget.item?.weight ?? 0) == 0 ? '' : _trim(widget.item!.weight));
  late final _quantity = TextEditingController(text: '${widget.item?.quantity ?? 1}');
  late GearCategory _category = GearCategory.fromKey(widget.item?.category ?? 'other');
  bool _busy = false;

  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(gearRepositoryProvider);
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantity.text.trim()) ?? 1;
    if (widget.item == null) {
      await repo.add(widget.tripId, name: _name.text.trim(), weight: weight, category: _category.key, quantity: quantity);
      await ref.read(libraryRepositoryProvider).remember(kind: 'gear', name: _name.text, category: _category.key, weight: weight);
    } else {
      await repo.update(widget.item!.id, name: _name.text.trim(), weight: weight, category: _category.key, quantity: quantity);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(gearRepositoryProvider).delete(widget.item!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(editing ? '編輯裝備' : '新增裝備', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: !editing,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().isEmpty ? '請輸入裝備名稱' : null,
                decoration: const InputDecoration(labelText: '名稱', hintText: '例如：睡袋'),
              ),
              if (!editing)
                LibrarySuggestions(
                  kind: 'gear',
                  controller: _name,
                  onPick: (i) => setState(() {
                    _name.text = i.name;
                    _category = GearCategory.fromKey(i.category);
                    _weight.text = i.weight == 0 ? '' : _trim(i.weight);
                  }),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GearCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: '分類'),
                items: [for (final c in GearCategory.values) DropdownMenuItem(value: c, child: Text(c.label))],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,1}'))],
                      decoration: const InputDecoration(labelText: '單件重量', suffixText: 'g'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) < 1 ? '至少 1 件' : null,
                      decoration: const InputDecoration(labelText: '數量'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _busy ? null : _save, child: Text(editing ? '儲存' : '新增')),
              if (editing)
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('刪除裝備'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
