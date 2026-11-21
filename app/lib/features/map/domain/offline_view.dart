import '../../../core/db/app_database.dart';
import '../data/offline_manager.dart';
import 'offline_regions.dart';

/// A region together with what is known about its download.
class OfflineEntry {
  const OfflineEntry(this.def, this.row);
  final OfflineRegionDef def;

  /// Null when the person has not asked to download it.
  final OfflineRegion? row;

  String get state => row?.state ?? 'none';

  /// 0..1 progress of a running or interrupted download.
  double get progress {
    final r = row;
    if (r == null || r.tilesTotal <= 0) return 0;
    return (r.tilesDone / r.tilesTotal).clamp(0, 1).toDouble();
  }
}

/// The three groups of the offline maps screen. They are all shown at the same time, so a running
/// download never hides what else can be downloaded.
class OfflineSections {
  const OfflineSections({required this.active, required this.done, required this.available});

  /// Queued, downloading, failed or interrupted: things that need attention or are in progress.
  final List<OfflineEntry> active;
  final List<OfflineEntry> done;
  final List<OfflineEntry> available;

  /// Bytes taken by what was downloaded so far.
  double get usedBytes => [...active, ...done].fold(0.0, (s, e) => s + (e.row?.bytes ?? 0));
}

OfflineSections buildOfflineSections(List<OfflineRegion> rows) {
  final byId = {for (final r in rows) r.id: r};
  final active = <OfflineEntry>[], done = <OfflineEntry>[], available = <OfflineEntry>[];
  for (final def in allOfflineRegions) {
    final row = byId[def.id];
    final entry = OfflineEntry(def, row);
    switch (row?.state) {
      case null:
        available.add(entry);
      case OfflineState.done:
        done.add(entry);
      default:
        active.add(entry);
    }
  }
  // Running first, then waiting, then the ones that need a decision.
  const order = {OfflineState.downloading: 0, OfflineState.queued: 1, OfflineState.interrupted: 2, OfflineState.failed: 3};
  active.sort((a, b) => (order[a.state] ?? 9).compareTo(order[b.state] ?? 9));
  return OfflineSections(active: active, done: done, available: available);
}
