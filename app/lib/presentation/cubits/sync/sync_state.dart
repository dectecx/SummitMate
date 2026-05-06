import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  final int pendingCount;
  final bool isOnline;

  const SyncState({this.pendingCount = 0, this.isOnline = true});

  bool get isInProgress => this is SyncInProgress;
  bool get isFailure => this is SyncFailure;
  bool get isSuccess => this is SyncSuccess;
  bool get isInitial => this is SyncInitial;

  @override
  List<Object?> get props => [pendingCount, isOnline];
}

class SyncInitial extends SyncState {
  final DateTime? lastSyncTime;

  const SyncInitial({
    this.lastSyncTime,
    int pendingCount = 0,
    bool isOnline = true,
  }) : super(pendingCount: pendingCount, isOnline: isOnline);

  @override
  List<Object?> get props => [...super.props, lastSyncTime];
}

class SyncInProgress extends SyncState {
  final String message;

  const SyncInProgress({
    this.message = '正在同步資料...',
    int pendingCount = 0,
    bool isOnline = true,
  }) : super(pendingCount: pendingCount, isOnline: isOnline);

  @override
  List<Object?> get props => [...super.props, message];
}

class SyncSuccess extends SyncState {
  final DateTime timestamp;
  final String message;

  const SyncSuccess({
    required this.timestamp,
    required this.message,
    int pendingCount = 0,
    bool isOnline = true,
  }) : super(pendingCount: pendingCount, isOnline: isOnline);

  @override
  List<Object?> get props => [...super.props, timestamp, message];
}

class SyncFailure extends SyncState {
  final String errorMessage;
  final DateTime? lastSuccessTime;

  const SyncFailure({
    required this.errorMessage,
    this.lastSuccessTime,
    int pendingCount = 0,
    bool isOnline = true,
  }) : super(pendingCount: pendingCount, isOnline: isOnline);

  @override
  List<Object?> get props => [...super.props, errorMessage, lastSuccessTime];
}
