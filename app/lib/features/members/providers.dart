import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_state.dart';
import '../../core/providers.dart';
import '../trips/providers.dart';
import 'data/member_repository.dart';
import 'data/user_search_api.dart';
import 'domain/member_logic.dart';

final memberRepositoryProvider = Provider((ref) => MemberRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider)));
final userSearchApiProvider = Provider<UserSearchApi>((ref) => DioUserSearchApi(ref.watch(authedDioProvider)));

/// The members list of a trip, with the signed-in person included even before the server confirms them.
final memberLinesProvider = Provider.family<List<MemberLine>, String>((ref, tripId) {
  final trip = ref.watch(tripProvider(tripId)).value;
  if (trip == null) return const [];
  final auth = ref.watch(authStateProvider).value ?? ref.watch(authRepositoryProvider).state;
  final user = switch (auth) {
    SignedIn(:final user) || NeedsReauth(:final user) => user,
    Guest() => null,
  };
  return buildMemberLines(
    trip: trip,
    members: ref.watch(tripMembersProvider(tripId)).value ?? const [],
    myId: user?.id,
    myName: user?.displayName ?? '',
    myAvatar: user?.avatar ?? '',
  );
});
