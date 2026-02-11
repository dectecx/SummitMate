import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoaded extends MapState {
  final Position? currentLocation;
  final double? currentHeading;
  final Gpx? gpx;
  final List<LatLng> trackPoints;
  final bool isLoading;

  /// 建構子
  ///
  /// [currentLocation] 目前 GPS 位置
  /// [currentHeading] 目前方位角
  /// [gpx] 載入的 GPX 資料
  /// [trackPoints] 軌跡點列表
  /// [isLoading] 是否正在載入
  const MapLoaded({
    this.currentLocation,
    this.currentHeading,
    this.gpx,
    this.trackPoints = const [],
    this.isLoading = false,
  });

  MapLoaded copyWith({
    Position? currentLocation,
    double? currentHeading,
    Gpx? gpx,
    List<LatLng>? trackPoints,
    bool? isLoading,
  }) {
    return MapLoaded(
      currentLocation: currentLocation ?? this.currentLocation,
      currentHeading: currentHeading ?? this.currentHeading,
      gpx: gpx ?? this.gpx,
      trackPoints: trackPoints ?? this.trackPoints,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [currentLocation, currentHeading, gpx, trackPoints, isLoading];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object> get props => [message];
}
