import 'package:equatable/equatable.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/base/toast_notification.dart';

abstract class PollState extends Equatable {
  /// 一次性 Toast 通知，由 UI 層 [BlocListener] 消費後應立即呼叫 `clearNotification()`。
  final ToastNotification? notification;

  const PollState({this.notification});

  @override
  List<Object?> get props => [notification];
}

class PollInitial extends PollState {
  const PollInitial({super.notification});
}

class PollLoading extends PollState {
  const PollLoading({super.notification});
}

class PollLoaded extends PollState {
  final List<Poll> polls;
  final String currentUserId;
  final DateTime? lastSyncTime;
  final bool isSyncing;

  /// 建構子
  ///
  /// [polls] 所有投票列表
  /// [currentUserId] 目前使用者 ID (用於篩選我的投票)
  /// [lastSyncTime] 上次同步時間
  /// [isSyncing] 是否正在同步
  const PollLoaded({
    required this.polls,
    required this.currentUserId,
    this.lastSyncTime,
    this.isSyncing = false,
    super.notification,
  });

  /// Computed: Active Polls (sorted by date)
  List<Poll> get activePolls =>
      polls.where((p) => p.isActive).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Computed: Ended Polls
  List<Poll> get endedPolls =>
      polls.where((p) => !p.isActive).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Computed: My Polls
  List<Poll> get myPolls =>
      polls.where((p) => p.creatorId == currentUserId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  PollLoaded copyWith({
    List<Poll>? polls,
    String? currentUserId,
    DateTime? lastSyncTime,
    bool? isSyncing,
    ToastNotification? notification,
    bool clearNotification = false,
  }) {
    return PollLoaded(
      polls: polls ?? this.polls,
      currentUserId: currentUserId ?? this.currentUserId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      notification: clearNotification ? null : (notification ?? this.notification),
    );
  }

  @override
  List<Object?> get props => [polls, currentUserId, lastSyncTime, isSyncing, notification];
}

class PollError extends PollState {
  final String message;

  const PollError(this.message, {super.notification});

  @override
  List<Object?> get props => [message, notification];
}
