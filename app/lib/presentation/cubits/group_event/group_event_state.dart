import 'package:equatable/equatable.dart';
import '../../../data/models/group_event.dart';
import '../../../data/models/enums/group_event_status.dart';

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
      events.where((e) => e.status == GroupEventStatus.open).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

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
