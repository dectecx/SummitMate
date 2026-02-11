import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/core.dart';
import '../../../../data/models/group_event.dart';
import '../../../../data/repositories/interfaces/i_group_event_repository.dart';

part 'group_event_review_state.dart';

class GroupEventReviewCubit extends Cubit<GroupEventReviewState> {
  final IGroupEventRepository _repository;
  final String eventId;
  final String userId;

  GroupEventReviewCubit({required IGroupEventRepository repository, required this.eventId, required this.userId})
    : _repository = repository,
      super(GroupEventReviewInitial());

  /// 載入報名列表
  Future<void> loadApplications() async {
    emit(GroupEventReviewLoading());
    try {
      final result = await _repository.getApplications(eventId: eventId);
      if (result is Success<List<GroupEventApplication>, Exception>) {
        emit(GroupEventReviewLoaded(result.value));
      } else if (result is Failure<List<GroupEventApplication>, Exception>) {
        emit(GroupEventReviewError(result.exception.toString()));
      }
    } catch (e) {
      emit(GroupEventReviewError(e.toString()));
    }
  }

  /// 審核報名
  ///
  /// [appId] 報名 ID
  /// [action] 動作 (approve/reject)
  Future<void> reviewApplication(String appId, String action) async {
    final currentState = state;
    if (currentState is! GroupEventReviewLoaded) return;

    final currentApps = currentState.applications;

    // Optimistic update (show syncing state with current data)
    emit(GroupEventReviewSyncing(currentApps));

    try {
      final result = await _repository.reviewApplication(
        eventId: appId, // Here appId serves as the ID to operate on
        applicantUserId: "", // Not needed for remote
        reviewerId: userId,
        action: action,
      );

      if (result is Success) {
        // Success: Refresh list to get updated status
        loadApplications();
      } else if (result is Failure) {
        emit(GroupEventReviewError(result.exception.toString()));
        emit(GroupEventReviewLoaded(currentApps));
      }
    } catch (e) {
      emit(GroupEventReviewError(e.toString()));
      emit(GroupEventReviewLoaded(currentApps));
    }
  }
}
