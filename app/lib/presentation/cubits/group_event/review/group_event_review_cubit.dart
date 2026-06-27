import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/base/safe_emit_mixin.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/core.dart';
import 'package:summitmate/domain/domain.dart';

part 'group_event_review_state.dart';

@injectable
class GroupEventReviewCubit extends Cubit<GroupEventReviewState> with SafeEmitMixin<GroupEventReviewState> {
  final IGroupEventRepository _repository;
  final String? eventId;
  final String? userId;

  GroupEventReviewCubit(this._repository, @factoryParam this.eventId, @factoryParam this.userId)
    : assert(eventId != null, 'eventId must not be null'),
      assert(userId != null, 'userId must not be null'),
      super(GroupEventReviewInitial());

  /// 載入報名列表
  Future<void> loadApplications() async {
    safeEmit(GroupEventReviewLoading());
    try {
      final result = await _repository.getApplications(eventId: eventId!);
      if (result is Success<List<GroupEventApplication>, Exception>) {
        safeEmit(GroupEventReviewLoaded(result.value));
      } else if (result is Failure<List<GroupEventApplication>, Exception>) {
        safeEmit(GroupEventReviewError(result.exception.toString()));
      }
    } catch (e) {
      safeEmit(GroupEventReviewError(e.toString()));
    }
  }

  /// 審核報名
  ///
  /// [appId] 報名 ID
  /// [action] 動作
  Future<void> reviewApplication(String appId, GroupEventReviewAction action, {String? note}) async {
    final currentState = state;
    if (currentState is! GroupEventReviewLoaded) return;

    final currentApps = currentState.applications;

    try {
      safeEmit(GroupEventReviewSyncing(currentApps));

      final result = await _repository.reviewApplication(
        eventId: eventId,
        applicationId: appId,
        action: action,
        note: note,
      );

      if (result is Success) {
        // Success: Refresh list to get updated status
        loadApplications();
      } else if (result is Failure) {
        safeEmit(GroupEventReviewError(result.exception.toString()));
        safeEmit(GroupEventReviewLoaded(currentApps));
      }
    } catch (e) {
      safeEmit(GroupEventReviewError(e.toString()));
      safeEmit(GroupEventReviewLoaded(currentApps));
    }
  }
}
