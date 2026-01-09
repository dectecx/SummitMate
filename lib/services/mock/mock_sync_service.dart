import 'package:summitmate/services/interfaces/i_sync_service.dart';
import 'package:summitmate/services/interfaces/i_data_service.dart';
import 'package:summitmate/data/models/message.dart';

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
  Future<SyncResult> syncItinerary({bool isAuto = false}) async {
    _lastItinerarySyncTime = DateTime.now();
    return SyncResult.success(itinerarySynced: true, messagesSynced: false);
  }

  @override
  Future<SyncResult> syncMessages({bool isAuto = false}) async {
    _lastMessagesSyncTime = DateTime.now();
    return SyncResult.success(itinerarySynced: false, messagesSynced: true);
  }

  @override
  Future<SyncResult> uploadPendingMessages() async {
    return SyncResult.success(itinerarySynced: false, messagesSynced: true);
  }

  @override
  Future<SyncResult> uploadItinerary() async {
    return SyncResult.success(itinerarySynced: true, messagesSynced: false);
  }

  @override
  Future<bool> checkItineraryConflict() async {
    return false;
  }

  @override
  Future<GetTripsResult> getCloudTrips() async {
    return GetTripsResult(isSuccess: true, trips: []);
  }

  @override
  Future<ApiResult> addMessageAndSync(Message message) async {
    return ApiResult(isSuccess: true);
  }

  @override
  Future<ApiResult> deleteMessageAndSync(String uuid) async {
    return ApiResult(isSuccess: true);
  }

  @override
  void resetLastSyncTimes() {
    _lastItinerarySyncTime = null;
    _lastMessagesSyncTime = null;
  }
}
