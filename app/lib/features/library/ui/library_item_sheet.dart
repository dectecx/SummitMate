import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../gear/domain/gear_logic.dart';
import '../../meals/domain/meal_logic.dart';
import '../providers.dart';
import '../../../shared/form_sheet.dart';

/// Add or edit one library item. [kind] is 'gear' or 'meal'.
Future<void> showLibraryItemSheet(BuildContext context, {required String kind, LibraryItem? item}) {
  return showFormSheet<void>(
    context: context,
    builder: (_) => LibraryItemSheet(kind: kind, item: item),
  );
}

class LibraryItemSheet extends ConsumerStatefulWidget {
  const LibraryItemSheet({super.key, required this.kind, this.item});
  final String kind;
  final LibraryItem? item;

  @override
  ConsumerState<LibraryItemSheet> createState() => _LibraryItemSheetState();
}

class _LibraryItemSheetState extends ConsumerState<LibraryItemSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _weight = TextEditingController(text: _num(widget.item?.weight));
  late final _calories = TextEditingController(text: _num(widget.item?.calories));
  late final _note = TextEditingController(text: widget.item?.note);
  late String _category = widget.item?.category ?? (_isGear ? GearCategory.other.key : MealType.other.key);

  bool get _isGear => widget.kind == 'gear';

  static String _num(double? v) =>
      v == null || v == 0 ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _calories.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(libraryRepositoryProvider);
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    final calories = double.tryParse(_calories.text.trim()) ?? 0;
    if (widget.item == null) {
      await repo.add(
        kind: widget.kind,
        name: _name.text.trim(),
        category: _category,
        weight: weight,
        calories: calories,
        note: _note.text.trim(),
      );
    } else {
      await repo.update(
        widget.item!.id,
        name: _name.text.trim(),
        category: _category,
        weight: weight,
        calories: calories,
        note: _note.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(libraryRepositoryProvider).delete(widget.item!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}\.?\d{0,1}'))];
    final options = _isGear
        ? [for (final c in GearCategory.values) (c.key, c.label)]
        : [for (final t in MealType.values) (t.key, t.label)];
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? (_isGear ? '編輯裝備' : '編輯餐食') : (_isGear ? '新增到裝備庫' : '新增到常用餐食'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: !editing,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().isEmpty ? '請輸入名稱' : null,
                decoration: InputDecoration(labelText: '名稱', hintText: _isGear ? '例如：睡袋' : '例如：燕麥粥'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: options.any((o) => o.$1 == _category) ? _category : options.last.$1,
                decoration: InputDecoration(labelText: _isGear ? '分類' : '餐別'),
                items: [for (final o in options) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimal,
                      decoration: const InputDecoration(labelText: '單件重量', suffixText: 'g'),
                    ),
                  ),
                  if (!_isGear) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _calories,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: decimal,
                        decoration: const InputDecoration(labelText: '熱量', suffixText: 'kcal'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '備註（選填）'),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: Text(editing ? '儲存' : '新增')),
              if (editing)
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('從庫中刪除'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
