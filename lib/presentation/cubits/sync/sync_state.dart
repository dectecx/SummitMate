import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  final DateTime? lastSyncTime;

  const SyncInitial({this.lastSyncTime});

  @override
  List<Object?> get props => [lastSyncTime];
}

class SyncInProgress extends SyncState {
  final String message;

  const SyncInProgress({this.message = '正在同步資料...'});

  @override
  List<Object?> get props => [message];
}

class SyncSuccess extends SyncState {
  final DateTime timestamp;
  final String message;

  const SyncSuccess({required this.timestamp, required this.message});

  @override
  List<Object?> get props => [timestamp, message];
}

class SyncFailure extends SyncState {
  final String errorMessage;
  final DateTime? lastSuccessTime;

  const SyncFailure({required this.errorMessage, this.lastSuccessTime});

  @override
  List<Object?> get props => [errorMessage, lastSuccessTime];
}
