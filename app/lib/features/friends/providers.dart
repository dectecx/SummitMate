import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../trips/providers.dart';
import 'data/friends_api.dart';

final friendsApiProvider = Provider<FriendsApi>((ref) => DioFriendsApi(ref.watch(authedDioProvider)));

/// My friends and pending requests. Needs a connection and a signed-in person; guests and offline get an empty list
/// and the error is exposed for the page to explain. Refresh with `ref.invalidate(friendsProvider)`.
final friendsProvider = FutureProvider.autoDispose<FriendsOverview>((ref) async {
  if (ref.watch(accountIdProvider) == null) return const FriendsOverview();
  return ref.watch(friendsApiProvider).overview();
});
