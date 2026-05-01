import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/core.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import 'itinerary_state.dart';

@injectable
class ItineraryCubit extends Cubit<ItineraryState> {
  final IItineraryRepository _repository;
  final ITripRepository _tripRepository;
  final IAuthService _authService;
  static const String _source = 'ItineraryCubit';

  ItineraryCubit(this._repository, this._tripRepository, this._authService) : super(const ItineraryInitial());

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
        emit(const ItineraryLoaded(items: []));
        return;
      }

      final tripItems = _repository.getByTripId(currentTripId);

      final tripResult = await _tripRepository.getTripById(currentTripId);
      final activeTrip = switch (tripResult) {
        Success(value: final t) => t,
        Failure() => null,
      };

      // 初始化天數列表
      List<String> dayNames = activeTrip?.dayNames ?? [];

      if (dayNames.isEmpty && activeTrip != null) {
        final daysCount = activeTrip.durationDays > 0 ? activeTrip.durationDays : 1;
        dayNames = List.generate(daysCount, (index) => 'D${index + 1}');

        activeTrip.dayNames = dayNames;
        final updateResult = await _tripRepository.updateTrip(activeTrip);
        if (updateResult is Failure) {
          LogService.error('Failed to update trip dayNames: ${updateResult.exception}', source: _source);
        }
      } else if (dayNames.isEmpty) {
        dayNames = ['D1'];
      }

      String selectedDay = 'D1';
      if (!dayNames.contains(selectedDay)) {
        selectedDay = dayNames.isNotEmpty ? dayNames.first : 'D1';
      }

      bool isEditMode = false;
      if (state is ItineraryLoaded) {
        final loaded = state as ItineraryLoaded;
        selectedDay = loaded.selectedDay;
        if (!dayNames.contains(selectedDay)) {
          selectedDay = dayNames.isNotEmpty ? dayNames.first : 'D1';
        }
        isEditMode = loaded.isEditMode;
      }

      emit(ItineraryLoaded(items: tripItems, selectedDay: selectedDay, isEditMode: isEditMode, dayNames: dayNames));

      LogService.debug('Loaded ${tripItems.length} items for ${dayNames.length} days', source: _source);
    } catch (e) {
      LogService.error('Failed to load itinerary: $e', source: _source);
      emit(ItineraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 新增天數
  Future<void> addDay(String name) async {
    final tripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final trip = tripResult is Success ? (tripResult as Success).value : null;

    if (trip == null) return;

    if (trip.dayNames.contains(name)) {
      emit(ItineraryError('天數名稱 "$name" 已存在'));
      await loadItinerary();
      return;
    }

    trip.dayNames = List<String>.from(trip.dayNames)..add(name);
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
    final tripItems = _repository.getByTripId(trip.id).where((i) => i.day == oldName);
    for (var item in tripItems) {
      final updatedItem = item.copyWith(day: newName, updatedAt: DateTime.now());
      await _repository.update(updatedItem);
    }

    if (state is ItineraryLoaded && (state as ItineraryLoaded).selectedDay == oldName) {
      selectDay(newName);
    }

    await loadItinerary();
  }

  /// 移除天數
  Future<void> removeDay(String name) async {
    final tripResult = await _tripRepository.getActiveTrip(_authService.currentUserId ?? 'guest');
    final trip = tripResult is Success ? (tripResult as Success).value : null;
    if (trip == null) return;

    final hasItems = _repository.getByTripId(trip.id).any((i) => i.day == name);
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

  /// 簽到邏輯 (切換狀態)
  Future<void> checkIn(String id) async {
    try {
      final result = await _repository.toggleCheckIn(id);
      if (result is Failure) throw result.exception;
      LogService.info('Toggle check-in: $id', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Toggle check-in failed: $e', source: _source);
      emit(ItineraryError(AppErrorHandler.getUserMessage(e)));
      await loadItinerary();
    }
  }

  /// 指定時間簽到
  Future<void> checkInWithTime(String id, DateTime time) async {
    try {
      final item = _repository.getById(id);
      if (item == null) return;

      final updatedItem = item.copyWith(
        isCheckedIn: true,
        checkedInAt: time,
        actualTime: time,
        updatedAt: DateTime.now(),
        updatedBy: _authService.currentUserId ?? 'guest',
      );

      final result = await _repository.update(updatedItem);
      if (result is Failure) throw result.exception;
      LogService.info('Check-in with time: $id at $time', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Check-in with time failed: $e', source: _source);
      emit(ItineraryError(AppErrorHandler.getUserMessage(e)));
      await loadItinerary();
    }
  }

  /// 新增項目
  Future<void> addItem(ItineraryItem item) async {
    try {
      var itemToAdd = item;
      final currentTripId = await _getCurrentTripId();
      if (item.tripId.isEmpty && currentTripId != null) {
        itemToAdd = item.copyWith(tripId: currentTripId);
      }

      final userId = _authService.currentUserId;
      if (userId != null) {
        itemToAdd = itemToAdd.copyWith(
          createdBy: itemToAdd.createdBy ?? userId,
          updatedBy: userId,
          createdAt: itemToAdd.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final result = await _repository.add(itemToAdd);
      if (result is Failure) throw result.exception;
      LogService.info('Added item: ${item.name}', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Add item failed: $e', source: _source);
      emit(ItineraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 更新項目
  Future<void> updateItem(ItineraryItem item) async {
    try {
      final userId = _authService.currentUserId;
      final itemToUpdate = userId != null
          ? item.copyWith(updatedBy: userId, updatedAt: DateTime.now())
          : item.copyWith(updatedAt: DateTime.now());

      final result = await _repository.update(itemToUpdate);
      if (result is Failure) throw result.exception;
      LogService.info('Updated item: ${item.name}', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Update item failed: $e', source: _source);
      emit(ItineraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 刪除項目
  Future<void> deleteItem(String id) async {
    try {
      final result = await _repository.delete(id);
      if (result is Failure) throw result.exception;
      LogService.info('Deleted item: $id', source: _source);
      await loadItinerary();
    } catch (e) {
      LogService.error('Delete item failed: $e', source: _source);
      emit(ItineraryError(AppErrorHandler.getUserMessage(e)));
    }
  }

  /// 重置狀態
  void reset() {
    emit(const ItineraryInitial());
  }
}
