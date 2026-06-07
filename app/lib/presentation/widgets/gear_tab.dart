import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/gear/gear_cubit.dart';
import '../cubits/gear/gear_state.dart';
import '../cubits/trip/trip_cubit.dart';
import '../cubits/trip/trip_state.dart';
import '../cubits/meal/meal_cubit.dart';
import '../cubits/meal/meal_state.dart';
import 'gear/gear_mode_selector.dart';
import 'gear/gear_search_bar.dart';
import 'gear/gear_summary_cards.dart';
import 'gear/gear_category_section.dart';
import 'gear/dialogs/add_gear_dialog.dart';
import '../../../domain/domain.dart';
import '../../../core/core.dart';
import 'responsive_layout.dart';
import '../cubits/tutorial/tutorial_cubit.dart';
import '../cubits/tutorial/tutorial_state.dart';
import 'tutorial/tutorial_aware_builder.dart';

/// 裝備管理頁籤
///
/// 顯示裝備清單、搜尋、分類檢視，並支援新增/編輯/刪除裝備。
/// 使用 [GearCubit] 管理狀態，並監聽 [TripCubit] 取得當前行程。
class GearTab extends StatefulWidget {
  /// 指定行程 ID (若為 null 則使用當前活動行程)
  final String? tripId;

  const GearTab({super.key, this.tripId});

  @override
  State<GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<GearTab> {
  final TextEditingController _searchController = TextEditingController();
  GearListMode _mode = GearListMode.view;

  @override
  void initState() {
    super.initState();
    _loadGear();
  }

  void _loadGear() {
    final tripCubit = context.read<TripCubit>();
    String? targetId = widget.tripId;

    if (targetId == null && tripCubit.state is TripLoaded) {
      targetId = (tripCubit.state as TripLoaded).activeTrip?.id;
    }

    if (targetId != null) {
      context.read<GearCubit>().loadGear(targetId);
    }
  }

  @override
  void didUpdateWidget(GearTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tripId != oldWidget.tripId) {
      _loadGear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealState = context.watch<MealCubit>().state;
    final mealWeight = mealState is MealLoaded ? mealState.totalWeightKg : 0.0;

    return TutorialAwareGearBuilder(
        builder: (context, items) {
          final totalWeight = items.fold(0.0, (sum, item) => sum + item.totalWeight) / 1000 + mealWeight;

          final gearState = context.watch<GearCubit>().state;
          final isTutorial = context.watch<TutorialCubit>().state is TutorialActive;

          if (!isTutorial) {
            if (gearState is GearInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (gearState is GearLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (gearState is GearError) {
              return Center(child: Text('Error: ${gearState.message}'));
            }

            if (gearState is! GearLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
          }

          // Generate itemsByCategory and filteredItems manually since we only have List<GearItem>
          final selectedCategory = !isTutorial && gearState is GearLoaded ? gearState.selectedCategory : null;
          final showUncheckedOnly = !isTutorial && gearState is GearLoaded ? gearState.showUncheckedOnly : false;
          final searchQuery = !isTutorial && gearState is GearLoaded ? gearState.searchQuery : '';

          var filteredItems = items;
          if (selectedCategory != null) {
            filteredItems = filteredItems.where((item) => item.category == selectedCategory).toList();
          }
          if (showUncheckedOnly) {
            filteredItems = filteredItems.where((item) => !item.isChecked).toList();
          }
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            filteredItems = filteredItems.where((item) => item.name.toLowerCase().contains(query)).toList();
          }

          final itemsByCategory = <String, List<GearItem>>{};
          for (final cat in GearCategory.all) {
            final filtered = filteredItems.where((item) => item.category == cat).toList();
            if (filtered.isNotEmpty) {
              itemsByCategory[cat] = filtered;
            }
          }

          return Scaffold(
            body: ResponsiveLayout(
              mobile: Column(
                children: [
                  // 搜尋欄
                  GearSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<GearCubit>().setSearchQuery(value);
                      setState(() {});
                    },
                    onClear: () {
                      _searchController.clear();
                      context.read<GearCubit>().setSearchQuery('');
                      setState(() {});
                    },
                  ),

                  // 模式切換器
                  GearModeSelector(selectedMode: _mode, onModeChanged: (newMode) => setState(() => _mode = newMode)),
                  const SizedBox(height: 8),

                  // 列表內容
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        const GearQuickLinks(),
                        const SizedBox(height: 8),
                        GearTotalWeightCard(totalWeight: totalWeight),
                        const SizedBox(height: 8),
                        GearMealCard(mealWeight: mealWeight),
                        const SizedBox(height: 16),
                        if (items.isEmpty)
                          _buildEmptyState(context)
                        else
                          ...itemsByCategory.entries.map(
                            (entry) => GearCategorySection(category: entry.key, items: entry.value, mode: _mode),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
              desktop: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: GearSearchBar(
                        controller: _searchController,
                        onChanged: (value) {
                          context.read<GearCubit>().setSearchQuery(value);
                          setState(() {});
                        },
                        onClear: () {
                          _searchController.clear();
                          context.read<GearCubit>().setSearchQuery('');
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 左側資訊面板
                            SizedBox(
                              width: 360,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  GearModeSelector(
                                    selectedMode: _mode,
                                    onModeChanged: (newMode) => setState(() => _mode = newMode),
                                  ),
                                  const SizedBox(height: 16),
                                  const GearQuickLinks(),
                                  const SizedBox(height: 16),
                                  GearTotalWeightCard(totalWeight: totalWeight),
                                  const SizedBox(height: 8),
                                  GearMealCard(mealWeight: mealWeight),
                                ],
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            // 右側裝備列表
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  if (items.isEmpty)
                                    _buildEmptyState(context)
                                  else
                                    ...itemsByCategory.entries.map(
                                      (entry) =>
                                          GearCategorySection(category: entry.key, items: entry.value, mode: _mode),
                                    ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => AddGearDialog.show(context),
              child: const Icon(Icons.add),
            ),
          );
        },
      );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.backpack_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text('目前沒有自定義裝備', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
