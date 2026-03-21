import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import '../../core/error/result.dart';
import '../../data/models/trip.dart';

/// Mock 同步服務
/// 用於測試和離線模式
class MockSyncService implements ISyncService {
  DateTime? _lastItinerarySyncTime;
  DateTime? _lastMessagesSyncTime;

  @override
  DateTime? get lastItinerarySync => _lastItinerarySyncTime;

  @override
  DateTime? get lastMessagesSync => _lastMessagesSyncTime;

  @override
  Future<SyncResult> syncAll({bool isAuto = false}) async {
    _lastItinerarySyncTime = DateTime.now();
    _lastMessagesSyncTime = DateTime.now();
    return SyncResult.success();
  }

  @override
  Future<Result<List<Trip>, Exception>> getCloudTrips() async {
    return const Success([]);
  }

  @override
  void resetLastSyncTimes() {
    _lastItinerarySyncTime = null;
    _lastMessagesSyncTime = null;
  }
}
