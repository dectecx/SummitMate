import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_state.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../trips/providers.dart';
import 'data/message_repository.dart';
import 'data/poll_repository.dart';

final messageRepositoryProvider = Provider(
  (ref) => MessageRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxWriterProvider),
    () => ref.read(accountIdProvider),
    now: ref.watch(clockProvider),
  ),
);
final pollRepositoryProvider = Provider(
  (ref) => PollRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(outboxWriterProvider),
    () => ref.read(accountIdProvider),
    now: ref.watch(clockProvider),
  ),
);

final messagesProvider = StreamProvider.family<List<TripMessage>, String>(
  (ref, tripId) => ref.watch(messageRepositoryProvider).watch(tripId),
);
final pollsProvider = StreamProvider.family<List<Poll>, String>(
  (ref, tripId) => ref.watch(pollRepositoryProvider).watchPolls(tripId),
);
final pollOptionsProvider = StreamProvider.family<List<PollOption>, String>(
  (ref, tripId) => ref.watch(pollRepositoryProvider).watchOptions(tripId),
);
final pollVotesProvider = StreamProvider.family<List<PollVote>, String>(
  (ref, tripId) => ref.watch(pollRepositoryProvider).watchVotes(tripId),
);

/// The signed-in person's id and profile; all null/empty for a guest.
typedef MyProfile = ({String? id, String name, String avatar});

final myProfileProvider = Provider<MyProfile>((ref) {
  final auth =
      ref.watch(authStateProvider).value ??
      ref.watch(authRepositoryProvider).state;
  return switch (auth) {
    SignedIn(:final user) || NeedsReauth(:final user) => (
      id: user.id,
      name: user.displayName,
      avatar: user.avatar,
    ),
    Guest() => (id: null, name: '', avatar: ''),
  };
});
