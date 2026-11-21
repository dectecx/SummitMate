import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/presentation/cubits/meal/meal_cubit.dart';
import 'package:summitmate/presentation/cubits/meal/meal_state.dart';
import 'package:summitmate/domain/domain.dart';

class MockTripRepository extends Mock implements ITripRepository {}

void main() {
  group('MealCubit', () {
    late MealCubit mealCubit;
    late MockTripRepository mockTripRepository;

    setUp(() {
      mockTripRepository = MockTripRepository();
      mealCubit = MealCubit(mockTripRepository);
      registerFallbackValue(const MealPlanDay(id: '', name: ''));
    });

    tearDown(() {
      mealCubit.close();
    });

    test('Given MealCubit, When executing, Then initial state is MealInitial', () {
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
      final initialDays = [
        const MealPlanDay(id: 'day1', name: 'Original Day'),
        const MealPlanDay(id: 'day2', name: 'Linked Day', linkedItineraryDay: 'D1'),
      ];

      setUp(() {
        when(() => mockTripRepository.getMealPlanDays(any())).thenAnswer((_) async => Success(initialDays));
        when(
          () => mockTripRepository.getDailyMealPlans(any()),
        ).thenAnswer((_) async => Success(initialDays.map((d) => DailyMealPlan(dayInfo: d)).toList()));
        when(() => mockTripRepository.markTripAsPendingUpdate(any())).thenAnswer((_) async => const Success(null));
      });

      blocTest<MealCubit, MealState>(
        'addMealPlanDay adds a new day',
        build: () {
          when(
            () => mockTripRepository.addMealPlanDay(any(), any(), linkedItineraryDay: any(named: 'linkedItineraryDay')),
          ).thenAnswer((_) async => const Success(MealPlanDay(id: 'new-id', name: 'New Independent Day')));
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.addMealPlanDay('New Independent Day');
        },
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 2), // load
          isA<MealLoaded>()
              .having((s) => s.dailyPlans.length, 'length', 3) // add
              .having((s) => s.dailyPlans.last.dayInfo.name, 'name', 'New Independent Day'),
        ],
      );

      blocTest<MealCubit, MealState>(
        'renameMealPlanDay renames an unlinked day',
        build: () {
          when(
            () => mockTripRepository.updateMealPlanDay(any(), 'day1', 'Renamed Day', linkedItineraryDay: null),
          ).thenAnswer((_) async => const Success(MealPlanDay(id: 'day1', name: 'Renamed Day')));
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.renameMealPlanDay('day1', 'Renamed Day');
        },
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 2), // load
          isA<MealLoaded>().having((s) => s.dailyPlans[0].dayInfo.name, 'name', 'Renamed Day'), // update
        ],
      );

      blocTest<MealCubit, MealState>(
        'renameMealPlanDay ignores linked day',
        build: () => mealCubit,
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.renameMealPlanDay('day2', 'Attempt Rename');
        },
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 2), // load only
        ],
      );

      blocTest<MealCubit, MealState>(
        'linkMealPlanDay links to itinerary day',
        build: () {
          when(
            () => mockTripRepository.updateMealPlanDay(any(), 'day1', 'D2', linkedItineraryDay: 'D2'),
          ).thenAnswer((_) async => const Success(MealPlanDay(id: 'day1', name: 'D2', linkedItineraryDay: 'D2')));
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.linkMealPlanDay('day1', 'D2');
        },
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 2), // load
          isA<MealLoaded>().having((s) => s.dailyPlans[0].dayInfo.linkedItineraryDay, 'linked', 'D2'), // update
        ],
      );

      blocTest<MealCubit, MealState>(
        'unlinkMealPlanDay unlinks from itinerary day',
        build: () {
          when(
            () => mockTripRepository.updateMealPlanDay(any(), 'day2', 'Linked Day', linkedItineraryDay: null),
          ).thenAnswer(
            (_) async => const Success(MealPlanDay(id: 'day2', name: 'Linked Day', linkedItineraryDay: null)),
          );
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.unlinkMealPlanDay('day2');
        },
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 2), // load
          isA<MealLoaded>().having((s) => s.dailyPlans[1].dayInfo.linkedItineraryDay, 'linked', null), // update
        ],
      );

      blocTest<MealCubit, MealState>(
        'deleteMealPlanDay removes the day',
        build: () {
          when(() => mockTripRepository.deleteMealPlanDay(any(), 'day1')).thenAnswer((_) async => const Success(null));
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.deleteMealPlanDay('day1');
        },
        expect: () => [
          isA<MealLoaded>().having((s) => s.dailyPlans.length, 'length', 2), // load
          isA<MealLoaded>()
              .having((s) => s.dailyPlans.length, 'length', 1) // delete
              .having((s) => s.dailyPlans.first.dayInfo.id, 'id', 'day2'),
        ],
      );
    });

    group('Meal Item Management', () {
      final initialDays = [const MealPlanDay(id: 'day1', name: 'Day 1')];
      final initialMeal = const MealItem(id: 'item1', name: 'Bread', weight: 100, calories: 200, quantity: 1);
      final initialDailyPlan = DailyMealPlan(
        dayInfo: initialDays[0],
        meals: {
          MealType.breakfast: [initialMeal],
        },
      );

      setUp(() {
        when(() => mockTripRepository.getDailyMealPlans(any())).thenAnswer((_) async => Success([initialDailyPlan]));
        when(() => mockTripRepository.markTripAsPendingUpdate(any())).thenAnswer((_) async => const Success(null));
      });

      blocTest<MealCubit, MealState>(
        'addMealItem adds a new item',
        build: () {
          when(
            () => mockTripRepository.addMealItem('day1', MealType.breakfast, 'Coffee', 50, 10, note: null),
          ).thenAnswer(
            (_) async => const Success(MealItem(id: 'item2', name: 'Coffee', weight: 50, calories: 10, quantity: 1)),
          );
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.addMealItem('day1', MealType.breakfast, 'Coffee', 50, 10);
        },
        expect: () => [
          isA<MealLoaded>(), // load
          isA<MealLoaded>().having((s) => s.dailyPlans[0].meals[MealType.breakfast]?.length, 'length', 2), // add
        ],
      );

      blocTest<MealCubit, MealState>(
        'removeMealItem removes an item',
        build: () {
          when(() => mockTripRepository.removeMealItem('item1')).thenAnswer((_) async => const Success(null));
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.removeMealItem('day1', MealType.breakfast, 'item1');
        },
        expect: () => [
          isA<MealLoaded>(), // load
          isA<MealLoaded>().having((s) => s.dailyPlans[0].meals[MealType.breakfast]?.length, 'length', 0), // remove
        ],
      );

      blocTest<MealCubit, MealState>(
        'updateMealItemQuantity updates the quantity',
        build: () {
          when(
            () => mockTripRepository.updateMealItemQuantity('item1', 3),
          ).thenAnswer((_) async => const Success(null));
          return mealCubit;
        },
        act: (cubit) async {
          await cubit.loadMealPlans('test-trip-id');
          await cubit.updateMealItemQuantity('day1', MealType.breakfast, 'item1', 3);
        },
        expect: () => [
          isA<MealLoaded>(), // load
          isA<MealLoaded>().having(
            (s) => s.dailyPlans[0].meals[MealType.breakfast]?.first.quantity,
            'quantity',
            3,
          ), // update
        ],
      );
    });
  });
}
