import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/models/group_event.dart';
import 'package:summitmate/data/models/group_event_comment.dart';
import 'package:summitmate/data/repositories/interfaces/i_group_event_repository.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/presentation/cubits/group_event/group_event_cubit.dart';
import 'package:summitmate/presentation/cubits/group_event/group_event_state.dart';

/// Fake Repository for testing - pure Dart implementation without Mock inheritance
class FakeGroupEventRepository implements IGroupEventRepository {
  List<GroupEvent> _events = [];
  bool _shouldFail = false;

  void setEvents(List<GroupEvent> events) => _events = List.from(events);
  void setShouldFail(bool fail) => _shouldFail = fail;

  @override
  List<GroupEvent> getAll() => _events;

  @override
  DateTime? getLastSyncTime() => null;

  @override
  Future<void> saveAll(List<GroupEvent> events) async {}

  @override
  Future<void> save(GroupEvent event) async {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      _events[idx] = event;
    } else {
      _events.add(event);
    }
  }

  @override
  Future<Result<void, Exception>> likeEvent({required String eventId, required String userId}) async {
    if (_shouldFail) {
      // Rollback in fake (simulate what real repo does)
      return Failure(Exception('Network Error'));
    }
    // Update local state
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final event = _events[idx];
      _events[idx] = event.copyWith(isLiked: true, likeCount: event.likeCount + 1);
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Exception>> unlikeEvent({required String eventId, required String userId}) async {
    if (_shouldFail) {
      return Failure(Exception('Network Error'));
    }
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final event = _events[idx];
      _events[idx] = event.copyWith(isLiked: false, likeCount: event.likeCount - 1);
    }
    return const Success(null);
  }

  // Stub implementations for other methods
  @override
  Future<Result<void, Exception>> init() async => const Success(null);
  @override
  GroupEvent? getById(String eventId) => null;
  @override
  Future<void> delete(String eventId) async {}
  @override
  Future<Result<void, Exception>> clearAll() async => const Success(null);
  @override
  List<GroupEventApplication> getAllApplications() => [];
  @override
  Future<void> saveApplications(List<GroupEventApplication> applications) async {}
  @override
  Future<Result<List<GroupEvent>, Exception>> syncEvents({String? category}) async => Success(_events);
  @override
  Future<Result<GroupEvent, Exception>> syncEventById(String eventId) async => Failure(Exception('Not implemented'));
  @override
  Future<Result<List<GroupEventApplication>, Exception>> syncMyApplications(String userId) async => const Success([]);
  @override
  Future<Result<String, Exception>> create({
    required String title,
    required String description,
    required String category,
    required DateTime eventDate,
    required String eventLocation,
    required int maxParticipants,
    required DateTime deadline,
    required String creatorId,
  }) async => const Success('new_id');
  @override
  Future<Result<void, Exception>> update(GroupEvent event) async => const Success(null);
  @override
  Future<Result<void, Exception>> remove({required String eventId, required String userId}) async =>
      const Success(null);
  @override
  Future<Result<void, Exception>> apply({required String eventId, required String userId, String? note}) async =>
      const Success(null);
  @override
  Future<Result<void, Exception>> cancelApplication({required String eventId, required String userId}) async =>
      const Success(null);
  @override
  Future<Result<void, Exception>> reviewApplication({
    required String eventId,
    required String applicantUserId,
    required String reviewerId,
    required String action,
    String? note,
  }) async => const Success(null);
  @override
  Future<Result<void, Exception>> closeEvent({required String eventId, required String userId}) async =>
      const Success(null);

  @override
  Future<Result<List<GroupEventApplication>, Exception>> getApplications({required String eventId}) async =>
      const Success([]);

  // Comment stubs
  @override
  Future<Result<List<GroupEventComment>, Exception>> getComments({required String eventId}) async => const Success([]);

  @override
  Future<Result<GroupEventComment, Exception>> addComment({
    required String eventId,
    required String userId,
    required String content,
  }) async => Success(
    GroupEventComment(
      id: 'c1',
      eventId: eventId,
      userId: userId,
      content: content,
      userName: 'Test User',
      userAvatar: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  @override
  Future<Result<void, Exception>> deleteComment({required String commentId, required String userId}) async =>
      const Success(null);
}

class FakeConnectivityService implements IConnectivityService {
  @override
  bool get isOffline => false;

  // Stub other methods
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeAuthService implements IAuthService {
  @override
  String? get currentUserId => 'test_user_id';

  // Stub other methods
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupEventCubit - Like Feature', () {
    late GroupEventCubit cubit;
    late FakeGroupEventRepository fakeRepo;
    late FakeConnectivityService fakeConnectivity;
    late FakeAuthService fakeAuth;

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
      fakeRepo = FakeGroupEventRepository();
      fakeConnectivity = FakeConnectivityService();
      fakeAuth = FakeAuthService();

      cubit = GroupEventCubit(groupEventRepository: fakeRepo, connectivity: fakeConnectivity, authService: fakeAuth);
    });

    tearDown(() => cubit.close());

    blocTest<GroupEventCubit, GroupEventState>(
      'likeEvent toggles isLiked from false to true and increments count',
      seed: () => GroupEventLoaded(events: [testEvent], currentUserId: 'test_user_id', isGuest: false),
      build: () {
        fakeRepo.setEvents([testEvent]);
        fakeRepo.setShouldFail(false);
        return cubit;
      },
      act: (cubit) => cubit.likeEvent(eventId: 'evt_1'),
      expect: () => [
        isA<GroupEventLoaded>()
            .having((s) => s.events.first.isLiked, 'isLiked true', true)
            .having((s) => s.events.first.likeCount, 'likeCount 6', 6),
      ],
    );

    blocTest<GroupEventCubit, GroupEventState>(
      'likeEvent rolls back on failure',
      seed: () => GroupEventLoaded(events: [testEvent], currentUserId: 'test_user_id', isGuest: false),
      build: () {
        fakeRepo.setEvents([testEvent]);
        fakeRepo.setShouldFail(true);
        return cubit;
      },
      act: (cubit) => cubit.likeEvent(eventId: 'evt_1'),
      expect: () => [
        // Optimistic update
        isA<GroupEventLoaded>().having((s) => s.events.first.isLiked, 'optimistic liked', true),
        // Rollback - repo returns original state via getAll()
        isA<GroupEventLoaded>().having((s) => s.events.first.isLiked, 'rollback unliked', false),
      ],
    );
  });
}
