import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../trips/providers.dart';
import '../domain/collab_logic.dart';
import '../providers.dart';
import 'discussion_view.dart';
import '../../../shared/form_sheet.dart';

Future<void> showPollFormSheet(BuildContext context, {required String tripId}) {
  return showFormSheet<void>(
    context: context,
    builder: (_) => PollFormSheet(tripId: tripId),
  );
}

/// Creates a poll (owner and guides only; the page decides who sees the button).
class PollFormSheet extends ConsumerStatefulWidget {
  const PollFormSheet({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<PollFormSheet> createState() => _PollFormSheetState();
}

class _PollFormSheetState extends ConsumerState<PollFormSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  DateTime? _deadline;
  bool _multiple = false;
  bool _addOption = false;
  bool _blind = false;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = ref.read(clockProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _deadline ?? DateTime(now.year, now.month, now.day, 21),
      ),
    );
    if (time == null) return;
    setState(
      () => _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    final options = cleanOptions(_options.map((c) => c.text));
    final error = validatePollDraft(_title.text, options);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref
        .read(pollRepositoryProvider)
        .create(
          widget.tripId,
          title: _title.text,
          description: _description.text,
          options: options,
          deadline: _deadline,
          allowMultiple: _multiple,
          allowAddOption: _addOption,
          blind: _blind,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('建立投票', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: pollTitleMaxLength,
              buildCounter: _noCounter,
              decoration: const InputDecoration(
                labelText: '標題',
                hintText: '例如：第二天要不要攻頂？',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '說明（選填）'),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        maxLength: pollOptionMaxLength,
                        buildCounter: _noCounter,
                        decoration: InputDecoration(labelText: '選項 ${i + 1}'),
                      ),
                    ),
                    if (_options.length > pollOptionMinCount)
                      IconButton(
                        tooltip: '移除選項 ${i + 1}',
                        onPressed: () =>
                            setState(() => _options.removeAt(i).dispose()),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                ),
              ),
            if (_options.length < pollOptionMaxCount)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _options.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('再加一個選項'),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null
                        ? '截止時間：不設定'
                        : '截止時間：${formatStamp(_deadline!)}',
                  ),
                ),
                if (_deadline != null)
                  IconButton(
                    tooltip: '清除截止時間',
                    onPressed: () => setState(() => _deadline = null),
                    icon: const Icon(Icons.close),
                  ),
                TextButton(onPressed: _pickDeadline, child: const Text('選擇')),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('允許多選'),
              value: _multiple,
              onChanged: (v) => setState(() => _multiple = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('允許成員新增選項'),
              value: _addOption,
              onChanged: (v) => setState(() => _addOption = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('盲投'),
              subtitle: const Text('結束或截止後才公開結果'),
              value: _blind,
              onChanged: (v) => setState(() => _blind = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('建立'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget? _noCounter(
    BuildContext _, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
