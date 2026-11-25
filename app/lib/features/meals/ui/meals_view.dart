import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../gear/domain/gear_logic.dart';
import '../../trips/domain/trip_logic.dart';
import '../domain/meal_logic.dart';
import '../providers.dart';
import 'meal_form_sheet.dart';
import '../../../shared/brand/illustrations.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/group_card.dart';

/// "餐食": the person's own meal plan, one day at a time, with weight and calorie totals.
class MealsView extends ConsumerWidget {
  const MealsView({super.key, required this.trip, required this.day, required this.onDayChanged});
  final Trip trip;
  final int day;
  final ValueChanged<int> onDayChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(mealsProvider(trip.id)).value ?? const <MealEntry>[];
    final days = mealDayIndexes(trip, all);
    final today = entriesOfDay(all, day);
    final groups = groupMeals(today);
    final theme = Theme.of(context);

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
                key: ValueKey('meal-day-$d'),
                label: Text('${dayLabel(d)}  ${date.month}/${date.day}'),
                selected: d == day,
                onSelected: (_) => onDayChanged(d),
              );
            },
          ),
        ),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _Total(label: '今天', weight: totalMealWeight(today), kcal: totalCalories(today))),
                Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                Expanded(child: _Total(label: '全程', weight: totalMealWeight(all), kcal: totalCalories(all))),
              ],
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const ComingSoon(illustration: Illustration.meal, message: '這一天還沒有餐點。這份計畫只有你看得到，按右下角新增。')
              : ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final g in groups)
                      GroupCard(
                        title: g.type.label,
                        trailing: formatWeight(g.entries.fold<double>(0, (sum, e) => sum + e.weight)),
                        children: [
                          for (final e in g.entries)
                            ListTile(
                              shape: const RoundedRectangleBorder(),
                              onTap: () => showMealFormSheet(context, tripId: trip.id, dayIndex: day, entry: e),
                              title: Text(e.item.name.isEmpty ? '（未命名）' : e.item.name),
                              subtitle: Text([if (e.item.quantity > 1) '× ${e.item.quantity}', if (e.item.note.isNotEmpty) e.item.note].join('  ·  ')),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [Text(formatWeight(e.weight)), Text(formatKcal(e.calories), style: theme.textTheme.bodySmall)],
                              ),
                            ),
                        ],
                      ),
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
        Text(formatWeight(weight), style: theme.textTheme.titleMedium),
        Text(formatKcal(kcal), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
