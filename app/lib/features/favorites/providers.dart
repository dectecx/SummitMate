import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/favorite_repository.dart';

final favoriteRepositoryProvider = Provider(
  (ref) => FavoriteRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxWriterProvider),
  ),
);

/// Ids of the starred items of a kind (see [FavoriteKind]), in the order they were starred.
final favoriteTargetsProvider = StreamProvider.family<List<String>, String>(
  (ref, kind) => ref.watch(favoriteRepositoryProvider).watchTargets(kind),
);

/// The starred mountains' ids.
final favoriteMountainIdsProvider = Provider<Set<String>>(
  (ref) =>
      (ref.watch(favoriteTargetsProvider(FavoriteKind.mountain)).value ??
              const [])
          .toSet(),
);
