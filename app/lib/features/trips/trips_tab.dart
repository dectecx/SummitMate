import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/ads/ads.dart';
import '../../core/db/app_database.dart';
import '../../shared/brand/illustrations.dart';
import '../../shared/hint_banner.dart';
import 'domain/trip_logic.dart';
import 'providers.dart';
import 'ui/copy_trip.dart';
import 'ui/gpx_actions.dart';
import 'ui/trip_form_sheet.dart';

/// "行程": the person's trips, grouped by when they happen.
class TripsTab extends ConsumerWidget {
  const TripsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('行程'),
        actions: [IconButton(key: const ValueKey('import-gpx'), tooltip: '匯入 GPX', icon: const Icon(Icons.file_open_outlined), onPressed: () => importGpx(context, ref))],
      ),
      body: trips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('讀取行程失敗：$e')),
        data: (list) => list.isEmpty ? const _EmptyState() : _TripList(trips: list),
      ),
      bottomNavigationBar: const AdBannerSlot(),
      floatingActionButton: (trips.value?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => _create(context),
              icon: const Icon(Icons.add),
              label: const Text('建立行程'),
            )
          : null,
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
      child: Padding(
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

class _TripList extends ConsumerWidget {
  const _TripList({required this.trips});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider)();
    final g = groupTrips(trips, today);
    final isGuest = ref.watch(accountIdProvider) == null;
    final hasRealTrip = trips.any((t) => !t.isSample);

    Widget section(String title, List<Trip> list) => list.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
                child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1)),
              ),
              for (final t in list) _TripCard(trip: t, today: today),
            ],
          );

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (isGuest && hasRealTrip)
          HintBanner(
            hintId: 'guest-backup',
            icon: Icons.cloud_upload_outlined,
            text: '登入後會自動備份行程，換手機也找得回來。',
            actionLabel: '登入',
            onAction: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.trips})),
          ),
        section('進行中', g.ongoing),
        section('即將出發', g.upcoming),
        section('過去的行程', g.past),
      ],
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.trip, required this.today});
  final Trip trip;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(myRoleProvider(trip.id));
    final phase = phaseOf(trip, today);
    final days = trip.start.difference(DateTime(today.year, today.month, today.day)).inDays;
    final status = switch (phase) {
      TripPhase.ongoing => '進行中',
      TripPhase.upcoming => days == 1 ? '明天出發' : '還有 $days 天',
      TripPhase.past => '已結束',
    };
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.trip(trip.id)),
        onLongPress: () => copyTrip(context, ref, trip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _DateTile(date: trip.start, highlight: phase == TripPhase.ongoing, faded: phase == TripPhase.past),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(trip.rangeLabel, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _Tag(status, highlight: phase == TripPhase.ongoing),
                        if (trip.isSample) const _Tag('範例'),
                        if (role != null && role != TripRole.owner) _Tag(role.label),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.highlight = false});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: highlight ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: highlight ? scheme.onPrimary : scheme.onSurfaceVariant)),
    );
  }
}

/// The start date as a small tile: month over day.
class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.highlight, required this.faded});
  final DateTime date;
  final bool highlight;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight ? scheme.primary : (faded ? scheme.surfaceContainer : scheme.primaryContainer);
    final fg = highlight ? scheme.onPrimary : (faded ? scheme.onSurfaceVariant : scheme.onPrimaryContainer);
    return Container(
      width: 52,
      height: 56,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${date.month}月', style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
          Text('${date.day}', style: TextStyle(fontSize: 22, height: 1.1, color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
