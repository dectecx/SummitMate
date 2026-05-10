import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/meal_plan_day.dart';
import '../../cubits/meal/meal_cubit.dart';
import '../../cubits/meal/meal_state.dart';
import '../../cubits/trip/trip_cubit.dart';
import '../../cubits/trip/trip_state.dart';

class MealDayManagementDialog extends StatelessWidget {
  const MealDayManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => const MealDayManagementDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('管理糧食計畫天數', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // Explanation text
              Text('獨立的糧食天數可以手動管理，也可以將其綁定到目前的行程天數以同步顯示。', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 12),

              // Days List
              Expanded(
                child: BlocBuilder<MealCubit, MealState>(
                  builder: (context, mealState) {
                    if (mealState is! MealLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final plans = mealState.dailyPlans;
                    if (plans.isEmpty) {
                      return const Center(child: Text('目前沒有任何糧食天數'));
                    }

                    return ListView.separated(
                      itemCount: plans.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final dayInfo = plans[index].dayInfo;
                        return _DayItemCard(dayInfo: dayInfo);
                      },
                    );
                  },
                ),
              ),

              // Add New Day Button
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showAddDayDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('新增獨立糧食天數'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDayDialog(BuildContext context) {
    final mealCubit = context.read<MealCubit>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增天數'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '天數名稱', hintText: '例如：行前準備'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                mealCubit.addMealPlanDay(name);
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

class _DayItemCard extends StatelessWidget {
  final MealPlanDay dayInfo;

  const _DayItemCard({required this.dayInfo});

  @override
  Widget build(BuildContext context) {
    final isLinked = dayInfo.linkedItineraryDay != null;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLinked ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLinked ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
          width: isLinked ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLinked ? Icons.link : Icons.link_off,
            color: isLinked ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayInfo.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isLinked ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                  ),
                ),
                if (isLinked)
                  Text(
                    '已綁定至行程天數: ${dayInfo.linkedItineraryDay}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)),
                  )
                else
                  Text('獨立天數 (未綁定)', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            color: theme.colorScheme.onSurfaceVariant,
            tooltip: '編輯',
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final mealCubit = context.read<MealCubit>();
    final isLinked = dayInfo.linkedItineraryDay != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('編輯 ${dayInfo.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (isLinked) ...[
                const Text('此天數已綁定行程，無法重新命名。'),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    mealCubit.unlinkMealPlanDay(dayInfo.id);
                    Navigator.pop(bottomSheetContext);
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text('解除綁定'),
                ),
              ] else ...[
                // Rename section
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('重新命名'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showRenameDialog(context, mealCubit);
                  },
                ),
                const Divider(),
                // Link section
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('綁定至行程天數'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showLinkDialog(context, mealCubit);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('刪除此天數', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showDeleteConfirmDialog(context, mealCubit);
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, MealCubit mealCubit) {
    final controller = TextEditingController(text: dayInfo.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '新名稱'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != dayInfo.name) {
                mealCubit.renameMealPlanDay(dayInfo.id, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _showLinkDialog(BuildContext context, MealCubit mealCubit) {
    final tripState = context.read<TripCubit>().state;
    List<String> availableDays = [];

    if (tripState is TripLoaded && tripState.activeTrip != null) {
      // Get all day names from the active trip
      availableDays = tripState.activeTrip!.dayNames;
    }

    if (availableDays.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('無法綁定'),
          content: const Text('目前行程沒有設定任何天數，請先到行程頁面新增天數。'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('確認'))],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('選擇要綁定的行程天數'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableDays.length,
              itemBuilder: (context, index) {
                final targetDay = availableDays[index];
                return ListTile(
                  title: Text(targetDay),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    mealCubit.linkMealPlanDay(dayInfo.id, targetDay);
                    Navigator.pop(dialogContext);
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消'))],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MealCubit mealCubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除天數'),
        content: Text('確定要刪除「${dayInfo.name}」嗎？這將會一併移除該天數內的所有糧食紀錄且無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              mealCubit.deleteMealPlanDay(dayInfo.id);
              Navigator.pop(context);
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}
