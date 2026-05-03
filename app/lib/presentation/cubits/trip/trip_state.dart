import 'package:equatable/equatable.dart';
import 'package:summitmate/domain/domain.dart';

/// 行程狀態基類
abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

/// 行程初始狀態
class TripInitial extends TripState {
  const TripInitial();
}

/// 行程載入中
class TripLoading extends TripState {
  const TripLoading();
}

/// 行程載入完成
class TripLoaded extends TripState {
  /// 行程列表
  final List<Trip> trips;

  /// 目前選中的行程
  final Trip? activeTrip;

  /// 是否正在同步
  final bool isSyncing;

  /// 建構子
  const TripLoaded({required this.trips, this.activeTrip, this.isSyncing = false});

  TripLoaded copyWith({List<Trip>? trips, Trip? activeTrip, bool? isSyncing}) {
    return TripLoaded(
      trips: trips ?? this.trips,
      activeTrip: activeTrip ?? this.activeTrip,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [trips, activeTrip, isSyncing];
}

/// 行程錯誤
class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object?> get props => [message];
}
