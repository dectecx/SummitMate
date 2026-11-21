import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/coming_soon.dart';
import '../../gear/ui/gear_form_sheet.dart';
import '../../gear/ui/gear_view.dart';
import '../../meals/ui/meal_form_sheet.dart';
import '../../meals/ui/meals_view.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';
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

class _TripDetailPageState extends ConsumerState<TripDetailPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));
  int? _day;
  int _mealDay = 1;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int _initialDay(Trip trip) {
    final n = ref.read(clockProvider)();
    final today = DateTime(n.year, n.month, n.day);
    if (phaseOf(trip, today) == TripPhase.ongoing) return today.difference(trip.start).inDays + 1;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final trip = tripAsync.value;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: tripAsync.isLoading ? const Center(child: CircularProgressIndicator()) : const ComingSoon(icon: Icons.search_off, message: '找不到這個行程，可能已被刪除'),
      );
    }
    final role = ref.watch(myRoleProvider(trip.id)) ?? TripRole.member;
    final day = _day ?? _initialDay(trip);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (role.canEditShared)
            PopupMenuButton<String>(
              tooltip: '更多',
              onSelected: (v) {
                if (v == 'edit') showTripFormSheet(context, trip: trip);
                if (v == 'delete') _delete(context, trip);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('編輯行程')),
                if (role.canDeleteTrip) const PopupMenuItem(value: 'delete', child: Text('刪除行程')),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: '行程'), Tab(text: '裝備'), Tab(text: '餐食'), Tab(text: '成員')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ItineraryView(trip: trip, role: role, day: day, onDayChanged: (d) => setState(() => _day = d)),
          GearView(tripId: trip.id),
          MealsView(trip: trip, day: _mealDay, onDayChanged: (d) => setState(() => _mealDay = d)),
          const ComingSoon(icon: Icons.group_outlined, message: '成員與天氣即將推出'),
        ],
      ),
      floatingActionButton: switch (_tabs.index) {
        0 when role.canEditShared => FloatingActionButton.extended(
          onPressed: () => showItemFormSheet(context, trip: trip, initialDay: day),
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
          onPressed: () => showMealFormSheet(context, tripId: trip.id, dayIndex: _mealDay),
          icon: const Icon(Icons.add),
          label: const Text('新增餐點'),
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
        content: Text(trip.isSample ? '範例行程會從這支手機移除。' : '「${trip.name}」與它的所有節點都會刪除，無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44), backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(tripRepositoryProvider).delete(trip.id);
    if (context.mounted) context.pop();
  }
}
