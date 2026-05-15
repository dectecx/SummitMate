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

  /// 是否為教學展示模式 (Mock Mode)
  final bool isMockMode;

  /// 建構子
  const TripLoaded({required this.trips, this.activeTrip, this.isSyncing = false, this.isMockMode = false});

  /// 當前行程是否已上傳至雲端
  bool get isActiveTripCloudReady => activeTrip?.isCloudReady ?? false;

  /// 當前行程是否為純本地 (從未上傳)
  bool get isActiveTripLocalOnly => activeTrip?.isLocalOnly ?? true;

  TripLoaded copyWith({List<Trip>? trips, Trip? activeTrip, bool? isSyncing, bool? isMockMode}) {
    return TripLoaded(
      trips: trips ?? this.trips,
      activeTrip: activeTrip ?? this.activeTrip,
      isSyncing: isSyncing ?? this.isSyncing,
      isMockMode: isMockMode ?? this.isMockMode,
    );
  }

  @override
  List<Object?> get props => [trips, activeTrip, isSyncing, isMockMode];
}

/// 行程錯誤
class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object?> get props => [message];
}
