import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/meal_repository.dart';
import 'domain/meal_logic.dart';

final mealRepositoryProvider = Provider((ref) => MealRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider)));
final mealsProvider = StreamProvider.family<List<MealEntry>, String>((ref, tripId) => ref.watch(mealRepositoryProvider).watch(tripId));
