import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/trip_snapshot.dart';

import '../widgets/itinerary/itinerary_list_view.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

class TripSnapshotDetailScreen extends StatefulWidget {
  final TripSnapshot snapshot;

  const TripSnapshotDetailScreen({super.key, required this.snapshot});

  @override
  State<TripSnapshotDetailScreen> createState() => _TripSnapshotDetailScreenState();
}

class _TripSnapshotDetailScreenState extends State<TripSnapshotDetailScreen> {
  late List<String> _dayNames;
  String _selectedDay = 'D1';

  @override
  void initState() {
    super.initState();
    _dayNames = widget.snapshot.itinerary.map((e) => e.day).toSet().toList();
    if (_dayNames.isEmpty) {
      _dayNames = ['D1'];
    }
    // 依 D1, D2 排序
    _dayNames.sort((a, b) {
      final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return aNum.compareTo(bNum);
    });
    _selectedDay = _dayNames.first;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.snapshot.itinerary.where((e) => e.day == _selectedDay).toList();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.snapshot.name} - 行程預覽')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('yyyy/MM/dd').format(widget.snapshot.startDate)}${widget.snapshot.endDate != null ? ' - ${DateFormat('yyyy/MM/dd').format(widget.snapshot.endDate!)}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('此為行程快照，僅供預覽。'),
                  ],
                ),
              ],
            ),
          ),
          if (_dayNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dayNames.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, index) {
                    final dayName = _dayNames[index];
                    final isSelected = dayName == _selectedDay;
                    return ChoiceChip(
                      label: Text(dayName),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedDay = dayName),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: ItineraryListView(
              items: items,
              selectedDay: _selectedDay,
              isEditMode: false,
              onConfirmDelete: (ctx, key) {},
              onShowEditDialog: (ctx, item, day) {},
              onShowCheckInDialog: (ctx, item) {
                ToastService.info('預覽模式無法打卡');
              },
            ),
          ),
        ],
      ),
    );
  }
}
