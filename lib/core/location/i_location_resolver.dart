/// 地點解析介面
/// 負責將經緯度轉換為對應的天氣預報區域代碼 (如鄉鎮市區代碼)
abstract class ILocationResolver {
  /// 根據經緯度取得對應的 Location ID
  /// [lat] 緯度
  /// [lon] 經度
  /// 回傳: (LocationID, LocationName) e.g., ("1000402", "新竹縣尖石鄉")
  Future<({String id, String name})?> resolve(double lat, double lon);
}
