import 'package:equatable/equatable.dart';
import 'package:summitmate/domain/domain.dart';

abstract class GroupEventState extends Equatable {
  const GroupEventState();

  @override
  List<Object?> get props => [];
}

class GroupEventInitial extends GroupEventState {
  const GroupEventInitial();
}

class GroupEventLoading extends GroupEventState {
  const GroupEventLoading();
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
  });

  /// Open events (recruiting)
  List<GroupEvent> get openEvents =>
      events.where((e) => e.status == GroupEventStatus.open).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// My created events
  List<GroupEvent> get myCreatedEvents =>
      events.where((e) => e.creatorId == currentUserId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
  }) {
    return GroupEventLoaded(
      events: events ?? this.events,
      currentUserId: currentUserId ?? this.currentUserId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [events, currentUserId, lastSyncTime, isSyncing, isGuest];
}

class GroupEventError extends GroupEventState {
  final String message;

  const GroupEventError(this.message);

  @override
  List<Object?> get props => [message];
}

/// ─────────────────────────────────────────────
/// 「我的揪團」專用狀態 (host / apply / like)
/// ─────────────────────────────────────────────

class MyEventsLoading extends GroupEventState {
  const MyEventsLoading();
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
  });

  MyEventsLoaded copyWith({
    List<GroupEvent>? events,
    String? type,
    int? page,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MyEventsLoaded(
      events: events ?? this.events,
      type: type ?? this.type,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [events, type, page, total, hasMore, isLoadingMore];
}

class MyEventsError extends GroupEventState {
  final String message;
  final String type;

  const MyEventsError({required this.message, required this.type});

  @override
  List<Object?> get props => [message, type];
}
