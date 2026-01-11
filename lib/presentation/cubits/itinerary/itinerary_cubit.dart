import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di.dart';
import '../../../data/models/itinerary_item.dart';
import '../../../data/repositories/interfaces/i_itinerary_repository.dart';
import '../../../data/repositories/interfaces/i_trip_repository.dart';
import '../../../domain/interfaces/i_sync_service.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import 'itinerary_state.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final IItineraryRepository _repository;
  final ITripRepository _tripRepository;
  // final ISyncService _syncService;
  // final IConnectivityService _connectivityService;

  static const String _source = 'ItineraryCubit';

  ItineraryCubit({
    IItineraryRepository? repository,
    ITripRepository? tripRepository,
    ISyncService? syncService,
    IConnectivityService? connectivityService,
  }) : _repository = repository ?? getIt<IItineraryRepository>(),
       _tripRepository = tripRepository ?? getIt<ITripRepository>(),
       // _syncService = syncService ?? getIt<ISyncService>(),
       // _connectivityService = connectivityService ?? getIt<IConnectivityService>(),
       super(const ItineraryInitial());

  String? get _currentTripId => _tripRepository.getActiveTrip()?.id;

  /// 載入當前行程的項目
  Future<void> loadItinerary() async {
    try {
      if (state is! ItineraryLoaded) {
        emit(const ItineraryLoading());
      }

      final currentTripId = _currentTripId;
      if (currentTripId == null) {
        // 無活動行程，顯示空狀態
        emit(const ItineraryLoaded(items: []));
        return;
      }

      final allItems = _repository.getAllItems();
      final tripItems = allItems.where((item) => item.tripId == currentTripId).toList();

      // 若為重新載入，保留當前選擇的狀態
      String selectedDay = 'D1';
      bool isEditMode = false;
      if (state is ItineraryLoaded) {
        selectedDay = (state as ItineraryLoaded).selectedDay;
        isEditMode = (state as ItineraryLoaded).isEditMode;
      }

      emit(ItineraryLoaded(items: tripItems, selectedDay: selectedDay, isEditMode: isEditMode));

      LogService.debug('Loaded ${tripItems.length} itinerary items', source: _source);
    } catch (e) {
      LogService.error('Failed to load itinerary: $e', source: _source);
      emit(ItineraryError(e.toString()));
    }
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
      await _repository.checkIn(key, checkInTime);
      LogService.info('Check-in: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Check-in failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
      // 錯誤後重新載入以確保狀態一致
      loadItinerary();
    }
  }

  /// 清除簽到
  ///
  /// [key] 行程節點 Key
  Future<void> clearCheckIn(dynamic key) async {
    try {
      await _repository.clearCheckIn(key);
      LogService.info('Clear check-in: $key', source: _source);
      loadItinerary();
    } catch (e) {
      LogService.error('Clear check-in failed: $e', source: _source);
      emit(ItineraryError(e.toString()));
      loadItinerary();
    }
  }

  /// 新增項目
  ///
  /// [item] 行程節點物件
  Future<void> addItem(ItineraryItem item) async {
    try {
      // 確保 tripId 正確填充 (若未指定則使用當前活動 tripId)
      var itemToAdd = item;
      if (item.tripId.isEmpty && _currentTripId != null) {
        itemToAdd = ItineraryItem(
          uuid: item.uuid,
          tripId: _currentTripId!,
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

      await _repository.addItem(itemToAdd);
      LogService.info('Added item: ${item.name}', source: _source);
      loadItinerary();
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
      await _repository.updateItem(key, item);
      LogService.info('Updated item: ${item.name}', source: _source);
      loadItinerary();
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
      await _repository.deleteItem(key);
      LogService.info('Deleted item: $key', source: _source);
      loadItinerary();
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
