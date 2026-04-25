import 'package:injectable/injectable.dart';
import '../../core/models/paginated_list.dart';
import '../../core/offline_config.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../data/repositories/interfaces/i_message_repository.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_connectivity_service.dart';
import '../../domain/interfaces/i_sync_service.dart';
import '../../domain/interfaces/i_auth_service.dart';
import '../../core/error/result.dart';

/// 同步服務
/// 管理本地資料與雲端資料的雙向同步
@LazySingleton(as: ISyncService)
class SyncService implements ISyncService {
  final ITripRepository _tripRepo;
  final IItineraryRepository _itineraryRepo;
  final IMessageRepository _messageRepo;
  final IConnectivityService _connectivity;
  final IAuthService _authService;

  SyncService({
    required ITripRepository tripRepo,
    required IItineraryRepository itineraryRepo,
    required IMessageRepository messageRepo,
    required IConnectivityService connectivity,
    required IAuthService authService,
  }) : _tripRepo = tripRepo,
       _itineraryRepo = itineraryRepo,
       _messageRepo = messageRepo,
       _connectivity = connectivity,
       _authService = authService;

  bool get _isOffline => _connectivity.isOffline;

  /// 取得當前活動行程 ID
  Future<String?> get _activeTripId async {
    final result = await _tripRepo.getActiveTrip(_authService.currentUserId ?? 'guest');
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  /// 上次同步行程的時間 (這裡改為內部管理或交由 Repository 存取)
  DateTime? _lastItinerarySyncTime;

  /// 上次同步留言的時間
  DateTime? _lastMessagesSyncTime;

  @override
  DateTime? get lastItinerarySync => _lastItinerarySyncTime;
  @override
  DateTime? get lastMessagesSync => _lastMessagesSyncTime;

  /// 完整同步 (下載 + 上傳)
  @override
  Future<SyncResult> syncAll({bool isAuto = false}) async {
    if (_isOffline) {
      return SyncResult.failure('目前為離線模式，無法同步');
    }

    final now = DateTime.now();

    // 檢查冷卻時間
    final itinNeeded =
        !isAuto ||
        (_lastItinerarySyncTime == null ||
            now.difference(_lastItinerarySyncTime!) > OfflineConfig.syncThrottleDuration);
    final msgNeeded =
        !isAuto ||
        (_lastMessagesSyncTime == null || now.difference(_lastMessagesSyncTime!) > OfflineConfig.syncThrottleDuration);

    if (!itinNeeded && !msgNeeded) {
      LogService.info('Auto-sync throttled (All cool)', source: 'SyncService');
      return SyncResult.skipped(reason: '同步節流中');
    }

    final tripId = await _activeTripId;
    if (tripId == null) {
      return SyncResult.failure('找不到活動行程');
    }

    LogService.info('SyncAll: Fetching Itinerary and Messages for trip: $tripId', source: 'SyncService');

    var itinSuccess = false;
    var msgSuccess = false;
    final errors = <String>[];

    // 處理行程
    if (itinNeeded) {
      try {
        final result = await _itineraryRepo.sync(tripId);
        if (result is Success) {
          _lastItinerarySyncTime = DateTime.now();
          itinSuccess = true;
        } else {
          errors.add('行程同步失敗');
        }
      } catch (e) {
        errors.add('行程同步異常: $e');
      }
    }

    // 處理留言
    if (msgNeeded) {
      try {
        final result = await _messageRepo.getRemoteMessages(tripId);
        if (result is Success) {
          _lastMessagesSyncTime = DateTime.now();
          msgSuccess = true;
        } else {
          errors.add('留言同步失敗');
        }
      } catch (e) {
        errors.add('留言同步異常: $e');
      }
    }

    return SyncResult(
      isSuccess: errors.isEmpty,
      itinerarySynced: itinSuccess,
      messagesSynced: msgSuccess,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  @override
  Future<Result<PaginatedList<Trip>, Exception>> getCloudTrips({int? page, int? limit}) async {
    if (_isOffline) {
      return Failure(Exception('離線模式無法取得行程列表'));
    }
    try {
      return await _tripRepo.getRemoteTrips(page: page, limit: limit);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  void resetLastSyncTimes() {
    _lastItinerarySyncTime = null;
    _lastMessagesSyncTime = null;
  }
}
