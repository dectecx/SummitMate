import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import '../data/events_api.dart';
import '../domain/event_logic.dart';
import '../providers.dart';
import 'event_widgets.dart';

/// Create a group event, or edit one when [eventId] is given.
class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({super.key, this.eventId});
  final String? eventId;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  EventDetail? _initial;
  EventsException? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ref.read(eventsApiProvider).get(widget.eventId!);
      if (!mounted) return;
      setState(() {
        _initial = d;
        _loading = false;
      });
    } on EventsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.eventId != null;
    if (editing && _initial == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('編輯揪團')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: RetryMessage(text: _error?.text ?? '無法開啟', onRetry: _loadInitial),
              ),
      );
    }
    return _EventForm(initial: _initial);
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.initial});
  final EventDetail? initial;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _location = TextEditingController(text: widget.initial?.location);
  late final _max = TextEditingController(text: '${widget.initial?.maxMembers ?? 10}');
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _private = TextEditingController(text: widget.initial?.privateMessage);
  late EventCategory _category = widget.initial?.category ?? EventCategory.hiking;
  late DateTime _start = widget.initial == null ? _today() : parseDate(widget.initial!.startDate);
  late DateTime? _end = widget.initial?.endDate == null ? null : parseDate(widget.initial!.endDate!);
  late bool _approval = widget.initial?.approvalRequired ?? true;
  late String? _linkedTripId = widget.initial?.linkedTripId;
  // Send the snapshot again: always for a newly picked trip, on request for the one already linked.
  bool _resend = false;
  bool _pickedNewTrip = false;
  bool _busy = false;
  String? _dateError;

  bool get _editing => widget.initial != null;

  DateTime _today() {
    final n = ref.read(clockProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _max.dispose();
    _description.dispose();
    _private.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = _today();
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: _start.isBefore(now) ? _start : now,
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: '出發日期',
    );
    if (d == null) return;
    setState(() {
      _start = d;
      if (_end != null && _end!.isBefore(d)) _end = null;
      _dateError = null;
    });
  }

  Future<void> _pickEnd() async {
    final now = _today();
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? _start,
      firstDate: _start,
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: '結束日期',
    );
    if (d != null) {
      setState(() {
        _end = d.isAfter(_start) ? d : null;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTrip() async {
    final trips = ref.read(tripsProvider).value ?? const <Trip>[];
    final picked = await showModalBottomSheet<Trip?>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TripPicker(trips: trips),
    );
    if (picked == null) return;
    setState(() {
      _linkedTripId = picked.id;
      _pickedNewTrip = true;
      _resend = false;
    });
  }

  Future<TripSnapshot?> _snapshot() async {
    final id = _linkedTripId;
    if (id == null) return null;
    final send = _pickedNewTrip || _resend;
    if (!send) return null;
    final trip = await ref.read(tripRepositoryProvider).watch(id).first;
    if (trip == null) return null;
    final items = await ref.read(itineraryRepositoryProvider).watch(id).first;
    return buildTripSnapshot(trip, items);
  }

  Future<void> _submit() async {
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      // The first one may be far above the button: bring it into view.
      await Scrollable.ensureVisible(invalid.first.context, alignment: .1);
      return;
    }
    final dateError = validateEventDates(_start, _end);
    if (dateError != null) return setState(() => _dateError = dateError);
    final max = int.parse(_max.text.trim());
    final initial = widget.initial;
    if (initial != null && max < initial.approvedCount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('人數上限不能少於目前已通過的 ${initial.approvedCount} 人')));
      return;
    }
    setState(() => _busy = true);
    try {
      final snapshot = await _snapshot();
      final input = EventInput(
        title: _title.text.trim(),
        category: _category,
        location: _location.text.trim(),
        startDate: formatDate(_start),
        endDate: _end == null ? null : formatDate(_end!),
        maxMembers: max,
        approvalRequired: _approval,
        description: _description.text.trim(),
        privateMessage: _private.text.trim(),
        // Sent when it is new or its snapshot is sent again; an unchanged link stays as it is.
        linkedTripId: (_pickedNewTrip || _resend) ? _linkedTripId : null,
        tripSnapshot: snapshot,
      );
      final api = ref.read(eventsApiProvider);
      if (_editing) {
        await api.update(widget.initial!.id, input: input);
        if (mounted) context.pop(true);
      } else {
        final created = await api.create(input);
        if (mounted) context.pushReplacement(Routes.event(created.id));
      }
    } on EventsException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.text)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trips = ref.watch(tripsProvider).value ?? const <Trip>[];
    final linkedTrip = _linkedTripId == null ? null : trips.where((t) => t.id == _linkedTripId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? '編輯揪團' : '建立揪團')),
      // Not a lazy list: every field has to stay mounted for the form to check it.
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 32 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionCaption('基本資料', padding: EdgeInsets.fromLTRB(4, 8, 4, 8)),
              TextFormField(
                key: const ValueKey('event-title'),
                controller: _title,
                maxLength: titleMax,
                textInputAction: TextInputAction.next,
                validator: validateTitle,
                decoration: const InputDecoration(labelText: '標題', hintText: '例如：嘉明湖三日（5 到 200 字）'),
              ),
              const SizedBox(height: 8),
              Text('分類', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in EventCategory.values)
                    ChoiceChip(
                      key: ValueKey('event-category-${c.name}'),
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('event-location'),
                controller: _location,
                maxLength: 200,
                decoration: const InputDecoration(labelText: '地點', hintText: '例如：台東海端'),
              ),
              const SectionCaption('日期'),
              InkWell(
                key: const ValueKey('event-start'),
                onTap: _pickStart,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '出發日期', suffixIcon: Icon(Icons.calendar_month_outlined)),
                  child: Text(formatDate(_start)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const ValueKey('event-end'),
                onTap: _pickEnd,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '結束日期（選填）',
                    errorText: _dateError,
                    suffixIcon: _end == null
                        ? const Icon(Icons.calendar_month_outlined)
                        : IconButton(
                            tooltip: '清除結束日期',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _end = null),
                          ),
                  ),
                  child: Text(_end == null ? '未設定（單日）' : formatDate(_end!)),
                ),
              ),
              const SectionCaption('人數與審核'),
              TextFormField(
                key: const ValueKey('event-max'),
                controller: _max,
                keyboardType: TextInputType.number,
                validator: validateMaxMembers,
                decoration: const InputDecoration(
                  labelText: '人數上限',
                  helperText: '$maxMembersMin 到 $maxMembersMax 人，不含主辦人',
                ),
              ),
              const SizedBox(height: 4),
              Card(
                child: SwitchListTile(
                  key: const ValueKey('event-approval'),
                  shape: const RoundedRectangleBorder(),
                  title: const Text('需要主辦人審核'),
                  subtitle: Text(_approval ? '申請後由你決定是否通過' : '申請後直接加入，額滿為止'),
                  value: _approval,
                  onChanged: (v) => setState(() => _approval = v),
                ),
              ),
              const SectionCaption('內容'),
              TextFormField(
                key: const ValueKey('event-description'),
                controller: _description,
                maxLength: 4000,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(labelText: '說明', alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('event-private-message'),
                controller: _private,
                maxLength: 2000,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '隊員私密留言（選填）',
                  helperText: '只有你和通過的隊員看得到，例如集合時間與聯絡方式',
                  helperMaxLines: 2,
                  alignLabelWithHint: true,
                ),
              ),
              const SectionCaption('行程'),
              InkWell(
                key: const ValueKey('event-link'),
                onTap: _pickTrip,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '連結現有行程（選填）',
                    helperText: '只能連結你是團長的行程；通過的人會自動加入行程成員，也會附上路線預覽',
                    helperMaxLines: 2,
                    suffixIcon: _linkedTripId == null || (_editing && !_pickedNewTrip)
                        ? const Icon(Icons.link)
                        : IconButton(
                            tooltip: '清除連結',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _linkedTripId = widget.initial?.linkedTripId;
                              _pickedNewTrip = false;
                              _resend = false;
                            }),
                          ),
                  ),
                  child: Text(_linkedTripId == null ? '未連結' : (linkedTrip?.name ?? '已連結的行程（不在這支手機上）')),
                ),
              ),
              if (_editing && _linkedTripId != null && !_pickedNewTrip && linkedTrip != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    child: SwitchListTile(
                      key: const ValueKey('event-resend'),
                      shape: const RoundedRectangleBorder(),
                      title: const Text('用目前的行程內容更新路線預覽'),
                      value: _resend,
                      onChanged: (v) => setState(() => _resend = v),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              FilledButton(
                key: const ValueKey('event-submit'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _busy ? null : _submit,
                child: Text(_editing ? '儲存' : '建立揪團'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lists the trips the person owns.
class _TripPicker extends ConsumerWidget {
  const _TripPicker({required this.trips});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = [
      for (final t in trips)
        if (canLinkTrip(t, ref.watch(myRoleProvider(t.id)))) t,
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('連結哪個行程？', style: Theme.of(context).textTheme.titleLarge),
          ),
          if (owned.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(24, 8, 24, 24), child: Text('沒有可以連結的行程。只能連結你是團長的行程。')),
          for (final t in owned)
            ListTile(
              key: ValueKey('link-trip-${t.id}'),
              leading: const IconTile(Icons.hiking),
              title: Text(t.name),
              subtitle: Text(t.rangeLabel),
              onTap: () => Navigator.pop(context, t),
            ),
        ],
      ),
    );
  }
}
