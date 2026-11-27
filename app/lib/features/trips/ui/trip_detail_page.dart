import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/brand/cover_image.dart';
import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../../../shared/brand/illustrations.dart';
import '../../../shared/animations.dart';
import '../../gpx/domain/elevation_profile.dart';
import '../domain/gpx_trip.dart';
import '../domain/trip_art.dart';
import 'trip_header.dart';
import '../../../shared/coming_soon.dart';
import '../../collab/ui/discussion_view.dart';
import '../../gear/ui/gear_form_sheet.dart';
import '../../gear/ui/gear_view.dart';
import '../../meals/ui/meal_form_sheet.dart';
import '../../meals/ui/meals_view.dart';
import '../../members/ui/members_view.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';
import '../../library/ui/template_actions.dart';
import 'copy_trip.dart';
import 'gpx_actions.dart';
import 'itinerary_view.dart';
import 'item_form_sheet.dart';
import 'trip_form_sheet.dart';

/// One trip: its itinerary today; gear, meals and members arrive in later steps.
class TripDetailPage extends ConsumerStatefulWidget {
  const TripDetailPage({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this)
    ..addListener(_onTab);
  final _scroll = GlobalKey<NestedScrollViewState>();
  int _shownTab = 0;
  int? _day;
  bool _hadTrip = false; // the trip was shown here at least once
  int _mealDay = 1;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onTab() {
    setState(() {});
    if (_tabs.index == _shownTab) return;
    _shownTab = _tabs.index;
    if (_shownTab != 0) _collapseHeader(); // the cover belongs to the itinerary; lists need the room
  }

  void _collapseHeader() {
    final outer = _scroll.currentState?.outerController;
    if (outer == null || !outer.hasClients) return;
    final end = outer.position.maxScrollExtent;
    if (outer.offset >= end) return;
    if (animationsOn(context, ref)) {
      outer.animateTo(end, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    } else {
      outer.jumpTo(end);
    }
  }

  static String _monthDay(DateTime d) => '${d.month}/${d.day}';

  /// Only numbers that exist: the stored track when there is one, otherwise the distances typed on the nodes.
  List<TripStat> _stats(Trip trip) {
    final track = decodeTrack(trip.track);
    final profile = track.length < 2 ? null : profileStats(track);
    final typed = (ref.watch(itineraryProvider(trip.id)).value ?? const <ItineraryItem>[]).fold(0.0, (sum, i) => sum + i.distance);
    return [
      (value: '${trip.dayCount} 天', label: '天數'),
      if (profile != null) ...[
        (value: '${profile.distanceKm.toStringAsFixed(1)} km', label: '距離'),
        (value: '${profile.ascent.round()} m', label: '爬升'),
      ] else if (typed > 0)
        (value: '${formatKm(typed)} km', label: '距離'),
    ];
  }

  int _initialDay(Trip trip) {
    final n = ref.read(clockProvider)();
    final today = DateTime(n.year, n.month, n.day);
    if (phaseOf(trip, today) == TripPhase.ongoing) {
      return today.difference(trip.start).inDays + 1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final trip = tripAsync.value;
    if (trip != null) _hadTrip = true;
    if (trip == null) {
      // A trip that was on screen and is gone (signed out or switched account, removed by the owner) leaves a dead
      // page in this tab. Go back to the list the next time the tab is visible; going while it is hidden would
      // yank the person over to this tab.
      if (_hadTrip && !tripAsync.isLoading && TickerMode.valuesOf(context).enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false) && ref.read(tripProvider(widget.tripId)).value == null) {
            context.go(Routes.trips);
          }
        });
      }
      return Scaffold(
        appBar: AppBar(),
        body: tripAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const ComingSoon(
                illustration: Illustration.search,
                message: '找不到這個行程，可能已被刪除',
              ),
      );
    }
    final role = ref.watch(myRoleProvider(trip.id)) ?? TripRole.member;
    final day = _day ?? _initialDay(trip);

    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final menu = PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (v) {
              if (v == 'edit') showTripFormSheet(context, trip: trip);
              if (v == 'copy') copyTrip(context, ref, trip);
              if (v == 'save-template') saveTripAsTemplate(context, ref, trip);
              if (v == 'apply-template') {
                applyTemplateToTrip(context, ref, trip);
              }
              if (v == 'gpx') {
                exportGpx(context, trip, ref.read(itineraryProvider(trip.id)).value ?? const []);
              }
              if (v == 'delete') _delete(context, trip);
            },
            itemBuilder: (_) => [
              if (role.canEditShared)
                const PopupMenuItem(value: 'edit', child: Text('編輯行程')),
              const PopupMenuItem(value: 'copy', child: Text('複製行程')),
              const PopupMenuItem(value: 'save-template', child: Text('存成範本')),
              const PopupMenuItem(value: 'apply-template', child: Text('套用範本')),
              const PopupMenuItem(value: 'gpx', child: Text('匯出 GPX')),
              if (role.canDeleteTrip)
                const PopupMenuItem(value: 'delete', child: Text('刪除行程')),
            ],
          );
    final tabBar = TabBar(
      controller: _tabs,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 15),
      tabs: const [
        Tab(text: '行程'),
        Tab(text: '裝備'),
        Tab(text: '餐食'),
        Tab(text: '討論'),
        Tab(text: '成員'),
      ],
    );
    final header = TripHeaderDelegate(
      tripId: trip.id,
      cover: coverFor(trip.id, coverCount),
      title: trip.name,
      dates: trip.dayCount == 1 ? _monthDay(trip.start) : '${_monthDay(trip.start)} – ${_monthDay(trip.end)}',
      stats: _stats(trip),
      tabBar: tabBar,
      menu: menu,
      topPadding: media.padding.top,
      screen: media.size,
      textScaler: media.textScaler,
      animate: animationsOn(context, ref),
      brightness: scheme.brightness,
    );

    return Scaffold(
      body: NestedScrollView(
        key: _scroll,
        headerSliverBuilder: (context, _) => [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverPersistentHeader(pinned: true, delegate: header),
          ),
        ],
        // The pinned part of the header stays on top of the body; start the tab content below it.
        body: Padding(
          padding: EdgeInsets.only(top: header.minExtent),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: TabBarView(
              controller: _tabs,
              children: [
                ItineraryView(
                  trip: trip,
                  role: role,
                  day: day,
                  onDayChanged: (d) => setState(() => _day = d),
                ),
                GearView(tripId: trip.id),
                MealsView(
                  trip: trip,
                  day: _mealDay,
                  onDayChanged: (d) => setState(() => _mealDay = d),
                ),
                DiscussionView(trip: trip, role: role),
                MembersView(trip: trip, role: role),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: switch (_tabs.index) {
        0 when role.canEditShared => FloatingActionButton.extended(
          onPressed: () =>
              showItemFormSheet(context, trip: trip, initialDay: day),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('新增節點'),
        ),
        // Gear and meals are the person's own data: everyone may edit them.
        1 => FloatingActionButton.extended(
          onPressed: () => showGearFormSheet(context, tripId: trip.id),
          icon: const Icon(Icons.add),
          label: const Text('新增裝備'),
        ),
        2 => FloatingActionButton.extended(
          onPressed: () =>
              showMealFormSheet(context, tripId: trip.id, dayIndex: _mealDay),
          icon: const Icon(Icons.add),
          label: const Text('新增餐食'),
        ),
        _ => null,
      },
    );
  }

  Future<void> _delete(BuildContext context, Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除這個行程？'),
        content: Text(
          trip.isSample ? '範例行程會從這支手機移除。' : '「${trip.name}」與它的所有節點都會刪除，無法復原。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 44),
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(tripRepositoryProvider).delete(trip.id);
    if (context.mounted) context.go(Routes.trips); // not pop: the missing-trip redirect may already have left
  }
}
