import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/page_accents.dart';
import '../../shared/brand/cover_image.dart';
import '../../app/router.dart';
import '../../core/ads/ads.dart';
import '../../core/db/app_database.dart';
import '../../shared/brand/illustrations.dart';
import 'domain/trip_art.dart';
import '../../shared/hint_banner.dart';
import 'domain/trip_logic.dart';
import 'providers.dart';
import '../gear/providers.dart';
import '../gear/domain/gear_logic.dart';
import 'ui/member_stack.dart';
import 'ui/copy_trip.dart';
import 'ui/gpx_actions.dart';
import 'ui/trip_form_sheet.dart';

/// "行程": the person's trips, grouped by when they happen.
class TripsTab extends ConsumerWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    return PageAccents(child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(canAdd: trips.value?.isNotEmpty ?? false),
            Expanded(
              child: trips.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('讀取行程失敗：$e')),
                data: (list) => list.isEmpty ? const _EmptyState() : _TripList(trips: list),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

/// Today's date over the page title, with the two ways to add a trip.
class _Header extends ConsumerWidget {
  const _Header({required this.canAdd});
  final bool canAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(clockProvider)();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${today.month} 月 ${today.day} 日　星期${_weekdays[today.weekday - 1]}',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: .5),
                ),
                Text('我的行程', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30)),
              ],
            ),
          ),
          IconButton(key: const ValueKey('import-gpx'), tooltip: '匯入 GPX', icon: const Icon(Icons.file_open_outlined), onPressed: () => importGpx(context, ref)),
          if (canAdd) ...[
            const SizedBox(width: 4),
            IconButton.filled(
              key: const ValueKey('add-trip'),
              tooltip: '建立行程',
              style: IconButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, minimumSize: const Size(48, 48)),
              onPressed: () => _create(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _create(BuildContext context) async {
  final id = await showTripFormSheet(context);
  if (id != null && context.mounted) context.push(Routes.trip(id));
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: IllustrationView(Illustration.trip)),
            const SizedBox(height: 16),
            Text('還沒有行程', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('建立一個行程，開始規劃每天的路線、裝備與糧食。', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            FilledButton(onPressed: () => _create(context), child: const Text('建立第一個行程')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final id = await ref.read(tripRepositoryProvider).createSample(today: ref.read(clockProvider)());
                if (context.mounted) context.push(Routes.trip(id));
              },
              child: const Text('用範例行程試試看'),
            ),
            TextButton(key: const ValueKey('empty-import-gpx'), onPressed: () => importGpx(context, ref), child: const Text('匯入 GPX 檔')),
          ],
        ),
      ),
    );
  }
}

/// The trip being walked, or else the next one, gets a large card; the others are small rows, and past trips
/// stay folded away until asked for.
class _TripList extends ConsumerStatefulWidget {
  const _TripList({required this.trips});
  final List<Trip> trips;

  @override
  ConsumerState<_TripList> createState() => _TripListState();
}

class _TripListState extends ConsumerState<_TripList> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final trips = widget.trips;
    final today = ref.watch(clockProvider)();
    final g = groupTrips(trips, today);
    final isGuest = ref.watch(accountIdProvider) == null;
    final hasRealTrip = trips.any((t) => !t.isSample);
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final tall = screen.height > screen.width; // a wide screen has no room for large pictures
    // with nothing ahead, the past is all there is to show
    final showPast = _showPast || (g.ongoing.isEmpty && g.upcoming.isEmpty);

    Widget caption(String title, {Widget? action}) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Spacer(),
          if (action != null) action else const SizedBox(height: 32),
        ],
      ),
    );
    // the ad goes after the second trip card on screen, or after the only one
    final visible = g.ongoing.length + g.upcoming.length + (showPast ? g.past.length : 0);
    final adAfter = visible < 2 ? visible : 2;
    var cards = 0;
    List<Widget> card(Trip t, {bool hero = false}) => [
      hero && tall ? _HeroCard(trip: t, today: today) : _TripRow(trip: t, today: today),
      if (++cards == adAfter) const AdBannerSlot(key: ValueKey('ad-slot')),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (isGuest && hasRealTrip)
          HintBanner(
            hintId: 'guest-backup',
            icon: Icons.cloud_upload_outlined,
            text: '登入後會自動備份行程，換手機也找得回來。',
            actionLabel: '登入',
            onAction: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.trips})),
          ),
        if (g.ongoing.isNotEmpty) ...[caption('進行中'), for (final t in g.ongoing) ...card(t, hero: true)],
        if (g.upcoming.isNotEmpty) ...[
          caption('即將出發'),
          for (final (i, t) in g.upcoming.indexed) ...card(t, hero: i == 0 && g.ongoing.isEmpty),
        ],
        if (g.past.isNotEmpty) ...[
          caption(
            '過去的行程',
            action: g.ongoing.isEmpty && g.upcoming.isEmpty
                ? null
                : TextButton(
                    key: const ValueKey('toggle-past'),
                    onPressed: () => setState(() => _showPast = !_showPast),
                    child: Text(_showPast ? '收合' : '查看 ${g.past.length} 趟'),
                  ),
          ),
          if (showPast)
            for (final t in g.past) ...card(t),
        ],
      ],
    );
  }
}

String _status(Trip trip, DateTime today) {
  final days = trip.start.difference(DateTime(today.year, today.month, today.day)).inDays;
  return switch (phaseOf(trip, today)) {
    TripPhase.ongoing => '進行中',
    TripPhase.upcoming => days == 1 ? '明天出發' : '還有 $days 天',
    TripPhase.past => '已結束',
  };
}

/// "範例" and, for someone else's trip, my role in it.
class _Tags extends ConsumerWidget {
  const _Tags({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(myRoleProvider(trip.id));
    final labels = [if (trip.isSample) '範例', if (role != null && role != TripRole.owner) role.label];
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 6, children: [for (final l in labels) _Tag(l)]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer)),
    );
  }
}

/// The large card: picture and countdown, who is coming, and how far the packing is.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.trip, required this.today});
  final Trip trip;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final gear = ref.watch(gearProvider(trip.id)).value ?? const <GearItem>[];
    final packed = packedCount(gear);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () => context.push(Routes.trip(trip.id)),
        onLongPress: () => copyTrip(context, ref, trip),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(height: 180, child: CoverImage(cover: coverFor(trip.id, coverCount))),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: scheme.surfaceContainerLowest.withValues(alpha: .92), borderRadius: BorderRadius.circular(16)),
                    child: Text(_status(trip, today), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(trip.rangeLabel, style: muted?.copyWith(fontSize: 13)),
                            _Tags(trip: trip),
                          ],
                        ),
                      ),
                      MemberStack(tripId: trip.id),
                    ],
                  ),
                  if (gear.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: scheme.outlineVariant),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Text('裝備打包', style: muted)),
                        Text('$packed / ${gear.length}', style: muted?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: packed / gear.length, minHeight: 6, borderRadius: BorderRadius.circular(3), backgroundColor: scheme.primaryContainer),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripRow extends ConsumerWidget {
  const _TripRow({required this.trip, required this.today});
  final Trip trip;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final past = phaseOf(trip, today) == TripPhase.past;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () => context.push(Routes.trip(trip.id)),
        onLongPress: () => copyTrip(context, ref, trip),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(dimension: 64, child: CoverImage(cover: coverFor(trip.id, coverCount))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                    Text(trip.rangeLabel, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    _Tags(trip: trip),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _status(trip, today),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: past ? scheme.onSurfaceVariant : scheme.tertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
