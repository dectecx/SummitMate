import 'package:injectable/injectable.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/core.dart';
import '../tools/log_service.dart';

/// 行程天數跨聚合協調服務 (Infrastructure)
///
/// 實作 [IItineraryDayService]，封裝 `renameDay` / `removeDay` 涉及的
/// 跨聚合業務協調邏輯，將此職責從 Cubit 移出至 Domain Service 層。
@LazySingleton(as: IItineraryDayService)
class ItineraryDayService implements IItineraryDayService {
  static const String _source = 'ItineraryDayService';

  final IItineraryRepository _itineraryRepository;
  final ITripRepository _tripRepository;

  ItineraryDayService(this._itineraryRepository, this._tripRepository);

  @override
  Future<Result<void, Exception>> renameDay(
    String tripId,
    String oldName,
    String newName,
  ) async {
    try {
      final tripResult = await _tripRepository.getTripById(tripId);
      final trip = switch (tripResult) {
        Success(value: final t) => t,
        Failure() => null,
      };
      if (trip == null) {
        return Failure(Exception('找不到行程 ($tripId)'));
      }

      if (oldName == newName) return const Success(null);

      if (trip.dayNames.contains(newName)) {
        return Failure(Exception('名稱 "$newName" 已重複'));
      }

      final index = trip.dayNames.indexOf(oldName);
      if (index == -1) {
        return Failure(Exception('找不到天數 "$oldName"'));
      }

      // 1. 更新 Trip.dayNames
      final newDays = List<String>.from(trip.dayNames)..[index] = newName;
      final updateTripResult = await _tripRepository.updateTrip(trip.copyWith(dayNames: newDays));
      if (updateTripResult is Failure) {
        return Failure((updateTripResult as Failure).exception);
      }

      // 2. 批次更新對應的 ItineraryItem.day
      final items = (await _itineraryRepository.getByTripId(tripId)).where((i) => i.day == oldName);
      for (final item in items) {
        final updateResult = await _itineraryRepository.update(
          item.copyWith(day: newName, updatedAt: DateTime.now()),
        );
        if (updateResult is Failure) {
          LogService.error(
            'Failed to update item day for item ${item.id}: ${(updateResult as Failure).exception}',
            source: _source,
          );
        }
      }

      LogService.info('Renamed day "$oldName" -> "$newName" in trip $tripId', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('renameDay failed: $e', source: _source);
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void, Exception>> removeDay(
    String tripId,
    String name, {
    bool confirmUnlink = false,
  }) async {
    try {
      final tripResult = await _tripRepository.getTripById(tripId);
      final trip = switch (tripResult) {
        Success(value: final t) => t,
        Failure() => null,
      };
      if (trip == null) {
        return Failure(Exception('找不到行程 ($tripId)'));
      }

      // 1. 確認無行程節點
      final hasItems = (await _itineraryRepository.getByTripId(tripId)).any((i) => i.day == name);
      if (hasItems) {
        return Failure(Exception('無法刪除 "$name"，請先清空該天行程'));
      }

      // 2. 檢查是否綁定糧食計畫天數
      final mealDaysResult = await _tripRepository.getMealPlanDays(tripId);
      if (mealDaysResult is Success<List<MealPlanDay>, Exception>) {
        final linkedDay = mealDaysResult.value.cast<MealPlanDay?>().firstWhere(
          (d) => d?.linkedItineraryDay == name,
          orElse: () => null,
        );

        if (linkedDay != null && !confirmUnlink) {
          return Failure(
            MealPlanDayLinkedToItineraryException(dayName: name, mealPlanDayId: linkedDay.id),
          );
        }

        if (linkedDay != null && confirmUnlink) {
          await _tripRepository.updateMealPlanDay(
            tripId,
            linkedDay.id,
            linkedDay.name,
            linkedItineraryDay: null,
          );
        }
      }

      // 3. 從 Trip.dayNames 移除天數
      final newDays = List<String>.from(trip.dayNames)..remove(name);
      final updateResult = await _tripRepository.updateTrip(trip.copyWith(dayNames: newDays));
      if (updateResult is Failure) {
        return Failure((updateResult as Failure).exception);
      }

      LogService.info('Removed day "$name" from trip $tripId', source: _source);
      return const Success(null);
    } catch (e) {
      LogService.error('removeDay failed: $e', source: _source);
      return Failure(Exception(e.toString()));
    }
  }
}
