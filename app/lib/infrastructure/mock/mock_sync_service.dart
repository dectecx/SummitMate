import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import '../../core/error/result.dart';
import '../../core/models/paginated_list.dart';
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
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({
    int? page,
    int? limit,
  }) async {
    return Success(PaginatedList(items: [], page: page ?? 1, total: 0, hasMore: false));
  }

  @override
  void resetLastSyncTimes() {
    _lastItinerarySyncTime = null;
    _lastMessagesSyncTime = null;
  }
}
