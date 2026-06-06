import 'package:equatable/equatable.dart';

/// 連線狀態基類
sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  /// 是否處於離線狀態
  bool get isOffline;

  @override
  List<Object?> get props => [isOffline];
}

/// 初始連線狀態
final class ConnectivityInitial extends ConnectivityState {
  @override
  final bool isOffline;

  const ConnectivityInitial({this.isOffline = false});
}

/// 已更新的連線狀態
final class ConnectivityUpdated extends ConnectivityState {
  @override
  final bool isOffline;

  const ConnectivityUpdated({required this.isOffline});
}
