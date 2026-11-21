import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/mountain_repository.dart';
import 'domain/mountain_models.dart';

final exploreApiProvider = Provider<ExploreApi>((ref) => DioExploreApi(ref.watch(publicDioProvider)));
final mountainRepositoryProvider = Provider((ref) => MountainRepository(ref.watch(appDatabaseProvider), ref.watch(exploreApiProvider)));
final mountainsProvider = StreamProvider<MountainsState>((ref) => ref.watch(mountainRepositoryProvider).watch());
