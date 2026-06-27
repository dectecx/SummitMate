import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/domain/repositories/i_trip_repository.dart';

/// 為持有 Trip 關聯資料的 Cubit 提供統一的「標記行程待更新」輔助方法。
///
/// 用法：
/// ```dart
/// class GearCubit extends Cubit<GearState>
///     with SafeEmitMixin<GearState>, TripDirtyMarkerMixin<GearState> {
///
///   @override
///   ITripRepository get tripRepository => _tripRepository;
///
///   @override
///   String? get currentTripId => _currentTripId;
/// }
/// ```
mixin TripDirtyMarkerMixin<S> on Cubit<S> {
  /// 行程 Repository，由宿主 Cubit 提供。
  ITripRepository get tripRepository;

  /// 目前正在操作的行程 ID；若無則為 null。
  String? get currentTripId;

  /// 將目前行程標記為「待同步更新」。
  ///
  /// 僅在 [currentTripId] 不為 null 時執行，呼叫端無需額外判斷。
  Future<void> markCurrentTripDirty() async {
    final id = currentTripId;
    if (id != null) {
      await tripRepository.markTripAsPendingUpdate(id);
    }
  }
}
