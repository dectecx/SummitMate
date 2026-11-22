import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_state.dart';
import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import 'data/itinerary_repository.dart';
import 'data/trip_copier.dart';
import 'data/trip_repository.dart';
import '../library/providers.dart';
import 'domain/route_points.dart';
import 'domain/trip_logic.dart';

/// "Now", replaceable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final tripRepositoryProvider = Provider((ref) => TripRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider)));
final itineraryRepositoryProvider = Provider((ref) => ItineraryRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider)));

final tripsProvider = StreamProvider<List<Trip>>((ref) => ref.watch(tripRepositoryProvider).watchAll());
final tripProvider = StreamProvider.family<Trip?, String>((ref, id) => ref.watch(tripRepositoryProvider).watch(id));
final tripMembersProvider = StreamProvider.family<List<TripMember>, String>((ref, id) => ref.watch(tripRepositoryProvider).watchMembers(id));
/// Node names used on trips to a mountain, most used first.
final routePointsProvider = StreamProvider.family<List<RoutePoint>, String>(
  (ref, mountainId) => ref.watch(itineraryRepositoryProvider).watchForMountain(mountainId).map(routePointsFrom),
);

final itineraryProvider = StreamProvider.family<List<ItineraryItem>, String>((ref, id) => ref.watch(itineraryRepositoryProvider).watch(id));

/// The signed-in person's id, or null for a guest.
final accountIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateProvider).value ?? ref.watch(authRepositoryProvider).state;
  return switch (auth) {
    SignedIn(:final user) || NeedsReauth(:final user) => user.id,
    Guest() => null,
  };
});

/// What the person may do in a trip; null until the trip is loaded.
final myRoleProvider = Provider.family<TripRole?, String>((ref, tripId) {
  final trip = ref.watch(tripProvider(tripId)).value;
  if (trip == null) return null;
  final members = ref.watch(tripMembersProvider(tripId)).value ?? const [];
  return roleFor(trip: trip, accountId: ref.watch(accountIdProvider), members: members);
});

final tripCopierProvider = Provider((ref) => TripCopier(ref.watch(tripRepositoryProvider), ref.watch(itineraryRepositoryProvider), ref.watch(templateRepositoryProvider)));
