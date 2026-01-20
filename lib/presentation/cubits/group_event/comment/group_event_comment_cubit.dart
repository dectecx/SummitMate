import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/result.dart';
import '../../../../data/models/group_event_comment.dart';
import '../../../../data/repositories/interfaces/i_group_event_repository.dart';
import '../../../../domain/interfaces/i_auth_service.dart';
import 'group_event_comment_state.dart';

class GroupEventCommentCubit extends Cubit<GroupEventCommentState> {
  final IGroupEventRepository _repository;
  final IAuthService _authService;
  final String eventId;

  GroupEventCommentCubit({
    required IGroupEventRepository repository,
    required IAuthService authService,
    required this.eventId,
  }) : _repository = repository,
       _authService = authService,
       super(const GroupEventCommentInitial());

  String get currentUserId => _authService.currentUserId ?? 'guest';

  /// 載入留言
  Future<void> loadComments() async {
    emit(const GroupEventCommentLoading());

    final result = await _repository.getComments(eventId: eventId);

    switch (result) {
      case Success(value: final comments):
        emit(GroupEventCommentLoaded(comments: comments));
      case Failure(exception: final error):
        emit(GroupEventCommentError(error.toString()));
    }
  }

  /// 新增留言
  Future<void> addComment(String content) async {
    if (content.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! GroupEventCommentLoaded) return;

    emit(currentState.copyWith(isSending: true));

    final result = await _repository.addComment(eventId: eventId, userId: currentUserId, content: content);

    switch (result) {
      case Success(value: final newComment):
        final updatedComments = List<GroupEventComment>.from(currentState.comments)..add(newComment);
        emit(currentState.copyWith(comments: updatedComments, isSending: false));
      case Failure(exception: final error):
        // 恢復原狀並顯示錯誤 (實際應用可能需要一次性錯誤事件)
        emit(currentState.copyWith(isSending: false));
        emit(GroupEventCommentError(error.toString()));
        // 重新載入以恢復 UI
        emit(GroupEventCommentLoaded(comments: currentState.comments));
    }
  }

  /// 刪除留言
  Future<void> deleteComment(String commentId) async {
    final currentState = state;
    if (currentState is! GroupEventCommentLoaded) return;

    // 樂觀更新
    final originalComments = currentState.comments;
    final updatedComments = originalComments.where((c) => c.id != commentId).toList();
    emit(currentState.copyWith(comments: updatedComments));

    final result = await _repository.deleteComment(commentId: commentId, userId: currentUserId);

    if (result is Failure) {
      // 失敗回滾
      emit(currentState.copyWith(comments: originalComments));
      emit(GroupEventCommentError(result.exception.toString()));
      emit(currentState); // 恢復顯示列表
    }
  }
}
