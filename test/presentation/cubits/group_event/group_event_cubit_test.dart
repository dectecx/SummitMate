import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/models/group_event.dart';
import 'package:summitmate/data/repositories/interfaces/i_group_event_repository.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_group_event_service.dart';
import 'package:summitmate/presentation/cubits/group_event/group_event_cubit.dart';
import 'package:summitmate/presentation/cubits/group_event/group_event_state.dart';

// Manual Mock Classes
class MockGroupEventService extends Mock implements IGroupEventService {
  @override
  Future<Result<void, Exception>> likeEvent({required String eventId, required String userId}) {
    return super.noSuchMethod(
      Invocation.method(#likeEvent, [], {#eventId: eventId, #userId: userId}),
      returnValue: Future.value(const Success<void, Exception>(null)),
      returnValueForMissingStub: Future.value(const Success<void, Exception>(null)),
    );
  }

  @override
  Future<Result<void, Exception>> unlikeEvent({required String eventId, required String userId}) {
    return super.noSuchMethod(
      Invocation.method(#unlikeEvent, [], {#eventId: eventId, #userId: userId}),
      returnValue: Future.value(const Success<void, Exception>(null)),
      returnValueForMissingStub: Future.value(const Success<void, Exception>(null)),
    );
  }
}

class FakeGroupEventRepository implements IGroupEventRepository {
  List<GroupEvent> _events = [];
  void setEvents(List<GroupEvent> events) => _events = events;

  @override
  List<GroupEvent> getAll() => _events;

  @override
  DateTime? getLastSyncTime() => null;

  @override
  Future<void> saveAll(List<GroupEvent> events) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConnectivityService extends Mock implements IConnectivityService {
  @override
  bool get isOffline => false;
}

class MockAuthService extends Mock implements IAuthService {
  @override
  String? get currentUserId => 'test_user_id';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupEventCubit - Like Feature', () {
    late GroupEventCubit cubit;
    late MockGroupEventService mockService;
    late FakeGroupEventRepository fakeRepo;
    late MockConnectivityService mockConnectivity;
    late MockAuthService mockAuth;

    final testEvent = GroupEvent(
      id: 'evt_1',
      creatorId: 'creator_1',
      title: 'Test Event',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'creator_1',
      updatedAt: DateTime.now(),
      updatedBy: 'creator_1',
      isLiked: false,
      likeCount: 5,
    );

    setUp(() {
      mockService = MockGroupEventService();
      fakeRepo = FakeGroupEventRepository();
      mockConnectivity = MockConnectivityService();
      mockAuth = MockAuthService();

      cubit = GroupEventCubit(
        groupEventService: mockService,
        groupEventRepository: fakeRepo,
        connectivity: mockConnectivity,
        authService: mockAuth,
      );
    });

    tearDown(() => cubit.close());

    blocTest<GroupEventCubit, GroupEventState>(
      'likeEvent toggles isLiked from false to true and increments count',
      seed: () => GroupEventLoaded(events: [testEvent], currentUserId: 'test_user_id', isGuest: false),
      build: () {
        when(
          mockService.likeEvent(eventId: 'evt_1', userId: 'test_user_id'),
        ).thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (cubit) => cubit.likeEvent(eventId: 'evt_1'),
      expect: () => [
        isA<GroupEventLoaded>()
            .having((s) => s.events.first.isLiked, 'isLiked true', true)
            .having((s) => s.events.first.likeCount, 'likeCount 6', 6),
      ],
      verify: (_) {
        verify(mockService.likeEvent(eventId: 'evt_1', userId: 'test_user_id')).called(1);
      },
    );

    blocTest<GroupEventCubit, GroupEventState>(
      'likeEvent rolls back on failure',
      seed: () => GroupEventLoaded(events: [testEvent], currentUserId: 'test_user_id', isGuest: false),
      build: () {
        when(
          mockService.likeEvent(eventId: 'evt_1', userId: 'test_user_id'),
        ).thenAnswer((_) async => Failure(Exception('Network Error')));
        return cubit;
      },
      act: (cubit) => cubit.likeEvent(eventId: 'evt_1'),
      expect: () => [
        // Optimistic update
        isA<GroupEventLoaded>().having((s) => s.events.first.isLiked, 'optimistic liked', true),
        // Rollback
        isA<GroupEventLoaded>().having((s) => s.events.first.isLiked, 'rollback unliked', false),
      ],
    );
  });
}
