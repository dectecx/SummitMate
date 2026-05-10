import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/domain.dart';
import '../cubits/meal/meal_cubit.dart';
import '../cubits/meal/meal_state.dart';
import 'food_reference_screen.dart';
import '../widgets/responsive_layout.dart';
import '../utils/meal_utils.dart';

/// 糧食計畫畫面
///
/// 顯示每日的餐點規劃，支援依餐別 (早餐、午餐、晚餐等) 新增與編輯食材。
/// 自動計算總熱量與總重量。
class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealCubit, MealState>(
      builder: (context, state) {
        if (state is! MealLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final dailyPlans = state.dailyPlans;
        final cubit = context.read<MealCubit>();

        return DefaultTabController(
          length: dailyPlans.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('糧食計畫'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: '參考資訊',
                  onPressed: () => FoodReferenceScreen.show(context),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                indicatorWeight: 4.0,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
                tabs: dailyPlans.map((plan) => Tab(text: plan.day)).toList(),
              ),
            ),
            body: TabBarView(
              children: dailyPlans.map((plan) {
                return ResponsiveLayout(
                  mobile: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      _buildSummaryCard(context, plan),
                      ...MealType.values.map(
                        (type) => _buildMealSection(context, cubit, plan.day, type, plan.meals[type] ?? []),
                      ),
                    ],
                  ),
                  desktop: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      children: [
                        _buildSummaryCard(context, plan),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 24,
                                children: MealType.values.map((type) {
                                  final items = plan.meals[type] ?? [];
                                  return SizedBox(
                                    width: 420,
                                    child: _buildMealSection(context, cubit, plan.day, type, items),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, DailyMealPlan plan) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem(
              context,
              icon: Icons.scale_outlined,
              label: '總重量',
              value: '${plan.totalWeight.toStringAsFixed(0)} g',
              color: theme.colorScheme.onPrimaryContainer,
            ),
            Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
            _buildSummaryItem(
              context,
              icon: Icons.local_fire_department_outlined,
              label: '總熱量',
              value: '${plan.totalCalories.toStringAsFixed(1).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")} kcal',
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
        ),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, MealCubit cubit, String day, MealType type, List<MealItem> items) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MealUIUtils.getMealColor(type).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(MealUIUtils.getMealIcon(type), color: MealUIUtils.getMealColor(type)),
        ),
        title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: items.isNotEmpty
            ? Text(
                '${items.length} 項 • ${items.fold<double>(0, (sum, i) => sum + i.weight * i.quantity).toStringAsFixed(0)}g • ${items.fold<double>(0, (sum, i) => sum + i.calories * i.quantity).toStringAsFixed(0)}kcal',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              )
            : Text('尚未規劃', style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
        children: [
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
              child: Column(
                children: [
                  Icon(Icons.no_meals_outlined, size: 48, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('此餐點尚未加入任何食材', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            ),
          if (items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (item.quantity > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${(item.weight * item.quantity).toStringAsFixed(0)}g  /  ${(item.calories * item.quantity).toStringAsFixed(0)}kcal',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                color: theme.colorScheme.onSurfaceVariant,
                                onPressed: item.quantity > 1
                                    ? () => cubit.updateMealItemQuantity(day, type, item.id, item.quantity - 1)
                                    : null,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                color: theme.colorScheme.primary,
                                onPressed: () => cubit.updateMealItemQuantity(day, type, item.id, item.quantity + 1),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: theme.colorScheme.error,
                          onPressed: () => _confirmRemoveMeal(context, cubit, day, type, item.id, item.name),
                          tooltip: '刪除',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _showAddMealDialog(context, cubit, day, type),
                icon: const Icon(Icons.add),
                label: const Text('新增食材'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMeal(
    BuildContext context,
    MealCubit cubit,
    String day,
    MealType type,
    String itemId,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除糧食'),
        content: Text('確定要刪除「$itemName」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              cubit.removeMealItem(day, type, itemId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, MealCubit cubit, String day, MealType type) {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final calCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新增 ${type.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '食物名稱', hintText: '例如：乾燥飯'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    decoration: const InputDecoration(labelText: '重量 (g)', hintText: '100'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: calCtrl,
                    decoration: const InputDecoration(labelText: '熱量 (kcal)', hintText: '350'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final weight = double.tryParse(weightCtrl.text) ?? 0;
              final cal = double.tryParse(calCtrl.text) ?? 0;
              if (name.isNotEmpty) {
                cubit.addMealItem(day, type, name, weight, cal);
                Navigator.pop(context);
              }
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }
}
