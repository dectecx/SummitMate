import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../map/providers.dart';
import '../../../core/db/app_database.dart';
import '../../../shared/hint_banner.dart';
import '../domain/trip_logic.dart';
import '../domain/trip_art.dart';
import '../../../shared/pills.dart';
import '../providers.dart';
import '../../gpx/domain/elevation_profile.dart';
import '../../gpx/ui/elevation_profile_chart.dart';
import '../domain/gpx_trip.dart';
import 'item_form_sheet.dart';
import '../../../shared/link_text.dart';
import '../../map/ui/trip_offline_hint.dart';
import '../../weather/ui/weather_card.dart';
import '../../../shared/brand/illustrations.dart';

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
        DayBar(
          itemCount: days.length,
          itemBuilder: (_, i) {
            final d = days[i];
            return DayPill(key: ValueKey('day-$d'), label: dayLabel(d), date: trip.dateOfDay(d), selected: d == day, onTap: () => onDayChanged(d));
          },
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 96 + MediaQuery.paddingOf(context).bottom),
            children: [
              TripOfflineHint(trip: trip),
              DayWeatherStrip(trip: trip, day: day),
              _TrackProfile(trip: trip),
              if (role.canEditShared)
                const HintBanner(hintId: 'edit-node', icon: Icons.touch_app_outlined, text: '點一下節點就能編輯；點右邊的圓圈代表已抵達。'),
              if (dayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const IllustrationView(Illustration.trip, width: 140),
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
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    // the nodes of a day share one white sheet: rounded where it begins and ends
    final radius = BorderRadius.vertical(top: Radius.circular(first ? 20 : 0), bottom: Radius.circular(last ? 20 : 0));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showItemFormSheet(context, trip: trip, item: item, readOnly: !role.canEditShared),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 58,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14, top: 21),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(formatMinutes(item.estMinutes) ?? '––:––', style: muted)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(width: 2, height: 12, color: first ? Colors.transparent : scheme.primaryContainer),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: arrived ? scheme.primary : scheme.primaryContainer, shape: BoxShape.circle),
                        child: Icon(nodeIconFor(item.name), size: 18, color: arrived ? scheme.onPrimary : scheme.primary),
                      ),
                      Expanded(child: Container(width: 2, color: last ? Colors.transparent : scheme.primaryContainer)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.name.isEmpty ? '（未命名）' : item.name, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface)),
                        if (facts.isNotEmpty) Text(facts.join('  ·  '), style: muted),
                        if (item.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: LinkText(item.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)),
                        if (arrived) Padding(padding: const EdgeInsets.only(top: 4), child: Text('已抵達 ${_clock(item.checkedInAt!)}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary))),
                      ],
                    ),
                  ),
                ),
                if (role.canEditShared)
                  IconButton(
                    tooltip: arrived ? '取消抵達' : '標記已抵達',
                    icon: Icon(arrived ? Icons.check_circle : Icons.circle_outlined, color: arrived ? scheme.primary : scheme.outline),
                    onPressed: () => ref.read(itineraryRepositoryProvider).update(
                      item.id,
                      checkedInAt: Value(arrived ? null : ref.read(clockProvider)().toUtc()),
                    ),
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _clock(DateTime utc) {
    final l = utc.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

/// Elevation profile and totals of the trip's stored GPX track (nothing when the trip has none).
class _TrackProfile extends ConsumerWidget {
  const _TrackProfile({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = decodeTrack(trip.track);
    if (track.length < 2) return const SizedBox.shrink();
    final stats = profileStats(track);
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('track-profile'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('海拔剖面', style: theme.textTheme.titleMedium),
            if (stats != null) ...[
              const SizedBox(height: 4),
              Text(
                '${stats.distanceKm.toStringAsFixed(1)} km  ·  爬升 ${stats.ascent.round()} m  ·  下降 ${stats.descent.round()} m  ·  最高 ${stats.maxEle.round()} m',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            ElevationProfileChart(profile: elevationProfile(track)),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const ValueKey('show-route'),
              onPressed: () {
                ref.read(mapRouteProvider.notifier).show(trip.id);
                context.go(Routes.map);
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('在地圖上看路線'),
            ),
          ],
        ),
      ),
    );
  }
}
