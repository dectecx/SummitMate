import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/itinerary_item.dart';
import '../../../domain/entities/gear_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/entities/daily_meal_plan.dart';
import '../../cubits/tutorial/tutorial_cubit.dart';
import '../../cubits/tutorial/tutorial_state.dart';
import '../../cubits/itinerary/itinerary_cubit.dart';
import '../../cubits/itinerary/itinerary_state.dart';
import '../../cubits/gear/gear_cubit.dart';
import '../../cubits/gear/gear_state.dart';
import '../../cubits/meal/meal_cubit.dart';
import '../../cubits/meal/meal_state.dart';
import '../../cubits/trip/trip_cubit.dart';
import '../../cubits/trip/trip_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tutorial-Aware Builders
//
// 這些 widget 是 UI 層的「資料來源代理」。
// 當教學模式開啟時，從 TutorialActive state 讀取 mock 資料。
// 當教學模式關閉時，從各業務 Cubit 讀取真實資料。
//
// 業務 Cubit (ItineraryCubit、GearCubit、MealCubit、TripCubit) 完全不需要
// 知道教學模式的存在，保持純淨的業務邏輯。
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────
// Itinerary
// ─────────────────────────────

/// 行程資料 (供 builder callback 使用的 data class)
class ItineraryViewData {
  final List<ItineraryItem> items;
  final String selectedDay;
  final List<String> dayNames;
  final bool isEditMode;

  const ItineraryViewData({
    required this.items,
    required this.selectedDay,
    required this.dayNames,
    this.isEditMode = false,
  });

  List<ItineraryItem> get currentDayItems =>
      items.where((item) => item.day == selectedDay).toList()
        ..sort((a, b) => a.estTime.compareTo(b.estTime));
}

/// 根據教學狀態決定行程資料來源
class TutorialAwareItineraryBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ItineraryViewData data) builder;

  const TutorialAwareItineraryBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TutorialCubit, TutorialState>(
      builder: (context, tutorialState) {
        if (tutorialState is TutorialActive) {
          final data = ItineraryViewData(
            items: tutorialState.mockItineraryItems,
            selectedDay: tutorialState.mockDayNames.isNotEmpty
                ? tutorialState.mockDayNames.first
                : 'D1',
            dayNames: tutorialState.mockDayNames,
          );
          return builder(context, data);
        }
        return BlocBuilder<ItineraryCubit, ItineraryState>(
          builder: (context, state) {
            if (state is! ItineraryLoaded) {
              return builder(
                context,
                const ItineraryViewData(items: [], selectedDay: 'D1', dayNames: []),
              );
            }
            final data = ItineraryViewData(
              items: state.items,
              selectedDay: state.selectedDay,
              dayNames: state.dayNames,
              isEditMode: state.isEditMode,
            );
            return builder(context, data);
          },
        );
      },
    );
  }
}

// ─────────────────────────────
// Gear
// ─────────────────────────────

/// 根據教學狀態決定裝備資料來源
class TutorialAwareGearBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, List<GearItem> items) builder;

  const TutorialAwareGearBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TutorialCubit, TutorialState>(
      builder: (context, tutorialState) {
        if (tutorialState is TutorialActive) {
          return builder(context, tutorialState.mockGearItems);
        }
        return BlocBuilder<GearCubit, GearState>(
          builder: (context, state) {
            return builder(
              context,
              state is GearLoaded ? state.items : [],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────
// Meal
// ─────────────────────────────

/// 根據教學狀態決定糧食計畫資料來源
class TutorialAwareMealBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, List<DailyMealPlan> plans) builder;

  const TutorialAwareMealBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TutorialCubit, TutorialState>(
      builder: (context, tutorialState) {
        if (tutorialState is TutorialActive) {
          return builder(context, tutorialState.mockMealPlans);
        }
        return BlocBuilder<MealCubit, MealState>(
          builder: (context, state) {
            return builder(
              context,
              state is MealLoaded ? state.dailyPlans : [],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────
// Trip
// ─────────────────────────────

/// 根據教學狀態決定行程（Trip）資料來源
///
/// 這是解決 MainNavigationScreen hasTrips 判斷問題的關鍵：
/// 教學模式下即使 TripCubit 無真實行程，也會提供 mock trip。
class TutorialAwareTripBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Trip? activeTrip, List<Trip> trips) builder;

  const TutorialAwareTripBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TutorialCubit, TutorialState>(
      builder: (context, tutorialState) {
        if (tutorialState is TutorialActive && tutorialState.mockTrip != null) {
          return builder(
            context,
            tutorialState.mockTrip,
            [tutorialState.mockTrip!],
          );
        }
        return BlocBuilder<TripCubit, TripState>(
          builder: (context, state) {
            if (state is! TripLoaded) {
              return builder(context, null, []);
            }
            return builder(context, state.activeTrip, state.trips);
          },
        );
      },
    );
  }
}
