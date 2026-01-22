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

class GearTab extends StatefulWidget {
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
    // final mealProvider = context.watch<MealProvider>(); // Removed
    final mealState = context.watch<MealCubit>().state;
    final mealWeight = mealState is MealLoaded ? mealState.totalWeightKg : 0.0;

    return MultiBlocListener(
      listeners: [
        BlocListener<TripCubit, TripState>(
          listener: (context, state) {
            if (state is TripLoaded && widget.tripId == null) {
              // If trip changes and we are tracking active trip, reload
              final activeTripId = state.activeTrip?.id;
              if (activeTripId != null && context.read<GearCubit>().currentTripId != activeTripId) {
                context.read<GearCubit>().loadGear(activeTripId);
              }
            }
          },
        ),
      ],
      child: BlocBuilder<GearCubit, GearState>(
        builder: (context, state) {
          final totalWeight = (state is GearLoaded ? state.totalWeightKg : 0.0) + mealWeight;

          // Checking loading state is tricky because we might want to show previous data while reloading?
          // Assuming GearState tracks loading.
          if (state is GearInitial) {
            // Try load again if initial (e.g. came from background)
            _loadGear();
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GearLoading && (state as dynamic).items == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GearError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is! GearLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            body: Column(
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
                      // 快速連結 (官方/雲端/個人庫)
                      const GearQuickLinks(),
                      const SizedBox(height: 8),
                      // 總重量
                      GearTotalWeightCard(totalWeight: totalWeight),
                      const SizedBox(height: 8),
                      // 糧食計畫
                      GearMealCard(mealWeight: mealWeight),
                      const SizedBox(height: 16),

                      // 分類清單
                      if (state.items.isEmpty)
                        Padding(
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
                        )
                      else
                        ...state.itemsByCategory.entries.map(
                          (entry) => GearCategorySection(category: entry.key, items: entry.value, mode: _mode),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => AddGearDialog.show(context),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
