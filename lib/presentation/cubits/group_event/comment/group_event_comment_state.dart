import 'package:equatable/equatable.dart';
import '../../../../data/models/group_event_comment.dart';

sealed class GroupEventCommentState extends Equatable {
  const GroupEventCommentState();

  @override
  List<Object?> get props => [];
}

final class GroupEventCommentInitial extends GroupEventCommentState {
  const GroupEventCommentInitial();
}

final class GroupEventCommentLoading extends GroupEventCommentState {
  const GroupEventCommentLoading();
}

final class GroupEventCommentLoaded extends GroupEventCommentState {
  final List<GroupEventComment> comments;
  final bool isSending;

  const GroupEventCommentLoaded({required this.comments, this.isSending = false});

  @override
  List<Object?> get props => [comments, isSending];

  GroupEventCommentLoaded copyWith({List<GroupEventComment>? comments, bool? isSending}) {
    return GroupEventCommentLoaded(comments: comments ?? this.comments, isSending: isSending ?? this.isSending);
  }
}

final class GroupEventCommentError extends GroupEventCommentState {
  final String message;

  const GroupEventCommentError(this.message);

  @override
  List<Object?> get props => [message];
}
