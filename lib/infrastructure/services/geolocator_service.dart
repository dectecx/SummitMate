import 'package:geolocator/geolocator.dart';
import '../../domain/interfaces/i_geolocator_service.dart';

class GeolocatorService implements IGeolocatorService {
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
