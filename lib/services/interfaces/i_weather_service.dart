import '../../data/models/weather_data.dart';

/// Weather Service 抽象介面
/// 定義天氣資料服務的契約
abstract interface class IWeatherService {
  /// 初始化服務
  Future<void> init();

  /// 取得天氣 (優先使用快取)
  /// [forceRefresh] 強制重新取得
  /// [locationName] 地點名稱
  Future<WeatherData?> getWeather({bool forceRefresh = false, String locationName = '向陽山'});

  /// 從 API 取得最新天氣
  Future<WeatherData> fetchWeather({String locationName = '向陽山'});

  /// 根據座標取得天氣 (使用鄉鎮預報 F-D0047-093)
  /// [lat] 緯度
  /// [lon] 經度
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon);
}
