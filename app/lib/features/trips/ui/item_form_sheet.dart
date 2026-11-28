import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../explore/domain/mountain_models.dart';
import '../../explore/providers.dart';
import '../domain/route_points.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';
import '../../../shared/form_sheet.dart';

/// A page to add a node, or to edit/view one when [item] is given.
Future<void> showItemFormSheet(BuildContext context, {required Trip trip, ItineraryItem? item, int initialDay = 1, bool readOnly = false}) {
  return showFormPage<void>(
    context: context,
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
  final _nameFocus = FocusNode();
  // Name of the place chosen from the suggestions (null when the coordinates were typed or came from an older save).
  String? _placeName;
  late final _altitude = TextEditingController(text: (widget.item?.altitude ?? 0) == 0 ? '' : '${widget.item!.altitude}');
  late final _distance = TextEditingController(text: (widget.item?.distance ?? 0) == 0 ? '' : formatKm(widget.item!.distance));
  late final _lat = TextEditingController(text: widget.item?.lat?.toString());
  late final _lng = TextEditingController(text: widget.item?.lng?.toString());
  late final _note = TextEditingController(text: widget.item?.note);
  late int _day = widget.item?.dayIndex ?? widget.initialDay;
  late int? _minutes = widget.item?.estMinutes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {})); // keeps the route-point chips in step with what is typed
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    _altitude.dispose();
    _distance.dispose();
    _lat.dispose();
    _lng.dispose();
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
    // Both or neither: a half coordinate is useless.
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    final hasCoords = lat != null && lng != null;
    if (widget.item == null) {
      await repo.add(widget.trip.id, dayIndex: _day, name: _name.text.trim(), estMinutes: _minutes, altitude: altitude, distance: distance, lat: hasCoords ? lat : null, lng: hasCoords ? lng : null, note: _note.text.trim());
    } else {
      await repo.update(widget.item!.id, dayIndex: _day, name: _name.text.trim(), estMinutes: Value(_minutes), altitude: altitude, distance: distance, lat: Value(hasCoords ? lat : null), lng: Value(hasCoords ? lng : null), note: _note.text.trim());
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

  bool get _hasPlace => double.tryParse(_lat.text.trim()) != null && double.tryParse(_lng.text.trim()) != null;

  void _pickPlace(Mountain m) {
    setState(() {
      _placeName = m.name;
      _lat.text = m.latitude.toStringAsFixed(5);
      _lng.text = m.longitude.toStringAsFixed(5);
      if (_altitude.text.trim().isEmpty) _altitude.text = '${m.elevation}';
    });
  }

  void _pickRoutePoint(RoutePoint p) {
    setState(() {
      _name.text = p.name;
      _placeName = null;
      if (_altitude.text.trim().isEmpty && p.altitude > 0) _altitude.text = '${p.altitude}';
      if (!_hasPlace && p.lat != null && p.lng != null) {
        _lat.text = p.lat!.toStringAsFixed(5);
        _lng.text = p.lng!.toStringAsFixed(5);
      }
    });
  }

  void _clearPlace() => setState(() {
    _placeName = null;
    _lat.clear();
    _lng.clear();
  });

  Widget _coordField(TextEditingController c, String label, double min, double max, bool ro) => TextFormField(
    controller: c,
    readOnly: ro,
    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}\.?\d{0,6}'))],
    validator: (v) {
      final t = (v ?? '').trim();
      if (t.isEmpty) return null;
      final n = double.tryParse(t);
      return n == null || n < min || n > max ? '$label 需介於 ${min.toInt()} 到 ${max.toInt()}' : null;
    },
    decoration: InputDecoration(labelText: label, hintText: label == '緯度' ? '23.4' : '121.0'),
  );

  /// Names used before on trips to the same mountain, so 1K處 or 涼亭 is one tap and never mixes up routes.
  Widget _routePointChips() {
    final points = ref.watch(routePointsProvider(widget.trip.mountainId!)).value ?? const <RoutePoint>[];
    final name = _name.text.trim();
    final shown = points.where((p) => p.name != name).take(8).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        children: [
          for (final p in shown)
            ActionChip(key: ValueKey('route-point-${p.name}'), label: Text(p.name), onPressed: () => _pickRoutePoint(p)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final ro = widget.readOnly;
    final items = ref.watch(itineraryProvider(widget.trip.id)).value ?? const <ItineraryItem>[];
    final mountains = switch (ref.watch(mountainsProvider).value) {
      MountainsReady(:final data) => data.mountains,
      _ => const <Mountain>[],
    };
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
              RawAutocomplete<Mountain>(
                textEditingController: _name,
                focusNode: _nameFocus,
                displayStringForOption: (m) => m.name,
                optionsBuilder: (value) {
                  final q = value.text.trim();
                  if (ro || q.isEmpty || q == _placeName) return const Iterable<Mountain>.empty();
                  return searchMountains(mountains, query: q).take(6);
                },
                onSelected: _pickPlace,
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: !editing && !ro,
                  readOnly: ro,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v ?? '').trim().isEmpty ? '請輸入名稱' : null,
                  decoration: const InputDecoration(labelText: '名稱', hintText: '例如：1K處、涼亭、黑水塘'),
                ),
                optionsViewBuilder: (context, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final m in options)
                            ListTile(
                              key: ValueKey('place-${m.id}'),
                              dense: true,
                              leading: const Icon(Icons.landscape_outlined),
                              title: Text(m.name),
                              subtitle: Text('${m.region}  ·  ${m.elevation} m'),
                              onTap: () => onSelected(m),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!ro && widget.trip.mountainId != null) _routePointChips(),
              if (_hasPlace)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      key: const ValueKey('place-chip'),
                      avatar: const Icon(Icons.place_outlined, size: 18),
                      label: Text(_placeName == null ? '已設定座標 ${_lat.text}, ${_lng.text}' : '地點：$_placeName'),
                      onDeleted: ro ? null : _clearPlace,
                      deleteButtonTooltipMessage: '移除地點',
                    ),
                  ),
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
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: _lat.text.isNotEmpty,
                title: const Text('手動輸入座標（進階）'),
                children: [
                  Row(
                    children: [
                      Expanded(child: _coordField(_lat, '緯度', -90, 90, ro)),
                      const SizedBox(width: 12),
                      Expanded(child: _coordField(_lng, '經度', -180, 180, ro)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
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
