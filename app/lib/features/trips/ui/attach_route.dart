import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../gpx/providers.dart';
import '../../gpx/ui/route_library_sheet.dart';
import '../domain/track_codec.dart';
import '../providers.dart';

/// Puts a saved route on [trip]: a simplified copy, stored with the trip so that teammates see it too.
Future<void> attachRoute(BuildContext context, WidgetRef ref, Trip trip) async {
  final messenger = ScaffoldMessenger.of(context);
  // read before the panel opens: the page may be rebuilt while it is up
  final library = ref.read(gpxLibraryProvider);
  final trips = ref.read(tripRepositoryProvider);
  final id = await showRouteLibrary(context, title: '附加到「${trip.name}」');
  if (id == null) return;
  final route = await library.load(id);
  if (route == null) {
    messenger.showSnackBar(const SnackBar(content: Text('找不到這個路線檔，請重新匯入。')));
    return;
  }
  await trips.update(trip.id, track: Value(encodeTrack(simplifyTrack(route.points))));
  messenger.showSnackBar(SnackBar(content: Text('已附加路線「${route.name}」')));
}
