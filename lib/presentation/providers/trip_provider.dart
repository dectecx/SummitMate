import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/di.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../../services/log_service.dart';
import '../../services/trip_cloud_service.dart';
import '../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../data/repositories/interfaces/i_gear_repository.dart';

/// 行程 (Trip) 狀態管理
/// 負責管理多個不同的登山計畫
class TripProvider extends ChangeNotifier {
  static const String _source = 'TripProvider';

  final ITripRepository _repository;
  final Uuid _uuid = const Uuid();

  List<Trip> _trips = [];
  Trip? _activeTrip;
  bool _isLoading = true;
  String? _error;

  TripProvider({ITripRepository? repository}) : _repository = repository ?? getIt<ITripRepository>() {
    _loadTrips();
  }

  // Getters
  List<Trip> get trips => _trips;
  Trip? get activeTrip => _activeTrip;
  String? get activeTripId => _activeTrip?.id;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTrips => _trips.isNotEmpty;

  /// 載入所有行程
  Future<void> _loadTrips() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _trips = _repository.getAllTrips();
      // 按建立時間降冪排序，最新的在前
      _trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 找出當前啟用的行程
      _activeTrip = _repository.getActiveTrip();

      // 若有行程但無 active，則預設選第一個；若無行程則 active 為 null
      if (_activeTrip == null && _trips.isNotEmpty) {
        _setActiveTrip(_trips.first.id);
      }

      _isLoading = false;
      LogService.info('載入 ${_trips.length} 個行程', source: _source);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      LogService.error('載入行程失敗: $e', source: _source);
      notifyListeners();
    }
  }

  /// 建立預設行程
  Future<void> createDefaultTrip() async {
    final defaultTrip = Trip(
      id: _uuid.v4(),
      name: '我的登山行程',
      startDate: DateTime.now(),
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _repository.addTrip(defaultTrip);
    _trips = [defaultTrip];
    _activeTrip = defaultTrip;
    LogService.info('建立預設行程: ${defaultTrip.name}', source: _source);
    notifyListeners();
  }

  /// 新增行程
  Future<void> addTrip({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? coverImage,
    bool setAsActive = true,
  }) async {
    try {
      final trip = Trip(
        id: _uuid.v4(),
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        coverImage: coverImage,
        isActive: false,
        createdAt: DateTime.now(),
      );

      await _repository.addTrip(trip);
      LogService.info('新增行程: ${trip.name}', source: _source);

      if (setAsActive) {
        await setActiveTrip(trip.id);
      } else {
        _loadTrips();
      }
    } catch (e) {
      _error = e.toString();
      LogService.error('新增行程失敗: $e', source: _source);
      notifyListeners();
    }
  }

  /// 匯入行程 (保持原有 ID)
  Future<void> importTrip(Trip trip) async {
    try {
      await _repository.addTrip(trip);
      LogService.info('匯入行程: ${trip.name} (${trip.id})', source: _source);
      // 不要自動設為 Active，由 caller 決定
      await _loadTrips();
    } catch (e) {
      _error = e.toString();
      LogService.error('匯入行程失敗: $e', source: _source);
      notifyListeners();
      rethrow; // 讓 caller 處理錯誤
    }
  }

  /// 更新行程
  Future<void> updateTrip(Trip trip) async {
    try {
      await _repository.updateTrip(trip);
      LogService.info('更新行程: ${trip.name}', source: _source);
      _loadTrips();
    } catch (e) {
      _error = e.toString();
      LogService.error('更新行程失敗: $e', source: _source);
      notifyListeners();
    }
  }

  /// 完整上傳行程到雲端 (包含行程表與裝備)
  Future<bool> uploadFullTrip(Trip trip) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. 蒐集資料
      final itineraryRepo = getIt<IItineraryRepository>();
      final gearRepo = getIt<IGearRepository>();

      // Note: Repository 目前沒有針對 Trip ID 的 filter API，因此先取全部再 Filter
      // 若資料量大需優化 Repository 介面
      final allItineraries = itineraryRepo.getAllItems();
      final allGear = gearRepo.getAllItems();

      final tripItineraries = allItineraries.where((i) => i.tripId == trip.id).toList();
      final tripGear = allGear.where((g) => g.tripId == trip.id).toList();

      // 2. 呼叫雲端服務
      final cloudService = TripCloudService();
      final result = await cloudService.uploadFullTrip(
        trip: trip,
        itineraryItems: tripItineraries,
        gearItems: tripGear,
      );

      _isLoading = false;
      notifyListeners();

      if (result.isSuccess) {
        LogService.info('上傳行程成功: ${trip.name}', source: _source);
        return true;
      } else {
        _error = result.errorMessage;
        LogService.error('上傳行程失敗: ${result.errorMessage}', source: _source);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      LogService.error('上傳行程例外: $e', source: _source);
      notifyListeners();
      return false;
    }
  }

  /// 刪除行程
  Future<bool> deleteTrip(String tripId) async {
    try {
      // 如果刪除的是當前行程，先嘗試切換到其他行程
      if (_activeTrip?.id == tripId) {
        final otherTrips = _trips.where((t) => t.id != tripId);
        if (otherTrips.isNotEmpty) {
          await setActiveTrip(otherTrips.first.id);
        } else {
          _activeTrip = null; // 變為無 Active 狀態
        }
      }

      await _repository.deleteTrip(tripId);
      LogService.info('刪除行程: $tripId', source: _source);
      _loadTrips();
      return true;
    } catch (e) {
      _error = e.toString();
      LogService.error('刪除行程失敗: $e', source: _source);
      notifyListeners();
      return false;
    }
  }

  /// 設定當前啟用的行程
  Future<void> setActiveTrip(String tripId) async {
    try {
      await _repository.setActiveTrip(tripId);
      _activeTrip = _repository.getTripById(tripId);
      LogService.info('切換到行程: ${_activeTrip?.name}', source: _source);
      _loadTrips();
    } catch (e) {
      _error = e.toString();
      LogService.error('切換行程失敗: $e', source: _source);
      notifyListeners();
    }
  }

  void _setActiveTrip(String tripId) {
    _repository.setActiveTrip(tripId);
    _activeTrip = _repository.getTripById(tripId);
  }

  /// 根據 ID 取得行程
  Trip? getTripById(String id) {
    return _repository.getTripById(id);
  }

  /// 重新載入
  void reload() {
    _loadTrips();
  }

  /// 重設 Provider 狀態 (登出時使用，不清除 Hive 資料)
  void reset() {
    _trips = [];
    _activeTrip = null;
    _isLoading = false;
    _error = null;
    LogService.info('TripProvider 已重設', source: _source);
    notifyListeners();
  }
}
