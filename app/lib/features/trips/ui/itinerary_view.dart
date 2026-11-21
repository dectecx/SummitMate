import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/hint_banner.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';
import 'item_form_sheet.dart';

/// Day chips and the timeline of the selected day.
class ItineraryView extends ConsumerWidget {
  const ItineraryView({super.key, required this.trip, required this.role, required this.day, required this.onDayChanged});
  final Trip trip;
  final TripRole role;
  final int day;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itineraryProvider(trip.id)).value ?? const <ItineraryItem>[];
    final days = dayIndexesFor(trip, items);
    final dayItems = itemsOfDay(items, day);
    final cumulative = cumulativeDistance(dayItems);

    return Column(
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              final date = trip.dateOfDay(d);
              return ChoiceChip(
                key: ValueKey('day-$d'),
                label: Text('${dayLabel(d)}  ${date.month}/${date.day}'),
                selected: d == day,
                onSelected: (_) => onDayChanged(d),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (role.canEditShared)
                const HintBanner(hintId: 'edit-node', icon: Icons.touch_app_outlined, text: '點一下節點就能編輯；點右邊的圓圈代表已抵達。'),
              if (dayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.route_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(role.canEditShared ? '這一天還沒有節點，按右下角新增登山口、山屋或山頭。' : '這一天還沒有節點。', textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                for (var i = 0; i < dayItems.length; i++)
                  _ItemTile(
                    item: dayItems[i],
                    cumulativeKm: cumulative[i],
                    first: i == 0,
                    last: i == dayItems.length - 1,
                    role: role,
                    trip: trip,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.cumulativeKm, required this.first, required this.last, required this.role, required this.trip});
  final ItineraryItem item;
  final double cumulativeKm;
  final bool first;
  final bool last;
  final TripRole role;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final arrived = item.checkedInAt != null;
    final facts = <String>[
      if (item.altitude > 0) '${item.altitude} m',
      if (cumulativeKm > 0) '累計 ${formatKm(cumulativeKm)} km',
    ];
    return InkWell(
      onTap: () => showItemFormSheet(context, trip: trip, item: item, readOnly: !role.canEditShared),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 12),
                child: Text(formatMinutes(item.estMinutes) ?? '––:––', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
              ),
            ),
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(width: 2, height: 20, color: first ? Colors.transparent : scheme.outlineVariant),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: arrived ? scheme.primary : scheme.surface, border: Border.all(color: scheme.primary, width: 2), shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(width: 2, color: last ? Colors.transparent : scheme.outlineVariant)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name.isEmpty ? '（未命名）' : item.name, style: theme.textTheme.titleMedium),
                    if (facts.isNotEmpty) Text(facts.join('  ·  '), style: theme.textTheme.bodySmall),
                    if (item.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)),
                    if (arrived) Padding(padding: const EdgeInsets.only(top: 4), child: Text('已抵達 ${_clock(item.checkedInAt!)}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary))),
                  ],
                ),
              ),
            ),
            if (role.canEditShared)
              IconButton(
                tooltip: arrived ? '取消抵達' : '標記已抵達',
                icon: Icon(arrived ? Icons.check_circle : Icons.radio_button_unchecked, color: scheme.primary),
                onPressed: () => ref.read(itineraryRepositoryProvider).update(
                  item.id,
                  checkedInAt: Value(arrived ? null : ref.read(clockProvider)().toUtc()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _clock(DateTime utc) {
    final l = utc.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
