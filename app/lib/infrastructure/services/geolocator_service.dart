import 'package:geolocator/geolocator.dart';
import '../../domain/interfaces/i_geolocator_service.dart';

/// 定位服務實作
///
/// 使用 `geolocator` 套件存取裝置 GPS 位置。
/// 處理權限請求與服務狀態檢查。
class GeolocatorService implements IGeolocatorService {
  /// 取得當前位置
  ///
  /// 此方法會先檢查：
  /// 1. 裝置定位服務是否啟用
  /// 2. App 是否擁有定位權限 (若無則請求)
  ///
  /// 若所有檢查通過，則回傳目前座標。
  /// [LocationAccuracy.low] 用於非導航場景，節省電力並加快獲取速度。
  @override
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 檢查定位服務是否啟用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('定位服務未啟用 (Location services are disabled)');
    }

    // 檢查並請求權限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('定位權限被拒 (Location permissions are denied)');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('定位權限被永久拒絕 (Location permissions are permanently denied)');
    }

    // 取得目前位置
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
    );
  }
}
