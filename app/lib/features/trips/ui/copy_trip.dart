import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';

/// Asks for a name and a start date, copies the trip and opens the copy.
Future<void> copyTrip(BuildContext context, WidgetRef ref, Trip trip) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final n = ref.read(clockProvider)();
  final today = DateTime(n.year, n.month, n.day);
  final choice = await showDialog<({String name, DateTime start})>(
    context: context,
    builder: (_) => _CopyDialog(initialName: '${trip.name}（複製）', initialStart: trip.start.isBefore(today) ? today : trip.start, today: today),
  );
  if (choice == null) return;
  final id = await ref.read(tripCopierProvider).copy(trip, name: choice.name, start: choice.start);
  messenger.showSnackBar(SnackBar(content: Text('已複製為「${choice.name}」')));
  router.push(Routes.trip(id));
}

class _CopyDialog extends StatefulWidget {
  const _CopyDialog({required this.initialName, required this.initialStart, required this.today});
  final String initialName;
  final DateTime initialStart;
  final DateTime today;

  @override
  State<_CopyDialog> createState() => _CopyDialogState();
}

class _CopyDialogState extends State<_CopyDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late DateTime _start = widget.initialStart;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(widget.today.year - 1),
      lastDate: DateTime(widget.today.year + 3, 12, 31),
      helpText: '新行程的出發日期',
    );
    if (d != null) setState(() => _start = d);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('複製行程'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(key: const ValueKey('copy-name'), controller: _name, maxLength: 200, decoration: const InputDecoration(labelText: '新行程名稱')),
          const SizedBox(height: 8),
          InkWell(
            key: const ValueKey('copy-date'),
            onTap: _pick,
            child: InputDecorator(decoration: const InputDecoration(labelText: '出發日期', suffixIcon: Icon(Icons.calendar_month_outlined)), child: Text(formatDate(_start))),
          ),
          const SizedBox(height: 12),
          Text('會複製節點、主要山頭、軌跡，以及你自己的裝備與餐點；不複製成員。', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          key: const ValueKey('copy-confirm'),
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, (name: name, start: _start));
          },
          child: const Text('複製'),
        ),
      ],
    );
  }
}
