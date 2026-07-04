import '../../core/error/result.dart';

/// 行程天數跨聚合協調服務介面 (Domain Service)
///
/// 封裝 `renameDay` / `removeDay` 涉及的跨聚合業務規則：
/// - Trip.dayNames（天數名稱列表）
/// - ItineraryItem.day（行程節點的天數欄位）
/// - MealPlanDay.linkedItineraryDay（糧食計畫天數的綁定）
abstract interface class IItineraryDayService {
  /// 重新命名天數
  ///
  /// 原子性地更新 Trip.dayNames 與所有對應 ItineraryItem.day。
  /// 若 [newName] 已存在，回傳 [Failure]。
  ///
  /// [tripId] 行程 ID
  /// [oldName] 原天數名稱
  /// [newName] 新天數名稱
  Future<Result<void, Exception>> renameDay(String tripId, String oldName, String newName);

  /// 移除天數
  ///
  /// 執行順序：
  /// 1. 確認無行程節點（有則回傳 [Failure]）
  /// 2. 若有綁定的糧食計畫天數且 [confirmUnlink] 為 false，回傳 [Failure] 通知呼叫端
  /// 3. 若 [confirmUnlink] 為 true，解除糧食計畫天數綁定
  /// 4. 從 Trip.dayNames 移除該天數
  ///
  /// [tripId] 行程 ID
  /// [name] 天數名稱
  /// [confirmUnlink] 是否確認解除糧食計畫綁定
  Future<Result<void, Exception>> removeDay(
    String tripId,
    String name, {
    bool confirmUnlink = false,
  });
}
