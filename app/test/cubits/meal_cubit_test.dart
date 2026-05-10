import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/presentation/cubits/meal/meal_cubit.dart';
import 'package:summitmate/presentation/cubits/meal/meal_state.dart';
import 'package:summitmate/domain/entities/daily_meal_plan.dart';
import 'package:summitmate/domain/entities/meal_plan_day.dart';
import 'package:summitmate/data/repositories/mock/mock_trip_repository.dart';

void main() {
  group('MealCubit', () {
    late MealCubit mealCubit;
    late MockTripRepository mockTripRepository;

    setUp(() {
      mockTripRepository = MockTripRepository();
      mealCubit = MealCubit(mockTripRepository);
    });

    tearDown(() {
      mealCubit.close();
    });

    test('initial state is MealInitial', () {
      expect(mealCubit.state, isA<MealInitial>());
    });

    blocTest<MealCubit, MealState>(
      'reset emits MealInitial',
      seed: () => const MealLoaded(dailyPlans: []),
      build: () => mealCubit,
      act: (cubit) => cubit.reset(),
      expect: () => [isA<MealInitial>()],
    );

    group('Day Management', () {
      final initialPlans = [
        DailyMealPlan(dayInfo: const MealPlanDay(id: 'day1', name: 'Original Day')),
        DailyMealPlan(dayInfo: const MealPlanDay(id: 'day2', name: 'Linked Day', linkedItineraryDay: 'D1')),
      ];

      blocTest<MealCubit, MealState>(
        'addMealPlanDay adds a new day',
        seed: () => MealLoaded(dailyPlans: initialPlans),
        build: () => mealCubit,
        act: (cubit) => cubit.addMealPlanDay('New Independent Day'),
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 3)
                           .having((s) => s.dailyPlans.last.dayInfo.name, 'name', 'New Independent Day'),
        ],
      );

      blocTest<MealCubit, MealState>(
        'renameMealPlanDay renames an unlinked day',
        seed: () => MealLoaded(dailyPlans: initialPlans),
        build: () => mealCubit,
        act: (cubit) => cubit.renameMealPlanDay('day1', 'Renamed Day'),
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans[0].dayInfo.name, 'name', 'Renamed Day'),
        ],
      );

      blocTest<MealCubit, MealState>(
        'renameMealPlanDay ignores linked day',
        seed: () => MealLoaded(dailyPlans: initialPlans),
        build: () => mealCubit,
        act: (cubit) => cubit.renameMealPlanDay('day2', 'Attempt Rename'),
        expect: () => [], // Should not emit any new state since linked days can't be renamed
      );

      blocTest<MealCubit, MealState>(
        'linkMealPlanDay links to itinerary day',
        seed: () => MealLoaded(dailyPlans: initialPlans),
        build: () => mealCubit,
        act: (cubit) => cubit.linkMealPlanDay('day1', 'D2'),
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans[0].dayInfo.linkedItineraryDay, 'linked', 'D2'),
        ],
      );

      blocTest<MealCubit, MealState>(
        'unlinkMealPlanDay unlinks from itinerary day',
        seed: () => MealLoaded(dailyPlans: initialPlans),
        build: () => mealCubit,
        act: (cubit) => cubit.unlinkMealPlanDay('day2'),
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans[1].dayInfo.linkedItineraryDay, 'linked', null),
        ],
      );

      blocTest<MealCubit, MealState>(
        'deleteMealPlanDay removes the day',
        seed: () => MealLoaded(dailyPlans: initialPlans),
        build: () => mealCubit,
        act: (cubit) => cubit.deleteMealPlanDay('day1'),
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 1)
                           .having((s) => s.dailyPlans.first.dayInfo.id, 'id', 'day2'),
        ],
      );
    });
  });
}
