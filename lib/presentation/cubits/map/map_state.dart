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
