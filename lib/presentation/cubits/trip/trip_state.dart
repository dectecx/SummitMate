import 'package:equatable/equatable.dart';
import '../../../data/models/trip.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {
  const TripInitial();
}

class TripLoading extends TripState {
  const TripLoading();
}

class TripLoaded extends TripState {
  final List<Trip> trips;
  final Trip? activeTrip;

  const TripLoaded({required this.trips, this.activeTrip});

  @override
  List<Object?> get props => [trips, activeTrip];
}

class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object?> get props => [message];
}
