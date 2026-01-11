import 'package:geolocator/geolocator.dart';

/// 地理定位服務介面
/// 負責取得裝置目前的 GPS 位置及處理權限檢查
abstract interface class IGeolocatorService {
  /// 取得目前位置
  ///
  /// 會自動檢查並請求定位權限。
  /// 若服務未啟用或權限被拒，則拋出例外。
  Future<Position> getCurrentPosition();
}
