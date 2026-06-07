import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/domain.dart';
import '../cubits/meal/meal_cubit.dart';
import '../cubits/meal/meal_state.dart';
import 'food_reference_screen.dart';
import '../widgets/responsive_layout.dart';
import '../utils/meal_utils.dart';
import '../widgets/meal/meal_day_management_dialog.dart';
import '../cubits/tutorial/tutorial_cubit.dart';
import '../cubits/tutorial/tutorial_state.dart';
import '../widgets/tutorial/tutorial_aware_builder.dart';
import '../widgets/meal/add_meal_dialog.dart';

/// 糧食計畫畫面
///
/// 顯示每日的餐點規劃，支援依餐別 (早餐、午餐、晚餐等) 新增與編輯食材。
/// 自動計算總熱量與總重量。
class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorialAwareMealBuilder(
      builder: (context, dailyPlans) {
        final isTutorial = context.watch<TutorialCubit>().state is TutorialActive;
        final mealState = context.watch<MealCubit>().state;

        if (!isTutorial && mealState is! MealLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final cubit = context.read<MealCubit>();

        if (dailyPlans.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('糧食計畫'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  tooltip: '管理天數',
                  onPressed: () => MealDayManagementDialog.show(context),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: '參考資訊',
                  onPressed: () => FoodReferenceScreen.show(context),
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('尚未建立糧食計畫', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('管理天數'),
                    onPressed: () => MealDayManagementDialog.show(context),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: dailyPlans.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('糧食計畫'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  tooltip: '管理天數',
                  onPressed: () => MealDayManagementDialog.show(context),
                ),
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
                tabs: dailyPlans.map((plan) => Tab(text: plan.dayInfo.name)).toList(),
              ),
            ),
            body: TabBarView(
              children: dailyPlans.map((plan) {
                return _DailyPlanView(plan: plan, cubit: cubit);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _DailyPlanView extends StatefulWidget {
  final DailyMealPlan plan;
  final MealCubit cubit;

  const _DailyPlanView({required this.plan, required this.cubit});

  @override
  State<_DailyPlanView> createState() => _DailyPlanViewState();
}

class _DailyPlanViewState extends State<_DailyPlanView> with AutomaticKeepAliveClientMixin {
  final ValueNotifier<bool> _expandCollapseNotifier = ValueNotifier<bool>(false); // 預設收合以優化效能

  @override
  void dispose() {
    _expandCollapseNotifier.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必須呼叫
    final plan = widget.plan;
    final cubit = widget.cubit;
    final theme = Theme.of(context);

    // 明顯的展開/收合按鈕
    Widget expandCollapseAction = ValueListenableBuilder<bool>(
      valueListenable: _expandCollapseNotifier,
      builder: (context, isExpanded, child) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FilledButton.tonalIcon(
              onPressed: () {
                _expandCollapseNotifier.value = !isExpanded;
              },
              icon: Icon(isExpanded ? Icons.unfold_less : Icons.unfold_more),
              label: Text(isExpanded ? '全部收合' : '全部展開', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        );
      },
    );

    // 建立 MealSection 卡片的方法
    Widget buildMealCard(MealType type) {
      return _MealSectionCard(
        cubit: cubit,
        dayId: plan.dayInfo.id,
        type: type,
        items: plan.meals[type] ?? [],
        expandCollapseNotifier: _expandCollapseNotifier,
        initiallyExpanded: _expandCollapseNotifier.value, // 使用當前狀態
        onRemove: (itemId, itemName) => _confirmRemoveMeal(context, cubit, plan.dayInfo.id, type, itemId, itemName),
        onAdd: () => _showAddMealDialog(context, cubit, plan.dayInfo.id, type),
      );
    }

    return ResponsiveLayout(
      mobile: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          _buildSummaryCard(context, plan),
          expandCollapseAction,
          ...MealType.values.map((type) => buildMealCard(type)),
        ],
      ),
      desktop: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _buildSummaryCard(context, plan),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: expandCollapseAction),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: MealType.values.map((type) {
                      return SizedBox(width: 420, child: buildMealCard(type));
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, DailyMealPlan plan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.primaryContainer.withValues(alpha: 0.7)],
        ),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                context,
                icon: Icons.scale_rounded,
                label: '打包總重',
                value: '${plan.totalWeight.toStringAsFixed(0)} g',
                color: colorScheme.onPrimaryContainer,
              ),
              Container(width: 1, height: 48, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.15)),
              _buildSummaryItem(
                context,
                icon: Icons.local_fire_department_rounded,
                label: '預估熱量',
                value: '${plan.totalCalories.toStringAsFixed(1).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")} kcal',
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
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

  void _confirmRemoveMeal(
    BuildContext context,
    MealCubit cubit,
    String dayId,
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
              cubit.removeMealItem(dayId, type, itemId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, MealCubit cubit, String dayId, MealType type) {
    AddMealDialog.show(
      context,
      mealType: type,
      onAdd: (name, weight, calories) {
        cubit.addMealItem(dayId, type, name, weight, calories);
      },
    );
  }
}

class _MealSectionCard extends StatefulWidget {
  final MealCubit cubit;
  final String dayId;
  final MealType type;
  final List<MealItem> items;
  final ValueNotifier<bool> expandCollapseNotifier;
  final bool initiallyExpanded;
  final void Function(String, String) onRemove;
  final VoidCallback onAdd;

  const _MealSectionCard({
    required this.cubit,
    required this.dayId,
    required this.type,
    required this.items,
    required this.expandCollapseNotifier,
    required this.initiallyExpanded,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  State<_MealSectionCard> createState() => _MealSectionCardState();
}

class _MealSectionCardState extends State<_MealSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    widget.expandCollapseNotifier.addListener(_syncExpand);
  }

  void _syncExpand() {
    if (mounted) {
      setState(() {
        _expanded = widget.expandCollapseNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    widget.expandCollapseNotifier.removeListener(_syncExpand);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MealUIUtils.getMealColor(widget.type, context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      MealUIUtils.getMealIcon(widget.type),
                      color: MealUIUtils.getMealColor(widget.type, context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.type.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        items.isNotEmpty
                            ? Text(
                                '${items.length} 項 • ${items.fold<double>(0, (sum, i) => sum + i.weight * i.quantity).toStringAsFixed(0)}g • ${items.fold<double>(0, (sum, i) => sum + i.calories * i.quantity).toStringAsFixed(0)}kcal',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                              )
                            : Text('尚未規劃', style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
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
                  Column(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    items[i].name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                if (items[i].quantity > 1) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'x${items[i].quantity}',
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
                                '${(items[i].weight * items[i].quantity).toStringAsFixed(0)}g  /  ${(items[i].calories * items[i].quantity).toStringAsFixed(0)}kcal',
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
                                        onPressed: items[i].quantity > 1
                                            ? () => widget.cubit.updateMealItemQuantity(
                                                widget.dayId,
                                                widget.type,
                                                items[i].id,
                                                items[i].quantity - 1,
                                              )
                                            : null,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          '${items[i].quantity}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        color: theme.colorScheme.primary,
                                        onPressed: () => widget.cubit.updateMealItemQuantity(
                                          widget.dayId,
                                          widget.type,
                                          items[i].id,
                                          items[i].quantity + 1,
                                        ),
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
                                  onPressed: () => widget.onRemove(items[i].id, items[i].name),
                                  tooltip: '刪除',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('新增食材'),
                    ),
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }
}
