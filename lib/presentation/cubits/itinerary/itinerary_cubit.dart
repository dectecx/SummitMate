import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../core/error/result.dart';
import '../../../domain/interfaces/i_auth_service.dart';

import '../../../infrastructure/tools/log_service.dart';
import 'itinerary_state.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final IItineraryRepository _repository;
  final ITripRepository _tripRepository;
  final IAuthService _authService;
  static const String _source = 'ItineraryCubit';

  ItineraryCubit({IItineraryRepository? repository, ITripRepository? tripRepository, IAuthService? authService})
    : _repository = repository ?? getIt<IItineraryRepository>(),
      _tripRepository = tripRepository ?? getIt<ITripRepository>(),
      _authService = authService ?? getIt<IAuthService>(),
      super(const ItineraryInitial());

  Future<String?> _getCurrentTripId() async {
    final result = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    return switch (result) {
      Success(value: final trip) => trip?.id,
      Failure() => null,
    };
  }

  /// 載入當前行程的項目
  Future<void> loadItinerary() async {
    try {
      if (state is! ItineraryLoaded) {
        emit(const ItineraryLoading());
      }

      final currentTripId = await _getCurrentTripId();
      if (currentTripId == null) {
        // 無活動行程，顯示空狀態
        emit(const ItineraryLoaded(items: []));
        return;
      }

      final allItems = _repository.getAllItems();
      final tripItems = allItems.where((item) => item.tripId == currentTripId).toList();

      final tripResult = await _tripRepository.getTripById(currentTripId);
      final activeTrip = switch (tripResult) {
        Success(value: final t) => t,
        Failure() => null,
      };

      // 初始化天數列表
      List<String> dayNames = activeTrip?.dayNames ?? [];

      // 若天數為空，則根據天數自動產生預設值 (相容舊資料)
      if (dayNames.isEmpty && activeTrip != null) {
        final daysCount = activeTrip.durationDays > 0 ? activeTrip.durationDays : 1;
        dayNames = List.generate(daysCount, (index) => 'D${index + 1}');

        // 自動保存預設天數設定，確保下次一致
        activeTrip.dayNames = dayNames;
        final updateResult = await _tripRepository.updateTrip(activeTrip);
        if (updateResult is Failure) {
          LogService.error('Failed to update trip dayNames: ${updateResult.exception}', source: _source);
        }
      } else if (dayNames.isEmpty) {
        // Fallback
        dayNames = ['D1'];
      }

      // 若為重新載入，保留當前選擇的狀態
      String selectedDay = 'D1';
      // 確保 selectedDay 在有效範圍內
      if (!dayNames.contains(selectedDay)) {
        selectedDay = dayNames.isNotEmpty ? dayNames.first : 'D1';
      }

      bool isEditMode = false;
      if (state is ItineraryLoaded) {
        final loaded = state as ItineraryLoaded;
        selectedDay = loaded.selectedDay;
        // 若之前的選擇天數已不存在，切換回第一個
        if (!dayNames.contains(selectedDay)) {
          selectedDay = dayNames.isNotEmpty ? dayNames.first : 'D1';
        }
        isEditMode = loaded.isEditMode;
      }

      emit(ItineraryLoaded(items: tripItems, selectedDay: selectedDay, isEditMode: isEditMode, dayNames: dayNames));

      LogService.debug('Loaded ${tripItems.length} items for ${dayNames.length} days', source: _source);
    } catch (e) {
      LogService.error('Failed to load itinerary: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// 新增天數
  Future<void> addDay(String name) async {
    final tripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final trip = tripResult is Success ? (tripResult as Success).value : null;

    if (trip == null) return;

    if (trip.dayNames.contains(name)) {
      emit(ItineraryError('天數名稱 "$name" 已存在'));
      // 恢復原狀
      await loadItinerary();
      return;
    }

    trip.dayNames = List.from(trip.dayNames)..add(name);
    final updateResult = await _tripRepository.updateTrip(trip);
    if (updateResult is Failure) {
      emit(ItineraryError(updateResult.exception.toString()));
      return;
    }
    await loadItinerary();
  }

  /// 重新命名天數
  Future<void> renameDay(String oldName, String newName) async {
    final tripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final trip = tripResult is Success ? (tripResult as Success).value : null;
    if (trip == null) return;

    if (oldName == newName) return;
    if (trip.dayNames.contains(newName)) {
      emit(ItineraryError('名稱 "$newName" 已重複'));
      await loadItinerary();
      return;
    }

    // 1. 更新 Trip dayNames
    final index = trip.dayNames.indexOf(oldName);
    if (index == -1) return;

    final newDays = List<String>.from(trip.dayNames);
    newDays[index] = newName;
    trip.dayNames = newDays;
    await _tripRepository.updateTrip(trip);

    // 2. 批次更新 Item 的 day 欄位
    final allItems = _repository.getAllItems().where((i) => i.tripId == trip.id && i.day == oldName);
    for (var item in allItems) {
      item.day = newName;
      // 注意: updateItem 使用 key 查找，HiveObject 直接 save 亦可，但這裡用 Repo 統一介面
      final itemUpdateResult = await _repository.updateItem(item.key, item);
      if (itemUpdateResult is Failure) {
        LogService.error('Failed to update item day: ${itemUpdateResult.exception}', source: _source);
      }
    }

    // 更新 selectedDay 若剛好是該天
    if (state is ItineraryLoaded && (state as ItineraryLoaded).selectedDay == oldName) {
      selectDay(newName); // 這會 emit 新狀態，但隨後的 loadItinerary 會覆蓋
    }

    await loadItinerary();
  }

  /// 移除天數
  Future<void> removeDay(String name) async {
    final tripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final trip = tripResult is Success ? (tripResult as Success).value : null;
    if (trip == null) return;

    // 檢查是否有行程項目
    final hasItems = _repository.getAllItems().any((i) => i.tripId == trip.id && i.day == name);
    if (hasItems) {
      emit(ItineraryError('無法刪除 "$name"，請先清空該天行程'));
      await loadItinerary();
      return;
    }

    final newDays = List<String>.from(trip.dayNames)..remove(name);
    trip.dayNames = newDays;
    await _tripRepository.updateTrip(trip);
    await loadItinerary();
  }

  /// 重新排序天數
  Future<void> reorderDays(List<String> newOrder) async {
    final tripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final trip = tripResult is Success ? (tripResult as Success).value : null;
    if (trip == null) return;

    trip.dayNames = newOrder;
    final updateResult = await _tripRepository.updateTrip(trip);
    if (updateResult is Failure) {
      emit(ItineraryError(updateResult.exception.toString()));
      return;
    }
    await loadItinerary();
  }

  /// 選擇日期
  ///
  /// [day] 行程天數 (e.g., "D1")
  void selectDay(String day) {
    if (state is ItineraryLoaded) {
      emit((state as ItineraryLoaded).copyWith(selectedDay: day));
    }
  }

  /// 切換編輯模式
  void toggleEditMode() {
    if (state is ItineraryLoaded) {
      final current = state as ItineraryLoaded;
      emit(current.copyWith(isEditMode: !current.isEditMode));
    }
  }

  /// 簽到邏輯
  ///
  /// [key] 行程節點 Key
  /// [time] 簽到時間 (預設當下)
  Future<void> checkIn(dynamic key, {DateTime? time}) async {
    try {
      final checkInTime = time ?? DateTime.now();
      final result = await _repository.checkIn(key, checkInTime);
      if (result is Failure) throw result.exception;
      LogService.info('Check-in: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Check-in failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
      // 錯誤後重新載入以確保狀態一致
      await loadItinerary();
    }
  }

  /// 清除簽到
  ///
  /// [key] 行程節點 Key
  Future<void> clearCheckIn(dynamic key) async {
    try {
      final result = await _repository.clearCheckIn(key);
      if (result is Failure) throw result.exception;
      LogService.info('Clear check-in: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Clear check-in failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
      await loadItinerary();
    }
  }

  /// 新增項目
  ///
  /// [item] 行程節點物件
  Future<void> addItem(ItineraryItem item) async {
    try {
      // 確保 tripId 正確填充 (若未指定則使用當前活動 tripId)
      var itemToAdd = item;
      final currentTripId = await _getCurrentTripId();
      if (item.tripId.isEmpty && currentTripId != null) {
        itemToAdd = ItineraryItem(
          id: item.id,
          tripId: currentTripId,
          day: item.day,
          name: item.name,
          estTime: item.estTime,
          altitude: item.altitude,
          distance: item.distance,
          note: item.note,
          imageAsset: item.imageAsset,
          isCheckedIn: item.isCheckedIn,
          checkedInAt: item.checkedInAt,
        );
      }

      // Populate Audit Fields
      final userId = _authService.currentUserId;
      if (userId != null) {
        itemToAdd.createdBy ??= userId;
        itemToAdd.updatedBy = userId;
      }

      final result = await _repository.addItem(itemToAdd);
      if (result is Failure) throw result.exception;
      LogService.info('Added item: ${item.name}', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Add item failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// 更新項目
  ///
  /// [key] 目標節點 Key
  /// [item] 更新後的節點資料
  Future<void> updateItem(dynamic key, ItineraryItem item) async {
    try {
      // Populate Audit Fields
      final userId = _authService.currentUserId;
      if (userId != null) {
        item.updatedBy = userId;
      }

      final result = await _repository.updateItem(key, item);
      if (result is Failure) throw result.exception;
      LogService.info('Updated item: ${item.name}', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Update item failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// 刪除項目
  ///
  /// [key] 目標節點 Key
  Future<void> deleteItem(dynamic key) async {
    try {
      final result = await _repository.deleteItem(key);
      if (result is Failure) throw result.exception;
      LogService.info('Deleted item: $key', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Delete item failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
  }

  /// 重置狀態 (例如登出時)
  void reset() {
    emit(const ItineraryInitial());
  }
}
