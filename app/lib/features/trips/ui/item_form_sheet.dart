import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';

/// Bottom sheet to add a node, or to edit/view one when [item] is given.
Future<void> showItemFormSheet(BuildContext context, {required Trip trip, ItineraryItem? item, int initialDay = 1, bool readOnly = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ItemFormSheet(trip: trip, item: item, initialDay: initialDay, readOnly: readOnly),
  );
}

class ItemFormSheet extends ConsumerStatefulWidget {
  const ItemFormSheet({super.key, required this.trip, this.item, this.initialDay = 1, this.readOnly = false});
  final Trip trip;
  final ItineraryItem? item;
  final int initialDay;
  final bool readOnly;

  @override
  ConsumerState<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends ConsumerState<ItemFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _altitude = TextEditingController(text: (widget.item?.altitude ?? 0) == 0 ? '' : '${widget.item!.altitude}');
  late final _distance = TextEditingController(text: (widget.item?.distance ?? 0) == 0 ? '' : formatKm(widget.item!.distance));
  late final _note = TextEditingController(text: widget.item?.note);
  late int _day = widget.item?.dayIndex ?? widget.initialDay;
  late int? _minutes = widget.item?.estMinutes;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _altitude.dispose();
    _distance.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final m = _minutes ?? 8 * 60;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60), helpText: '預計抵達時間');
    if (t != null) setState(() => _minutes = t.hour * 60 + t.minute);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(itineraryRepositoryProvider);
    final altitude = int.tryParse(_altitude.text.trim()) ?? 0;
    final distance = double.tryParse(_distance.text.trim()) ?? 0;
    if (widget.item == null) {
      await repo.add(widget.trip.id, dayIndex: _day, name: _name.text.trim(), estMinutes: _minutes, altitude: altitude, distance: distance, note: _note.text.trim());
    } else {
      await repo.update(widget.item!.id, dayIndex: _day, name: _name.text.trim(), estMinutes: Value(_minutes), altitude: altitude, distance: distance, note: _note.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除這個節點？'),
        content: Text('「${widget.item!.name}」會被移除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44), backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(itineraryRepositoryProvider).delete(widget.item!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final ro = widget.readOnly;
    final items = ref.watch(itineraryProvider(widget.trip.id)).value ?? const <ItineraryItem>[];
    final days = dayIndexesFor(widget.trip, items);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(ro ? '節點' : (editing ? '編輯節點' : '新增節點'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: !editing && !ro,
                readOnly: ro,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().isEmpty ? '請輸入名稱' : null,
                decoration: const InputDecoration(labelText: '名稱', hintText: '例如：向陽山屋'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _day,
                      decoration: const InputDecoration(labelText: '第幾天'),
                      items: [for (final d in days) DropdownMenuItem(value: d, child: Text('${dayLabel(d)}  ${widget.trip.dateOfDay(d).month}/${widget.trip.dateOfDay(d).day}'))],
                      onChanged: ro ? null : (v) => setState(() => _day = v ?? _day),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: ro ? null : _pickTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '預計時間',
                          suffixIcon: _minutes != null && !ro ? IconButton(tooltip: '清除時間', icon: const Icon(Icons.close), onPressed: () => setState(() => _minutes = null)) : const Icon(Icons.schedule),
                        ),
                        child: Text(formatMinutes(_minutes) ?? '未設定'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _altitude,
                      readOnly: ro,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                      decoration: const InputDecoration(labelText: '海拔', suffixText: 'm'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _distance,
                      readOnly: ro,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,2}'))],
                      decoration: const InputDecoration(labelText: '與上一點距離', suffixText: 'km'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _note, readOnly: ro, minLines: 1, maxLines: 4, decoration: const InputDecoration(labelText: '備註（選填）')),
              if (!ro) ...[
                const SizedBox(height: 24),
                FilledButton(onPressed: _busy ? null : _save, child: Text(editing ? '儲存' : '新增')),
                if (editing)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('刪除節點'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
