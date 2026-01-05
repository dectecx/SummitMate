import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import '../../services/log_service.dart';
import 'i_location_resolver.dart';

/// 鄉鎮市區地點解析器
/// 使用 assets/data/township_centers.json 進行最近鄰搜尋
class TownshipLocationResolver implements ILocationResolver {
  static const String _dataPath = 'assets/data/township_centers.json';
  List<dynamic>? _dataCache;
  final Distance _distance = const Distance();

  @override
  Future<({String id, String name})?> resolve(double lat, double lon) async {
    try {
      if (_dataCache == null) {
        await _loadData();
      }

      if (_dataCache == null || _dataCache!.isEmpty) {
        LogService.error('Township data is empty', source: 'TownshipLocationResolver');
        return null;
      }

      final target = LatLng(lat, lon);
      Map<String, dynamic>? nearest;
      double minDistance = double.infinity;

      for (var item in _dataCache!) {
        final itemLat = item['lat'] as double;
        final itemLon = item['lon'] as double;
        final point = LatLng(itemLat, itemLon);

        final dist = _distance.as(LengthUnit.Meter, target, point);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = item;
        }
      }

      if (nearest != null) {
        LogService.debug(
          'Resolved location: (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}) -> ${nearest['name']} (~${(minDistance / 1000).toStringAsFixed(1)}km)',
          source: 'TownshipLocationResolver',
        );
        return (id: nearest['id'] as String, name: nearest['name'] as String);
      }
    } catch (e) {
      LogService.error('Error resolving location: $e', source: 'TownshipLocationResolver');
    }
    return null;
  }

  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString(_dataPath);
      _dataCache = json.decode(jsonString) as List<dynamic>;
      LogService.info('Loaded ${_dataCache!.length} township centers', source: 'TownshipLocationResolver');
    } catch (e) {
      LogService.error('Failed to load township data: $e', source: 'TownshipLocationResolver');
      // 可以考慮在這裡加上重試或 fallback
    }
  }
}
