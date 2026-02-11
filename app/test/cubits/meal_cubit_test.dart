import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/meal_item.dart';
import 'package:summitmate/presentation/cubits/meal/meal_cubit.dart';
import 'package:summitmate/presentation/cubits/meal/meal_state.dart';

void main() {
  group('MealCubit', () {
    late MealCubit mealCubit;

    setUp(() {
      mealCubit = MealCubit();
    });

    tearDown(() {
      mealCubit.close();
    });

    test('initial state is MealLoaded with default plans', () {
      expect(mealCubit.state, isA<MealLoaded>());
      expect((mealCubit.state as MealLoaded).dailyPlans.length, 3);
    });

    blocTest<MealCubit, MealState>(
      'reset emits MealLoaded with default days',
      seed: () => const MealLoaded(dailyPlans: []),
      build: () => mealCubit,
      act: (cubit) => cubit.reset(),
      expect: () => [isA<MealLoaded>().having((state) => state.dailyPlans.length, 'dailyPlans length', 3)],
    );

    blocTest<MealCubit, MealState>(
      'addMealItem adds item and updates weight',
      build: () => mealCubit,
      act: (cubit) => cubit.addMealItem('D1', MealType.lunch, 'Rice', 100, 350),
      expect: () => [isA<MealLoaded>().having((s) => s.totalWeightKg, 'weight 0.1kg', 0.1)],
    );

    blocTest<MealCubit, MealState>(
      'removeMealItem removes item',
      build: () => mealCubit,
      act: (cubit) async {
        cubit.addMealItem('D1', MealType.lunch, 'Rice', 100, 350);
        await Future.delayed(Duration.zero);
        final state = cubit.state as MealLoaded;
        final item = state.dailyPlans.firstWhere((p) => p.day == 'D1').meals[MealType.lunch]!.first;
        cubit.removeMealItem('D1', MealType.lunch, item.id);
      },
      expect: () => [
        isA<MealLoaded>().having((s) => s.totalWeightKg, 'added', 0.1),
        isA<MealLoaded>().having((s) => s.totalWeightKg, 'removed', 0.0),
      ],
    );
  });
}
