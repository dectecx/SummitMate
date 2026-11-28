import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'meal_icons.dart';
import '../../../core/db/app_database.dart';
import '../../gear/domain/gear_logic.dart';
import '../../trips/domain/trip_logic.dart';
import '../domain/meal_logic.dart';
import '../providers.dart';
import 'meal_form_sheet.dart';
import '../../../shared/brand/illustrations.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/reorderable_group.dart';
import '../../../shared/pills.dart';
import '../../../shared/icon_badge.dart';

/// "餐食": the person's own meal plan, one day at a time, with weight and calorie totals.
class MealsView extends ConsumerStatefulWidget {
  const MealsView({super.key, required this.trip, required this.day, required this.onDayChanged});
  final Trip trip;
  final int day;
  final ValueChanged<int> onDayChanged;

  @override
  ConsumerState<MealsView> createState() => _MealsViewState();
}

class _MealsViewState extends ConsumerState<MealsView> {
  bool _reordering = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final day = widget.day;
    final onDayChanged = widget.onDayChanged;
    final all = ref.watch(mealsProvider(trip.id)).value ?? const <MealEntry>[];
    final days = mealDayIndexes(trip, all);
    final today = entriesOfDay(all, day);
    final groups = groupMeals(today);
    final theme = Theme.of(context);

    return Column(
      children: [
        DayBar(
          itemCount: days.length,
          itemBuilder: (_, i) {
            final d = days[i];
            return DayPill(key: ValueKey('meal-day-$d'), label: dayLabel(d), date: trip.dateOfDay(d), selected: d == day, onTap: () => onDayChanged(d));
          },
        ),
        Card(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const IconBadge(Icons.restaurant_outlined, size: 48),
                Expanded(child: _Total(label: '今天', weight: totalMealWeight(today), kcal: totalCalories(today))),
                Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                Expanded(child: _Total(label: '全程', weight: totalMealWeight(all), kcal: totalCalories(all))),
              ],
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const ComingSoon(illustration: Illustration.meal, message: '這一天還沒有餐食。這份計畫只有你看得到，按右下角新增。')
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), child: ReorderToggle(reordering: _reordering, onChanged: (v) => setState(() => _reordering = v))),
                      ),
                    ),
                    for (final g in groups)
                      ReorderableGroupSliver(
                        key: ValueKey('meal-group-${g.type.key}'),
                        title: g.type.label,
                        icon: mealIcon(g.type),
                        trailing: formatWeight(g.entries.fold<double>(0, (sum, e) => sum + e.weight)),
                        reordering: _reordering,
                        ids: [for (final e in g.entries) e.item.id],
                        onReorder: (ids) => ref.read(mealRepositoryProvider).reorder(ids),
                        itemBuilder: (_, i) {
                          final e = g.entries[i];
                          final detail = [if (e.item.quantity > 1) '× ${e.item.quantity}', if (e.item.note.isNotEmpty) e.item.note].join('  ·  ');
                          return ListTile(
                            shape: const RoundedRectangleBorder(),
                            onTap: _reordering ? null : () => showMealFormSheet(context, tripId: trip.id, dayIndex: day, entry: e),
                            title: Text(e.item.name.isEmpty ? '（未命名）' : e.item.name),
                            subtitle: detail.isEmpty ? null : Text(detail),
                            trailing: _reordering
                                ? ReorderHandle(index: i)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [Text(formatWeight(e.weight)), if (e.calories > 0) Text(formatKcal(e.calories), style: theme.textTheme.bodySmall)],
                                  ),
                          );
                        },
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.weight, required this.kcal});
  final String label;
  final double weight;
  final double kcal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(formatWeight(weight), style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface)),
        if (kcal > 0) Text(formatKcal(kcal), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
