import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../explore/domain/mountain_models.dart';
import '../../explore/providers.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';
import '../../../shared/form_sheet.dart';

/// A page to create a trip, or to edit one when [trip] is given. Returns the trip id.
Future<String?> showTripFormSheet(BuildContext context, {Trip? trip}) {
  return showFormPage<String>(
    context: context,
    builder: (_) => TripFormSheet(trip: trip),
  );
}

class TripFormSheet extends ConsumerStatefulWidget {
  const TripFormSheet({super.key, this.trip});
  final Trip? trip;

  @override
  ConsumerState<TripFormSheet> createState() => _TripFormSheetState();
}

class _TripFormSheetState extends ConsumerState<TripFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.trip?.name);
  late final _description = TextEditingController(text: widget.trip?.description);
  late DateTime _start = widget.trip?.start ?? _today();
  late DateTime? _end = widget.trip?.endDate == null ? null : widget.trip!.end;
  late String? _mountainId = widget.trip?.mountainId;
  bool _busy = false;
  String? _dateError;

  DateTime _today() {
    final n = ref.read(clockProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = _today();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end ?? _start),
      helpText: '選擇出發與回程日期',
      saveText: '確定',
    );
    if (range == null) return;
    setState(() {
      _start = range.start;
      _end = range.end.isAfter(range.start) ? range.end : null;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(tripRepositoryProvider);
    final name = _name.text.trim();
    final description = _description.text.trim();
    final String id;
    if (widget.trip == null) {
      id = await repo.create(name: name, start: _start, end: _end, description: description, mountainId: _mountainId);
    } else {
      id = widget.trip!.id;
      await repo.update(id, name: name, description: description, start: _start, end: Value(_end), mountainId: Value(_mountainId));
    }
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.trip != null;
    final dayCount = (_end ?? _start).difference(_start).inDays + 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(editing ? '編輯行程' : '建立行程', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: !editing,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                validator: (v) => (v ?? '').trim().isEmpty ? '請輸入行程名稱' : null,
                decoration: const InputDecoration(labelText: '行程名稱', hintText: '例如：嘉明湖三日'),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDates,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: '日期', errorText: _dateError, suffixIcon: const Icon(Icons.calendar_month_outlined)),
                  child: Text(_end == null ? '${formatDate(_start)}（1 天）' : '${formatDate(_start)} ～ ${formatDate(_end!)}（$dayCount 天）'),
                ),
              ),
              const SizedBox(height: 16),
              _MountainField(
                value: _mountainId,
                onChanged: (id) => setState(() => _mountainId = id),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '備註（選填）'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(editing ? '儲存' : '建立'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional main mountain of the trip: a tap opens a searchable list of the named peaks.
class _MountainField extends ConsumerWidget {
  const _MountainField({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mountains = switch (ref.watch(mountainsProvider).value) {
      MountainsReady(:final data) => data,
      _ => null,
    };
    final selected = value == null ? null : mountains?.byId(value!);
    return InkWell(
      key: const ValueKey('trip-mountain'),
      onTap: mountains == null
          ? null
          : () async {
              final r = await showModalBottomSheet<_Pick>(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                showDragHandle: true,
                builder: (_) => _MountainPicker(mountains: mountains.mountains),
              );
              if (r != null) onChanged(r.id);
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '主要山頭（選填）',
          helperText: '設定後會用這座山顯示天氣',
          suffixIcon: selected != null
              ? IconButton(tooltip: '清除山頭', icon: const Icon(Icons.close), onPressed: () => onChanged(null))
              : const Icon(Icons.landscape_outlined),
        ),
        child: Text(selected == null ? (mountains == null ? '山岳資料載入中' : '未設定') : '${selected.name}  ·  ${selected.elevation} m'),
      ),
    );
  }
}

class _Pick {
  const _Pick(this.id);
  final String? id;
}

class _MountainPicker extends StatefulWidget {
  const _MountainPicker({required this.mountains});
  final List<Mountain> mountains;

  @override
  State<_MountainPicker> createState() => _MountainPickerState();
}

class _MountainPickerState extends State<_MountainPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final results = _q.trim().isEmpty ? widget.mountains : searchMountains(widget.mountains, query: _q.trim()).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '搜尋山名'),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final m in results)
                    ListTile(
                      key: ValueKey('trip-mountain-${m.id}'),
                      leading: const Icon(Icons.landscape_outlined),
                      title: Text(m.name),
                      subtitle: Text('${m.region}  ·  ${m.elevation} m'),
                      onTap: () => Navigator.pop(context, _Pick(m.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
