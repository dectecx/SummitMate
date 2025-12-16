import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../../services/log_service.dart';

/// 行程狀態管理
class ItineraryProvider extends ChangeNotifier {
  final ItineraryRepository _repository;

  List<ItineraryItem> _items = [];
  String _selectedDay = ItineraryDay.d1; // 預設顯示 D1
  bool _isLoading = true;
  String? _error;

  ItineraryProvider() : _repository = getIt<ItineraryRepository>() {
    LogService.info('ItineraryProvider 初始化', source: 'Itinerary');
    _loadItems();
  }

  /// 所有行程節點
  List<ItineraryItem> get allItems => _items;

  /// 當前選擇天數的行程節點
  List<ItineraryItem> get currentDayItems =>
      _items.where((item) => item.day == _selectedDay).toList();

  /// 當前選擇的天數
  String get selectedDay => _selectedDay;

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 錯誤訊息
  String? get error => _error;

  /// 完成進度 (已打卡數 / 總數)
  double get progress {
    if (_items.isEmpty) return 0;
    final checked = _items.where((item) => item.isCheckedIn).length;
    return checked / _items.length;
  }

  /// 當前目標 (下一個未打卡節點)
  ItineraryItem? get currentTarget {
    try {
      return currentDayItems.firstWhere((item) => !item.isCheckedIn);
    } catch (e) {
      return null;
    }
  }

  /// 載入行程
  void _loadItems() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _items = _repository.getAllItems();
      LogService.debug('載入 ${_items.length} 個行程節點', source: 'Itinerary');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LogService.error('載入行程失敗: $e', source: 'Itinerary');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切換顯示天數
  void selectDay(String day) {
    if (ItineraryDay.all.contains(day)) {
      _selectedDay = day;
      LogService.debug('切換到 $day', source: 'Itinerary');
      notifyListeners();
    }
  }

  /// 打卡 - 使用當前時間
  Future<void> checkInNow(dynamic key) async {
    await checkIn(key, DateTime.now());
  }

  /// 打卡 - 指定時間
  Future<void> checkIn(dynamic key, DateTime time) async {
    try {
      final item = _items.firstWhere((i) => i.key == key);
      LogService.info('打卡: ${item.name} @ ${time.hour}:${time.minute}', source: 'Itinerary');
      await _repository.checkIn(key, time);
      _loadItems();
    } catch (e) {
      LogService.error('打卡失敗: $e', source: 'Itinerary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 清除打卡
  Future<void> clearCheckIn(dynamic key) async {
    try {
      final item = _items.firstWhere((i) => i.key == key);
      LogService.info('清除打卡: ${item.name}', source: 'Itinerary');
      await _repository.clearCheckIn(key);
      _loadItems();
    } catch (e) {
      LogService.error('清除打卡失敗: $e', source: 'Itinerary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 重置所有打卡
  Future<void> resetAllCheckIns() async {
    try {
      LogService.warning('重置所有打卡', source: 'Itinerary');
      await _repository.resetAllCheckIns();
      _loadItems();
    } catch (e) {
      LogService.error('重置打卡失敗: $e', source: 'Itinerary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 同步行程後重新載入
  void reload() {
    LogService.debug('行程重新載入', source: 'Itinerary');
    _loadItems();
  }
}

