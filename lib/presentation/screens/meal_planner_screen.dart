import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // optional
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/meal_item.dart';
import '../cubits/meal/meal_cubit.dart';
import '../cubits/meal/meal_state.dart';
// import '../providers/meal_provider.dart'; // Removed
import 'food_reference_screen.dart';

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
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
                    indicatorColor: Colors.white,
                    indicatorWeight: 4.0,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
                    tabs: dailyPlans.map((plan) => Tab(text: plan.day)).toList(),
                  ),
                ),
                body: TabBarView(
                  children: dailyPlans.map((plan) {
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        _buildSummaryCard(context, plan),
                        ...MealType.values.map(
                          (type) => _buildMealSection(context, cubit, plan.day, type, plan.meals[type] ?? []),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, DailyMealPlan plan) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('總重量', style: TextStyle(fontSize: 12)),
                Text(
                  '${plan.totalWeight.toStringAsFixed(0)} g',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Column(
              children: [
                const Text('總熱量', style: TextStyle(fontSize: 12)),
                Text(
                  '${plan.totalCalories.toStringAsFixed(1).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, MealCubit cubit, String day, MealType type, List<MealItem> items) {
    if (items.isEmpty && type != MealType.breakfast && type != MealType.lunch && type != MealType.dinner) {
      // 隱藏非主要且空的餐別，這裡選擇顯示所有以方便規劃，或者只摺疊
      // 策略：顯示 Header，若空則顯示 placeholder 鼓勵新增
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(_getMealIcon(type), color: _getMealColor(type)),
        title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: items.isNotEmpty
            ? Text(
                '${items.length} 項 • ${items.fold<double>(0, (sum, i) => sum + i.weight * i.quantity).toStringAsFixed(0)}g • ${items.fold<double>(0, (sum, i) => sum + i.calories * i.quantity).toStringAsFixed(0)}kcal',
              )
            : const Text('尚未規劃', style: TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showAddMealDialog(context, cubit, day, type),
        ),
        children: items.isEmpty
            ? [const SizedBox(height: 10)]
            : items
                  .map(
                    (item) => ListTile(
                      title: Row(
                        children: [
                          Flexible(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                          if (item.quantity > 1) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x${item.quantity}',
                                style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${(item.weight * item.quantity).toStringAsFixed(0)}g / ${(item.calories * item.quantity).toStringAsFixed(0)}kcal',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                            onPressed: item.quantity > 1
                                ? () => cubit.updateMealItemQuantity(day, type, item.id, item.quantity - 1)
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
                            onPressed: () => cubit.updateMealItemQuantity(day, type, item.id, item.quantity + 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                            onPressed: () => _confirmRemoveMeal(context, cubit, day, type, item.id, item.name),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
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

  IconData _getMealIcon(MealType type) {
    switch (type) {
      case MealType.preBreakfast:
        return Icons.wb_twilight;
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.teatime:
        return Icons.coffee;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.action:
        return Icons.directions_walk;
      case MealType.emergency:
        return Icons.medical_services;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.preBreakfast:
        return Colors.indigo;
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.teatime:
        return Colors.brown;
      case MealType.dinner:
        return Colors.deepPurple;
      case MealType.action:
        return Colors.blue;
      case MealType.emergency:
        return Colors.red;
    }
  }
}
