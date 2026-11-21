import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import 'data/gear_repository.dart';

final gearRepositoryProvider = Provider((ref) => GearRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider)));
final gearProvider = StreamProvider.family<List<GearItem>, String>((ref, tripId) => ref.watch(gearRepositoryProvider).watch(tripId));
