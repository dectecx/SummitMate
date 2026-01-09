import 'package:hive/hive.dart';
import '../../core/di.dart';
import '../models/itinerary_item.dart';
import 'interfaces/i_itinerary_repository.dart';
import '../datasources/interfaces/i_itinerary_local_data_source.dart';
import '../datasources/interfaces/i_itinerary_remote_data_source.dart';
import '../../services/interfaces/i_connectivity_service.dart';
import '../../services/log_service.dart';

/// Itinerary Repository
/// Coordinates Local and Remote Data Sources
class ItineraryRepository implements IItineraryRepository {
  static const String _source = 'ItineraryRepository';

  final IItineraryLocalDataSource _localDataSource;
  final IItineraryRemoteDataSource _remoteDataSource;
  final IConnectivityService _connectivity;

  ItineraryRepository({
    IItineraryLocalDataSource? localDataSource,
    IItineraryRemoteDataSource? remoteDataSource,
    IConnectivityService? connectivity,
  }) : _localDataSource = localDataSource ?? getIt<IItineraryLocalDataSource>(),
       _remoteDataSource = remoteDataSource ?? getIt<IItineraryRemoteDataSource>(),
       _connectivity = connectivity ?? getIt<IConnectivityService>();

  @override
  Future<void> init() async {
    // Repository init mainly ensures LocalDS is ready
    await _localDataSource.init();
  }

  // Delegate Local Operations

  @override
  List<ItineraryItem> getAllItems() {
    return _localDataSource.getAll();
  }

  @override
  List<ItineraryItem> getItemsByDay(String day) {
    return _localDataSource.getAll().where((item) => item.day == day).toList();
  }

  @override
  ItineraryItem? getItemByKey(dynamic key) {
    return _localDataSource.getByKey(key);
  }

  @override
  Future<void> checkIn(dynamic key, DateTime time) async {
    final item = _localDataSource.getByKey(key);
    if (item == null) return;
    item.actualTime = time;
    await _localDataSource.update(key, item);
  }

  @override
  Future<void> clearCheckIn(dynamic key) async {
    final item = _localDataSource.getByKey(key);
    if (item == null) return;
    item.actualTime = null;
    await _localDataSource.update(key, item);
  }

  @override
  Future<void> resetAllCheckIns() async {
    for (final item in _localDataSource.getAll()) {
      item.actualTime = null;
      await _localDataSource.update('${item.day}_${item.name}', item);
    }
  }

  @override
  Future<void> addItem(ItineraryItem item) async {
    await _localDataSource.add(item);
  }

  @override
  Future<void> updateItem(dynamic key, ItineraryItem item) async {
    await _localDataSource.update(key, item);
  }

  @override
  Future<void> deleteItem(dynamic key) async {
    await _localDataSource.delete(key);
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    await _localDataSource.saveLastSyncTime(time);
  }

  @override
  DateTime? getLastSyncTime() {
    return _localDataSource.getLastSyncTime();
  }

  @override
  Stream<BoxEvent> watchAllItems() {
    return _localDataSource.watch();
  }

  /// Sync Implementation
  /// Fetches from Remote, Preserves Local State (actualTime), Updates Local
  @override
  Future<void> sync(String tripId) async {
    if (_connectivity.isOffline) {
      LogService.warning('Offline mode, skipping itinerary sync', source: _source);
      return;
    }

    try {
      LogService.info('Syncing itinerary for trip: $tripId', source: _source);
      final cloudItems = await _remoteDataSource.getItinerary(tripId);

      // Preservation Logic (Business Logic)
      final existing = _localDataSource.getAll();
      final actualTimeMap = <String, DateTime?>{};
      for (final item in existing) {
        final key = '${item.day}_${item.name}';
        actualTimeMap[key] = item.actualTime;
      }

      await _localDataSource.clear();

      for (final item in cloudItems) {
        final key = '${item.day}_${item.name}';
        item.actualTime = actualTimeMap[key];
        await _localDataSource.add(item);
      }

      await saveLastSyncTime(DateTime.now());
      LogService.info('Sync itinerary complete', source: _source);
    } catch (e) {
      LogService.error('Sync itinerary failed: $e', source: _source);
      rethrow;
    }
  }

  // Deprecated/Legacy method support (if needed for temporary) or Remove?
  // IItineraryRepository definition needs update first.
  @override
  Future<void> syncFromCloud(List<ItineraryItem> cloudItems) async {
    // Legacy support: logic moved to sync() but if called directly with items:
    // Perform same preservation logic
    final existing = _localDataSource.getAll();
    final actualTimeMap = <String, DateTime?>{};
    for (final item in existing) {
      final key = '${item.day}_${item.name}';
      actualTimeMap[key] = item.actualTime;
    }

    await _localDataSource.clear();

    for (final item in cloudItems) {
      final key = '${item.day}_${item.name}';
      item.actualTime = actualTimeMap[key];
      await _localDataSource.add(item);
    }
  }
}
