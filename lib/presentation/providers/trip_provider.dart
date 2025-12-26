import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/di.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../../services/log_service.dart';

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
  void _loadTrips() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _trips = _repository.getAllTrips();
      // 按建立時間降冪排序，最新的在前
      _trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 找出當前啟用的行程
      _activeTrip = _repository.getActiveTrip();

      // 如果沒有行程，建立預設行程
      if (_trips.isEmpty) {
        _createDefaultTrip();
      } else if (_activeTrip == null && _trips.isNotEmpty) {
        // 如果沒有啟用的行程，啟用第一個
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
  Future<void> _createDefaultTrip() async {
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

  /// 刪除行程
  Future<bool> deleteTrip(String tripId) async {
    try {
      // 不能刪除唯一的行程
      if (_trips.length <= 1) {
        LogService.warning('無法刪除唯一的行程', source: _source);
        return false;
      }

      // 如果刪除的是當前行程，先切換到其他行程
      if (_activeTrip?.id == tripId) {
        final otherTrip = _trips.firstWhere((t) => t.id != tripId);
        await setActiveTrip(otherTrip.id);
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
}
