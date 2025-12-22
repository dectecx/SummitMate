import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../data/models/itinerary_item.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../../services/log_service.dart';
import '../../services/toast_service.dart';
import '../../services/sync_service.dart';

/// 行程狀態管理
class ItineraryProvider extends ChangeNotifier {
  final ItineraryRepository _repository;

  List<ItineraryItem> _items = [];
  String _selectedDay = ItineraryDay.d1; // 預設顯示 D1
  bool _isLoading = true;
  bool _isEditMode = false;
  String? _error;

  ItineraryProvider() : _repository = getIt<ItineraryRepository>() {
    LogService.info('ItineraryProvider 初始化', source: 'Itinerary');
    _loadItems();
  }

  /// 所有行程節點
  List<ItineraryItem> get allItems => _items;

  /// 當前選擇天數的行程節點 (依時間排序)
  List<ItineraryItem> get currentDayItems {
    final list = _items.where((item) => item.day == _selectedDay).toList();
    list.sort((a, b) => a.estTime.compareTo(b.estTime));
    return list;
  }

  /// 當前選擇的天數
  String get selectedDay => _selectedDay;

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 是否為編輯模式
  bool get isEditMode => _isEditMode;

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

  /// 切換編輯模式
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
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

  /// 新增行程
  Future<void> addItem({
    required String day,
    required String name,
    required String estTime,
    required int altitude,
    required double distance,
    String note = '',
  }) async {
    try {
      final newItem = ItineraryItem(
        day: day,
        name: name,
        estTime: estTime,
        altitude: altitude,
        distance: distance,
        note: note,
      );

      LogService.info('新增行程: $name ($day)', source: 'Itinerary');
      await _repository.addItem(newItem);
      _loadItems();
    } catch (e) {
      LogService.error('新增行程失敗: $e', source: 'Itinerary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新行程
  Future<void> updateItem(dynamic key, ItineraryItem updatedItem) async {
    try {
      LogService.info('更新行程: ${updatedItem.name}', source: 'Itinerary');
      // 保留原有的 key (Hive Box 使用 key 作為索引)
      // 若 key 是 int, put(key, val)
      await _repository.updateItem(key, updatedItem);
      _loadItems();
    } catch (e) {
      LogService.error('更新行程失敗: $e', source: 'Itinerary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 刪除行程
  Future<void> deleteItem(dynamic key) async {
    try {
      final item = _items.firstWhere((i) => i.key == key);
      LogService.info('刪除行程: ${item.name}', source: 'Itinerary');
      await _repository.deleteItem(key);
      _loadItems();
    } catch (e) {
      LogService.error('刪除行程失敗: $e', source: 'Itinerary');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 檢查行程衝突 (回傳 true 表示本地與雲端不同)
  Future<bool> checkConflict() async {
    try {
      final syncService = getIt<SyncService>();
      return await syncService.checkItineraryConflict();
    } catch (e) {
      LogService.error('檢查衝突失敗: $e', source: 'Itinerary');
      return false; // 預設無衝突或無法檢查
    }
  }

  /// 同步行程 (自動或手動)
  Future<void> sync({bool isAuto = false}) async {
    try {
      // 若為手動同步，顯示載入中
      if (!isAuto) {
        _isLoading = true;
        notifyListeners();
      }

      LogService.info('開始同步行程...', source: 'Itinerary');

      final syncService = getIt<SyncService>();
      final result = await syncService.syncItinerary(isAuto: isAuto);

      if (result.success) {
        if (result.itinerarySynced) {
          LogService.info('行程與雲端同步完成', source: 'Itinerary');
          if (!isAuto) ToastService.success('行程同步成功');
          _loadItems(); // 重新載入本地資料庫的新資料
        } else {
          // 被節流或無需更新
          LogService.debug('行程同步跳過 (節流或無需更新)', source: 'Itinerary');
        }
      } else {
        LogService.error('行程同步失敗: ${result.errors.join(", ")}', source: 'Itinerary');
        ToastService.error(result.errors.join('\n'));
      }
    } catch (e) {
      LogService.error('行程同步異常: $e', source: 'Itinerary');
      ToastService.error('同步異常: $e');
    } finally {
      if (!isAuto) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 上傳行程 (覆寫雲端)
  Future<void> uploadToCloud() async {
    try {
      _isLoading = true;
      notifyListeners();

      final syncService = getIt<SyncService>();
      final result = await syncService.uploadItinerary();

      if (result.success) {
        LogService.info('行程上傳成功', source: 'Itinerary');
        ToastService.success('行程上傳成功');
      } else {
        LogService.error('行程上傳失敗: ${result.errorMessage}', source: 'Itinerary');
        ToastService.error('上傳失敗: ${result.errorMessage}');
      }
    } catch (e) {
      LogService.error('行程上傳異常: $e', source: 'Itinerary');
      ToastService.error('上傳異常: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
