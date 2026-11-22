import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../library/providers.dart';
import '../../library/ui/library_suggestions.dart';
import '../domain/meal_logic.dart';
import '../providers.dart';

Future<void> showMealFormSheet(BuildContext context, {required String tripId, required int dayIndex, MealEntry? entry}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => MealFormSheet(tripId: tripId, dayIndex: dayIndex, entry: entry),
  );
}

class MealFormSheet extends ConsumerStatefulWidget {
  const MealFormSheet({super.key, required this.tripId, required this.dayIndex, this.entry});
  final String tripId;
  final int dayIndex;
  final MealEntry? entry;

  @override
  ConsumerState<MealFormSheet> createState() => _MealFormSheetState();
}

class _MealFormSheetState extends ConsumerState<MealFormSheet> {
  final _form = GlobalKey<FormState>();
  MealItem? get _item => widget.entry?.item;
  late final _name = TextEditingController(text: _item?.name);
  late final _weight = TextEditingController(text: _num(_item?.weight));
  late final _calories = TextEditingController(text: _num(_item?.calories));
  late final _quantity = TextEditingController(text: '${_item?.quantity ?? 1}');
  late final _note = TextEditingController(text: _item?.note);
  late MealType _type = MealType.fromKey(_item?.mealType ?? 'lunch');
  bool _busy = false;

  static String _num(double? v) => v == null || v == 0 ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _calories.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(mealRepositoryProvider);
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    final calories = double.tryParse(_calories.text.trim()) ?? 0;
    final quantity = int.tryParse(_quantity.text.trim()) ?? 1;
    if (_item == null) {
      await repo.add(widget.tripId, dayIndex: widget.dayIndex, name: _name.text.trim(), mealType: _type.key, weight: weight, calories: calories, quantity: quantity, note: _note.text.trim());
      await ref.read(libraryRepositoryProvider).remember(kind: 'meal', name: _name.text, category: _type.key, weight: weight, calories: calories);
    } else {
      await repo.update(_item!.id, name: _name.text.trim(), mealType: _type.key, weight: weight, calories: calories, quantity: quantity, note: _note.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(mealRepositoryProvider).delete(_item!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = _item != null;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,1}'))];
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(editing ? '編輯餐點' : '新增餐點（D${widget.dayIndex}）', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: !editing,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().isEmpty ? '請輸入餐點名稱' : null,
                decoration: const InputDecoration(labelText: '名稱', hintText: '例如：燕麥粥'),
              ),
              if (!editing)
                LibrarySuggestions(
                  kind: 'meal',
                  controller: _name,
                  onPick: (i) => setState(() {
                    _name.text = i.name;
                    _type = MealType.fromKey(i.category);
                    _weight.text = _num(i.weight);
                    _calories.text = _num(i.calories);
                  }),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: '餐別'),
                items: [for (final t in MealType.values) DropdownMenuItem(value: t, child: Text(t.label))],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimal,
                      decoration: const InputDecoration(labelText: '單份重量', suffixText: 'g'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _calories,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimal,
                      decoration: const InputDecoration(labelText: '單份熱量', suffixText: 'kcal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) < 1 ? '至少 1 份' : null,
                      decoration: const InputDecoration(labelText: '份數'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: TextFormField(controller: _note, decoration: const InputDecoration(labelText: '備註（選填）'))),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _busy ? null : _save, child: Text(editing ? '儲存' : '新增')),
              if (editing)
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('刪除餐點'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
