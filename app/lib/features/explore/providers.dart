import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/mountain_repository.dart';
import 'data/shop_repository.dart';
import 'domain/mountain_models.dart';
import 'domain/shop_models.dart';

final exploreApiProvider = Provider<ExploreApi>((ref) => DioExploreApi(ref.watch(publicDioProvider)));
final mountainRepositoryProvider = Provider((ref) => MountainRepository(ref.watch(appDatabaseProvider), ref.watch(exploreApiProvider)));
final mountainsProvider = StreamProvider<MountainsState>((ref) => ref.watch(mountainRepositoryProvider).watch());

final shopsApiProvider = Provider<ShopsApi>((ref) => DioShopsApi(ref.watch(publicDioProvider)));
final shopRepositoryProvider = Provider((ref) => ShopRepository(ref.watch(appDatabaseProvider), ref.watch(shopsApiProvider)));
final shopsProvider = StreamProvider<ShopsState>((ref) => ref.watch(shopRepositoryProvider).watch());
