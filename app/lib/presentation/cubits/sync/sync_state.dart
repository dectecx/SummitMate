import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  /// 上次同步時間
  final DateTime? lastSyncTime;

  /// 建構子
  ///
  /// [lastSyncTime] 上次同步時間 (可為 null)
  const SyncInitial({this.lastSyncTime});

  @override
  List<Object?> get props => [lastSyncTime];
}

class SyncInProgress extends SyncState {
  final String message;

  /// 建構子
  ///
  /// [message] 進度訊息
  const SyncInProgress({this.message = '正在同步資料...'});

  @override
  List<Object?> get props => [message];
}

class SyncSuccess extends SyncState {
  final DateTime timestamp;
  final String message;

  /// 建構子
  ///
  /// [timestamp] 同步完成時間
  /// [message] 成功訊息
  const SyncSuccess({required this.timestamp, required this.message});

  @override
  List<Object?> get props => [timestamp, message];
}

class SyncFailure extends SyncState {
  final String errorMessage;
  final DateTime? lastSuccessTime;

  /// 建構子
  ///
  /// [errorMessage] 錯誤訊息
  /// [lastSuccessTime] 上次成功時間 (如果有的話)
  const SyncFailure({required this.errorMessage, this.lastSuccessTime});

  @override
  List<Object?> get props => [errorMessage, lastSuccessTime];
}
