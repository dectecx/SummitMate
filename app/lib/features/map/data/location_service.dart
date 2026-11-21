import 'package:geolocator/geolocator.dart';

/// Result of asking where the person is.
sealed class LocationResult {
  const LocationResult();
}

class LocationFound extends LocationResult {
  const LocationFound(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// The person said no (or "no" is permanent: they must change it in system settings).
class LocationDenied extends LocationResult {
  const LocationDenied({this.permanent = false});
  final bool permanent;
}

/// Location services are switched off on the phone.
class LocationDisabled extends LocationResult {
  const LocationDisabled();
}

/// No fix could be obtained (e.g. indoors) within a reasonable time.
class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

abstract interface class LocationService {
  Future<LocationResult> current();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return const LocationDisabled();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return const LocationDenied(permanent: true);
    if (permission == LocationPermission.denied) return const LocationDenied();
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      return LocationFound(p.latitude, p.longitude);
    } on Object {
      return const LocationUnavailable();
    }
  }
}
