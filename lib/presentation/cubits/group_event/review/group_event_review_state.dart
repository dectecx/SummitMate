part of 'group_event_review_cubit.dart';

abstract class GroupEventReviewState extends Equatable {
  const GroupEventReviewState();

  @override
  List<Object> get props => [];
}

class GroupEventReviewInitial extends GroupEventReviewState {}

class GroupEventReviewLoading extends GroupEventReviewState {}

class GroupEventReviewLoaded extends GroupEventReviewState {
  final List<GroupEventApplication> applications;

  const GroupEventReviewLoaded(this.applications);

  @override
  List<Object> get props => [applications];
}

class GroupEventReviewSyncing extends GroupEventReviewState {
  final List<GroupEventApplication> applications;
  const GroupEventReviewSyncing(this.applications);

  @override
  List<Object> get props => [applications];
}

class GroupEventReviewError extends GroupEventReviewState {
  final String message;

  const GroupEventReviewError(this.message);

  @override
  List<Object> get props => [message];
}
