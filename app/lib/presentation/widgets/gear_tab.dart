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
import '../utils/gear_utils.dart';
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

          // 非教學模式直接沿用 GearLoaded 的篩選/分組 getter；
          // 教學模式無 GearLoaded 狀態，對 mock items 做無篩選分組。
          final itemsByCategory = !isTutorial && gearState is GearLoaded
              ? gearState.itemsByCategory
              : GearFilter.groupByCategory(items, categoryOf: (item) => item.category);

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
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const GearQuickLinks(),
                                const SizedBox(height: 8),
                                GearTotalWeightCard(totalWeight: totalWeight),
                                const SizedBox(height: 8),
                                GearMealCard(mealWeight: mealWeight),
                              ],
                            ),
                          ),
                        ),
                        if (items.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState(context))
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverMainAxisGroup(
                              slivers: [
                                for (final entry in itemsByCategory.entries)
                                  GearCategorySection(category: entry.key, items: entry.value, mode: _mode),
                              ],
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
                              child: CustomScrollView(
                                slivers: [
                                  if (items.isEmpty)
                                    SliverToBoxAdapter(child: _buildEmptyState(context))
                                  else
                                    SliverPadding(
                                      padding: const EdgeInsets.all(16),
                                      sliver: SliverMainAxisGroup(
                                        slivers: [
                                          for (final entry in itemsByCategory.entries)
                                            GearCategorySection(
                                              category: entry.key,
                                              items: entry.value,
                                              mode: _mode,
                                            ),
                                        ],
                                      ),
                                    ),
                                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
