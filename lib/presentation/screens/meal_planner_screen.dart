
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/meal_item.dart';
import '../providers/meal_provider.dart';
import 'food_reference_screen.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MealProvider>(
      builder: (context, provider, child) {
        return DefaultTabController(
          length: provider.dailyPlans.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('糧食計畫'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: '參考資訊',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FoodReferenceScreen()),
                  ),
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
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
                tabs: provider.dailyPlans.map((plan) => Tab(text: plan.day)).toList(),
              ),
            ),
            body: TabBarView(
              children: provider.dailyPlans.map((plan) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    _buildSummaryCard(context, plan),
                    ...MealType.values.map((type) => _buildMealSection(context, provider, plan.day, type, plan.meals[type] ?? [])),
                  ],
                );
              }).toList(),
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
                Text('${plan.totalWeight.toStringAsFixed(0)} g', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Column(
              children: [
                const Text('總熱量', style: TextStyle(fontSize: 12)),
                Text('${plan.totalCalories} kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, MealProvider provider, String day, MealType type, List<MealItem> items) {
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
            ? Text('${items.length} 項 • ${items.fold<double>(0, (sum, i) => sum + i.weight).toStringAsFixed(0)}g') 
            : const Text('尚未規劃', style: TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _showAddMealDialog(context, provider, day, type),
        ),
        children: items.isEmpty 
            ? [const SizedBox(height: 10)] 
            : items.map((item) => ListTile(
                title: Text(item.name),
                subtitle: Text('${item.weight.toStringAsFixed(0)}g / ${item.calories}kcal'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  onPressed: () => provider.removeMealItem(day, type, item.id),
                ),
              )).toList(),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, MealProvider provider, String day, MealType type) {
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
                    keyboardType: TextInputType.number,
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
              final cal = int.tryParse(calCtrl.text) ?? 0;
              if (name.isNotEmpty) {
                provider.addMealItem(day, type, name, weight, cal);
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
      case MealType.preBreakfast: return Icons.wb_twilight;
      case MealType.breakfast: return Icons.wb_sunny;
      case MealType.lunch: return Icons.lunch_dining;
      case MealType.teatime: return Icons.coffee;
      case MealType.dinner: return Icons.dinner_dining;
      case MealType.action: return Icons.directions_walk;
      case MealType.emergency: return Icons.medical_services;
    }
  }

  Color _getMealColor(MealType type) {
    switch (type) {
      case MealType.preBreakfast: return Colors.indigo;
      case MealType.breakfast: return Colors.orange;
      case MealType.lunch: return Colors.green;
      case MealType.teatime: return Colors.brown;
      case MealType.dinner: return Colors.deepPurple;
      case MealType.action: return Colors.blue;
      case MealType.emergency: return Colors.red;
    }
  }
}
