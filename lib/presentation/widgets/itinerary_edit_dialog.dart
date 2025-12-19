import 'package:flutter/material.dart';
import '../../data/models/itinerary_item.dart';

class ItineraryEditDialog extends StatefulWidget {
  final ItineraryItem? item; // Null for Add, non-null for Edit
  final String defaultDay;

  const ItineraryEditDialog({super.key, this.item, required this.defaultDay});

  @override
  State<ItineraryEditDialog> createState() => _ItineraryEditDialogState();
}

class _ItineraryEditDialogState extends State<ItineraryEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _altitudeCtrl;
  late TextEditingController _distanceCtrl;
  late TextEditingController _noteCtrl;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _altitudeCtrl = TextEditingController(text: item?.altitude.toString() ?? '3000');
    _distanceCtrl = TextEditingController(text: item?.distance.toString() ?? '1.0');
    _noteCtrl = TextEditingController(text: item?.note ?? '');

    if (item != null) {
      // Parse "08:00" format
      try {
        final parts = item.estTime.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _altitudeCtrl.dispose();
    _distanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return AlertDialog(
      title: Text(isEdit ? '編輯行程' : '新增行程'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '名稱', hintText: '例如：向陽山屋'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '預計時間'),
                child: Text(_selectedTime.format(context), style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _altitudeCtrl,
                    decoration: const InputDecoration(labelText: '海拔 (m)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _distanceCtrl,
                    decoration: const InputDecoration(labelText: '距離 (km)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: '備註'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: Text(isEdit ? '儲存' : '新增')),
      ],
    );
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null) {
      setState(() => _selectedTime = t);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final alt = int.tryParse(_altitudeCtrl.text) ?? 0;
    final dist = double.tryParse(_distanceCtrl.text) ?? 0.0;
    final note = _noteCtrl.text.trim();
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    // Return partial map or object to parent to handle submission
    Navigator.pop(context, {'name': name, 'estTime': timeStr, 'altitude': alt, 'distance': dist, 'note': note});
  }
}
