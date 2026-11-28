import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import 'members_view.dart';

/// Where a person travelling alone invites others: their trip shows no members tab until someone joins.
class TeamPage extends ConsumerWidget {
  const TeamPage({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider(tripId)).value;
    return Scaffold(
      appBar: AppBar(title: const Text('邀請隊友')),
      body: trip == null ? const SizedBox.shrink() : MembersView(trip: trip, role: ref.watch(myRoleProvider(tripId)) ?? TripRole.member),
    );
  }
}
