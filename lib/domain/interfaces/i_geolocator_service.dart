import 'package:geolocator/geolocator.dart';

abstract interface class IGeolocatorService {
  Future<Position> getCurrentPosition();
}
