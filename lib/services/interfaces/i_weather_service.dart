import '../../data/models/weather_data.dart';

/// Weather Service 抽象介面
/// 定義天氣資料服務的契約
abstract interface class IWeatherService {
  /// 初始化服務 (檢查快取、設定等)
  Future<void> init();

  /// 根據「地點名稱」取得天氣
  ///
  /// 此方法主要用於查詢特定山岳或已知地點的天氣。
  /// [locationName] 地點名稱 (例如: '向陽山', '玉山')
  /// [forceRefresh] 是否強制忽略快取重新從 API 取得
  Future<WeatherData?> getWeatherByName(String locationName, {bool forceRefresh = false});

  /// 根據「經緯度」取得天氣 (通常用於即時位置)
  ///
  /// 此方法會自動將座標轉換為對應的行政區 (鄉鎮市區)，並查詢該區的天氣預報 (CWA F-D0047-093)。
  /// [lat] 緯度
  /// [lon] 經度
  /// [forceRefresh] 是否強制忽略快取重新從 API 取得
  Future<WeatherData?> getWeatherByLocation(double lat, double lon, {bool forceRefresh = false});
}
