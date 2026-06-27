import '../entities/gear_library_item.dart';
import '../entities/linked_trip_info.dart';

/// 裝備庫同步服務介面 (Domain Service)
///
/// 封裝跨 Repository 的裝備庫同步業務規則：
/// - 將庫存更新同步至所有連結的行程裝備
/// - 查詢連結特定庫存項目的行程清單
abstract interface class IGearLibrarySyncService {
  /// 將庫存項目的變更 (name/weight/category) 同步至所有連結的行程裝備。
  ///
  /// 僅更新尚未封存的行程；若欄位未變動則略過該裝備。
  /// 失敗時拋出例外，由呼叫端決定錯誤處理策略。
  Future<void> syncLinkedGear(GearLibraryItem libItem);

  /// 查詢連結指定庫存項目的行程摘要清單。
  Future<List<LinkedTripInfo>> getLinkedTrips(String libraryItemId);
}
