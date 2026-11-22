import '../../../core/db/app_database.dart';

/// A node name that was used before on trips to the same mountain.
class RoutePoint {
  const RoutePoint({required this.name, required this.count, required this.altitude, this.lat, this.lng});
  final String name;

  /// How many nodes carry this name.
  final int count;

  /// Of the most recent node with this name; 0 when unknown.
  final int altitude;
  final double? lat;
  final double? lng;
}

/// Groups [items] (from trips to one mountain, oldest first) by name, most used first. This is how shared names
/// like 1K處 or 涼亭 stay tied to one route: the list comes only from trips with the same main mountain.
List<RoutePoint> routePointsFrom(List<ItineraryItem> items) {
  final byName = <String, List<ItineraryItem>>{};
  for (final i in items) {
    final n = i.name.trim();
    if (n.isEmpty) continue;
    byName.putIfAbsent(n, () => []).add(i);
  }
  final points = [
    for (final e in byName.entries)
      RoutePoint(
        name: e.key,
        count: e.value.length,
        altitude: e.value.lastWhere((i) => i.altitude > 0, orElse: () => e.value.last).altitude,
        lat: e.value.lastWhere((i) => i.lat != null && i.lng != null, orElse: () => e.value.last).lat,
        lng: e.value.lastWhere((i) => i.lat != null && i.lng != null, orElse: () => e.value.last).lng,
      ),
  ]..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.name.compareTo(b.name));
  return points;
}
