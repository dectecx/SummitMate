import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../../gear/domain/gear_logic.dart';
import '../../gear/providers.dart';
import '../../map/maplibre/rudy_providers.dart';
import '../../meals/domain/meal_logic.dart';
import '../../meals/providers.dart';
import '../providers.dart';

/// What is still to do for the next trip. Every line opens the place where it is done.
class TripChecklist extends ConsumerWidget {
  const TripChecklist({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nodes = ref.watch(itineraryProvider(trip.id)).value ?? const <ItineraryItem>[];
    final gear = ref.watch(gearProvider(trip.id)).value ?? const <GearItem>[];
    final meals = ref.watch(mealsProvider(trip.id)).value ?? const <MealEntry>[];
    final map = ref.watch(rudyReadyProvider).value; // unknown until the files have been looked for
    final packed = packedCount(gear);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('準備清單', style: theme.textTheme.titleSmall),
        _Line(
          id: 'nodes',
          label: '行程節點',
          value: nodes.isEmpty ? '還沒排' : '${nodes.length} 個',
          done: nodes.isNotEmpty,
          onTap: () => context.push(Routes.trip(trip.id)),
        ),
        _Line(
          id: 'gear',
          label: '裝備打包',
          value: gear.isEmpty ? '還沒列' : '$packed / ${gear.length}',
          done: gear.isNotEmpty && packed == gear.length,
          onTap: () => context.push(Routes.tripTab(trip.id, 1)),
        ),
        _Line(
          id: 'meals',
          label: '餐食',
          value: meals.isEmpty ? '還沒排' : '${meals.length} 項',
          done: meals.isNotEmpty,
          onTap: () => context.push(Routes.tripTab(trip.id, 2)),
        ),
        if (map != null)
          _Line(id: 'map', label: '離線地圖', value: map ? '已下載' : '還沒下載', done: map, onTap: () => context.push(Routes.offlineMaps)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.id, required this.label, required this.value, required this.done, required this.onTap});
  final String id;
  final String label;
  final String value;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      checked: done,
      child: InkWell(
        key: ValueKey('checklist-$id'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: done ? scheme.primary : scheme.outline),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text(value, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
              Icon(Icons.chevron_right, size: 20, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
