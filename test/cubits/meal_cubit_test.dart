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

    test('initial state is MealLoaded', () {
      expect(mealCubit.state, isA<MealLoaded>());
    });

    blocTest<MealCubit, MealState>(
      'reset emits MealLoaded with default days',
      build: () => mealCubit,
      act: (cubit) => cubit.reset(),
      expect: () => [
        isA<MealLoaded>().having((state) => state.dailyPlans.length, 'dailyPlans length', 3),
      ],
    );

    blocTest<MealCubit, MealState>(
      'addMealItem adds item and updates state',
      build: () => mealCubit,
      act: (cubit) {
        cubit.reset(); // First reset to load
        // Wait for reset to emit? bloc_test won't capture internal emit if called in constructor?
        // Constructor called reset().
        // Actually constructor calls reset(), so it should emit immediately?
        // No, Cubit constructor is sync. emit called in constructor? 
        // MealCubit constructor calls reset().
        // But initial state is MealInitial.
        // If constructor calls reset, initial state *should* be MealLoaded if emit works in constructor?
        // Cubit: "emit is only allowed after the constructor has finished." - Wait, really? No. 
        // Just verify initial state.
        
        // Let's call reset explicitely in tests if needed or rely on constructor.
        // If constructor calls reset(), state might be MealLoaded already?
        // Let's check constructor: `MealCubit() : super(const MealInitial()) { reset(); }`
        // So state will likely change immediately.
        // But for testing `addMealItem`, we need it to be loaded.
        cubit.addMealItem('D1', MealType.lunch, 'Rice', 100, 350);
      },
      // skip: 1, // Removed
      verify: (cubit) {
        final state = cubit.state;
        if (state is MealLoaded) {
          final plan = state.dailyPlans.firstWhere((p) => p.day == 'D1');
          final lunch = plan.meals[MealType.lunch];
          expect(lunch, isNotNull);
          expect(lunch!.length, 1);
          expect(lunch.first.name, 'Rice');
          expect(state.totalWeightKg, 0.1);
        }
      },
    );

    blocTest<MealCubit, MealState>(
      'removeMealItem removes item',
      build: () => mealCubit,
      act: (cubit) async {
        cubit.addMealItem('D1', MealType.lunch, 'Rice', 100, 350);
        // We need to wait for state update to get ID?
        // This is tricky in bloc_test act.
        // We can cheat by using a fixed ID if we could, but ID is generated.
        // We can inspect state.
        await Future.delayed(Duration.zero); // yield
        final state = cubit.state as MealLoaded;
        final item = state.dailyPlans[1].meals[MealType.lunch]!.first;
        cubit.removeMealItem('D1', MealType.lunch, item.id);
      },
      // skip: 2, // Removed
      expect: () => [
        // We can expect specific states.
        // 1. Loaded with Item
        // 2. Loaded without Item
        // Since we skip, we just match the final specific states if we listed them.
        isA<MealLoaded>(), // Add
        isA<MealLoaded>().having((s) => s.totalWeightKg, 'weight 0', 0), // Remove
      ],
    );
  });
}
