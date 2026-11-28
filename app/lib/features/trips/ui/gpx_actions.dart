import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';
import '../../../core/db/app_database.dart';
import '../../explore/domain/mountain_models.dart';
import '../../explore/providers.dart';
import '../../gpx/domain/gpx_codec.dart';
import '../../gpx/domain/gpx_models.dart';
import '../data/gpx_import.dart';
import '../domain/gpx_trip.dart';
import '../domain/trip_logic.dart';
import '../providers.dart';

/// Lets the person pick a GPX file and puts its route on [trip], asking before replacing one and whether the
/// file's points should become nodes too.
Future<void> importGpxInto(BuildContext context, WidgetRef ref, Trip trip) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final picked = await FilePicker.pickFiles(dialogTitle: '選擇 GPX 檔案');
    if (picked.isEmpty || !context.mounted) return;
    final doc = parseGpx(utf8.decode(await picked.first.readAsBytes(), allowMalformed: true));
    final imported = tripFromGpx(doc, today: ref.read(clockProvider)());
    if (imported.track.length < 2) {
      messenger.showSnackBar(const SnackBar(content: Text('這個檔案沒有路線軌跡，只能從首頁匯入成新行程。')));
      return;
    }
    if (decodeTrack(trip.track).length >= 2) {
      if (!context.mounted) return;
      final replace = await _ask(context, title: '換掉目前的路線？', message: '這個行程原本的路線會被新檔案取代。', yes: '換掉', no: '取消');
      if (replace != true) return;
    }
    var addNodes = false;
    if (doc.waypoints.isNotEmpty) {
      if (!context.mounted) return;
      final answer = await _ask(context, title: '也加入節點嗎？', message: '檔案裡有 ${imported.nodes.length} 個航點，可以一起加到行程節點。', yes: '加入節點', no: '只要路線');
      if (answer == null) return;
      addNodes = answer;
    }
    await attachGpx(ref.read(tripRepositoryProvider), ref.read(itineraryRepositoryProvider), trip.id, imported, dayCount: trip.dayCount, addNodes: addNodes);
    messenger.showSnackBar(const SnackBar(content: Text('已加入路線')));
  } on GpxFormatException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('這個檔案不是可用的 GPX：${e.message}')));
  } on Object catch (e, st) {
    debugPrint('GPX import failed: $e\n$st');
    messenger.showSnackBar(const SnackBar(content: Text('無法讀取這個檔案，請換一個 GPX 檔再試。')));
  }
}

/// True for [yes], false for [no], null when dismissed.
Future<bool?> _ask(BuildContext context, {required String title, required String message, required String yes, required String no}) => showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, no == '取消' ? null : false), child: Text(no)),
      FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(88, 44)), onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
    ],
  ),
);

/// Lets the person pick a GPX file and turns it into a new trip.
Future<void> importGpx(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  try {
    final picked = await FilePicker.pickFiles(dialogTitle: '選擇 GPX 檔案');
    if (picked.isEmpty) return;
    final text = utf8.decode(await picked.first.readAsBytes(), allowMalformed: true);
    final doc = parseGpx(text);
    final now = ref.read(clockProvider)();
    final imported = tripFromGpx(doc, today: now);

    String? mountainId;
    final peak = imported.nodes.isEmpty ? null : imported.track.isEmpty ? null : _highest(imported.track);
    if (peak != null) {
      final list = switch (ref.read(mountainsProvider).value) {
        MountainsReady(:final data) => data.mountains,
        _ => const <Mountain>[],
      };
      mountainId = nearestMountainId(list, peak.lat, peak.lng, maxKm: 3);
    }
    final id = await importGpxTrip(ref.read(tripRepositoryProvider), ref.read(itineraryRepositoryProvider), imported, mountainId: mountainId);
    messenger.showSnackBar(SnackBar(content: Text('已匯入「${imported.name}」，共 ${imported.nodes.length} 個節點')));
    router.push(Routes.trip(id));
  } on GpxFormatException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('這個檔案不是可用的 GPX：${e.message}')));
  } on Object catch (e, st) {
    debugPrint('GPX import failed: $e\n$st');
    messenger.showSnackBar(const SnackBar(content: Text('無法讀取這個檔案，請換一個 GPX 檔再試。')));
  }
}

GpxPoint? _highest(List<GpxPoint> track) {
  GpxPoint? best;
  for (final p in track) {
    if (p.ele != null && (best == null || p.ele! > best.ele!)) best = p;
  }
  return best ?? (track.isEmpty ? null : track.first);
}

/// The listed mountain closest to a point, if one is within [maxKm].
String? nearestMountainId(List<Mountain> all, double lat, double lng, {required double maxKm}) {
  String? best;
  var bestKm = maxKm;
  for (final m in all) {
    final km = _km(lat, lng, m.latitude, m.longitude);
    if (km <= bestKm) {
      bestKm = km;
      best = m.id;
    }
  }
  return best;
}

double _km(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0088;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// GPX text of a trip: nodes with coordinates as waypoints, plus the stored track.
String gpxForTrip(Trip trip, List<ItineraryItem> items) {
  final located = items.where((i) => i.lat != null && i.lng != null).toList()
    ..sort((a, b) => a.dayIndex != b.dayIndex ? a.dayIndex.compareTo(b.dayIndex) : (a.estMinutes ?? 1 << 20).compareTo(b.estMinutes ?? 1 << 20));
  final track = decodeTrack(trip.track);
  return buildGpx(
    GpxDocument(
      name: trip.name,
      waypoints: [
        for (final i in located) GpxWaypoint(name: i.name, lat: i.lat!, lng: i.lng!, ele: i.altitude > 0 ? i.altitude.toDouble() : null, description: i.note),
      ],
      tracks: track.length >= 2 ? [GpxTrack(name: trip.name, points: track)] : const [],
    ),
  );
}

/// Writes the trip as a .gpx file and opens the share sheet.
Future<void> exportGpx(BuildContext context, Trip trip, List<ItineraryItem> items) async {
  final messenger = ScaffoldMessenger.of(context);
  final located = items.any((i) => i.lat != null && i.lng != null);
  if (!located && (trip.track ?? '').isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('這個行程還沒有座標或軌跡，沒有可以匯出的路線。')));
    return;
  }
  final dir = await getTemporaryDirectory();
  final safe = trip.name.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
  final file = File('${dir.path}/${safe.isEmpty ? 'trip' : safe}.gpx');
  await file.writeAsString(gpxForTrip(trip, items));
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/gpx+xml')], subject: trip.name));
}
