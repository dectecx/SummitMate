import 'package:geolocator/geolocator.dart';
import 'package:summitmate/domain/interfaces/i_geolocator_service.dart';

class MockGeolocatorService implements IGeolocatorService {
  @override
  Future<Position> getCurrentPosition() async {
    // Return a dummy position (Taipei)
    return Position(
      longitude: 121.5,
      latitude: 25.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 1.0,
    );
  }
}
