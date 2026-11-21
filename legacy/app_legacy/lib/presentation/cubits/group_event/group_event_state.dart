import 'package:equatable/equatable.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/base/toast_notification.dart';

abstract class GroupEventState extends Equatable {
  /// 一次性 Toast 通知，由 UI 層 [BlocListener] 消費後應立即呼叫 `clearNotification()`。
  final ToastNotification? notification;

  const GroupEventState({this.notification});

  @override
  List<Object?> get props => [notification];
}

class GroupEventInitial extends GroupEventState {
  const GroupEventInitial({super.notification});
}

class GroupEventLoading extends GroupEventState {
  const GroupEventLoading({super.notification});
}

class GroupEventLoaded extends GroupEventState {
  final List<GroupEvent> events;
  final String currentUserId;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final bool isGuest;

  const GroupEventLoaded({
    required this.events,
    required this.currentUserId,
    this.lastSyncTime,
    this.isSyncing = false,
    this.isGuest = false,
    super.notification,
  });

  /// Open events (recruiting)
  List<GroupEvent> get openEvents =>
      events.where((e) => e.status == GroupEventStatus.open).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// My created events
  List<GroupEvent> get myCreatedEvents =>
      events.where((e) => e.hostId == currentUserId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// My applied events
  List<GroupEvent> get myAppliedEvents =>
      events.where((e) => e.myApplicationStatus != null).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// My liked events
  List<GroupEvent> get myLikedEvents =>
      events.where((e) => e.isLiked).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  GroupEventLoaded copyWith({
    List<GroupEvent>? events,
    String? currentUserId,
    DateTime? lastSyncTime,
    bool? isSyncing,
    bool? isGuest,
    ToastNotification? notification,
    bool clearNotification = false,
  }) {
    return GroupEventLoaded(
      events: events ?? this.events,
      currentUserId: currentUserId ?? this.currentUserId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      isGuest: isGuest ?? this.isGuest,
      notification: clearNotification ? null : (notification ?? this.notification),
    );
  }

  @override
  List<Object?> get props => [events, currentUserId, lastSyncTime, isSyncing, isGuest, notification];
}

class GroupEventError extends GroupEventState {
  final String message;

  const GroupEventError(this.message, {super.notification});

  @override
  List<Object?> get props => [message, notification];
}

/// ─────────────────────────────────────────────
/// 「我的揪團」專用狀態 (host / apply / like)
/// ─────────────────────────────────────────────

class MyEventsLoading extends GroupEventState {
  const MyEventsLoading({super.notification});
}

class MyEventsLoaded extends GroupEventState {
  final List<GroupEvent> events;
  final String type; // 'host' | 'apply' | 'like'
  final int page;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  const MyEventsLoaded({
    required this.events,
    required this.type,
    required this.page,
    required this.total,
    this.hasMore = false,
    this.isLoadingMore = false,
    super.notification,
  });

  MyEventsLoaded copyWith({
    List<GroupEvent>? events,
    String? type,
    int? page,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    ToastNotification? notification,
    bool clearNotification = false,
  }) {
    return MyEventsLoaded(
      events: events ?? this.events,
      type: type ?? this.type,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      notification: clearNotification ? null : (notification ?? this.notification),
    );
  }

  @override
  List<Object?> get props => [events, type, page, total, hasMore, isLoadingMore, notification];
}

class MyEventsError extends GroupEventState {
  final String message;
  final String type;

  const MyEventsError({required this.message, required this.type, super.notification});

  @override
  List<Object?> get props => [message, type, notification];
}
