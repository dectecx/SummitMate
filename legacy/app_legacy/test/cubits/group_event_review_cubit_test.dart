import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/group_event/review/group_event_review_cubit.dart';

class MockGroupEventRepository extends Mock implements IGroupEventRepository {}

void main() {
  late MockGroupEventRepository mockRepo;
  late GroupEventReviewCubit cubit;

  const eventId = 'event-1';
  const userId = 'user-1';

  final sampleApp = GroupEventApplication(
    id: 'app-1',
    eventId: eventId,
    userId: 'applicant-1',
    status: GroupEventApplicationStatus.pending,
    message: 'Hello',
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
    updatedBy: 'applicant-1',
    userName: 'Tester',
    userAvatar: '👤',
  );

  setUp(() {
    mockRepo = MockGroupEventRepository();
    cubit = GroupEventReviewCubit(mockRepo, eventId, userId);
  });

  group('GroupEventReviewCubit', () {
    test('initial state is GroupEventReviewInitial', () {
      expect(cubit.state, isA<GroupEventReviewInitial>());
    });

    blocTest<GroupEventReviewCubit, GroupEventReviewState>(
      'reviewApplication success emits syncing, action success, loading, and loaded',
      build: () => cubit,
      seed: () => GroupEventReviewLoaded([sampleApp]),
      act: (c) async {
        when(
          () => mockRepo.reviewApplication(
            eventId: eventId,
            applicationId: 'app-1',
            action: GroupEventReviewAction.approve,
            note: null,
          ),
        ).thenAnswer((_) async => const Success(null));

        when(
          () => mockRepo.getApplications(eventId: eventId),
        ).thenAnswer((_) async => Success([sampleApp.copyWith(status: GroupEventApplicationStatus.approved)]));

        await c.reviewApplication('app-1', GroupEventReviewAction.approve);
      },
      expect: () => [
        isA<GroupEventReviewSyncing>(),
        isA<GroupEventReviewActionSuccess>().having((s) => s.message, 'message', '操作成功'),
        isA<GroupEventReviewLoading>(),
        isA<GroupEventReviewLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockRepo.reviewApplication(
            eventId: eventId,
            applicationId: 'app-1',
            action: GroupEventReviewAction.approve,
            note: null,
          ),
        ).called(1);
      },
    );
  });
}
