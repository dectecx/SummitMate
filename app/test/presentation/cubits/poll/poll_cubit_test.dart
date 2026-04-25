import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/models/poll.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_poll_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_poll_service.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/presentation/cubits/poll/poll_cubit.dart';
import 'package:summitmate/presentation/cubits/poll/poll_state.dart';
import 'package:summitmate/core/error/result.dart';

class MockPollService extends Mock implements IPollService {}

class MockPollRepository extends Mock implements IPollRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPollRepository mockRepo;
  late MockTripRepository mockTripRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;
  late PollCubit cubit;

  final testPoll = Poll(
    id: 'p1',
    title: 'Poll 1',
    creatorId: 'u1',
    createdAt: DateTime.now(),
    createdBy: 'u1',
    updatedAt: DateTime.now(),
    updatedBy: 'u1',
    options: [],
  );

  final testTrip = Trip(
    id: 'trip1',
    userId: 'u1',
    name: 'Trip 1',
    startDate: DateTime.now(),
    createdAt: DateTime.now(),
    createdBy: 'u1',
    updatedAt: DateTime.now(),
    updatedBy: 'u1',
  );

  setUp(() {
    mockRepo = MockPollRepository();
    mockTripRepo = MockTripRepository();
    mockConnectivity = MockConnectivityService();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.currentUserId).thenReturn('u1');
    when(() => mockConnectivity.isOffline).thenReturn(false);
    when(() => mockTripRepo.getActiveTrip(any())).thenAnswer((_) async => Success(testTrip));
    when(() => mockRepo.getByTripId(any())).thenReturn([]);

    cubit = PollCubit(mockRepo, mockTripRepo, mockConnectivity, mockAuthService);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is correct', () {
    expect(cubit.state, const PollInitial());
  });

  group('loadPolls', () {
    blocTest<PollCubit, PollState>(
      'loads polls from repository',
      setUp: () {
        when(() => mockRepo.getByTripId('trip1')).thenReturn([testPoll]);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadPolls(),
      expect: () => [
        const PollLoading(),
        isA<PollLoaded>().having((s) => s.polls, 'polls', [testPoll]),
      ],
    );
  });

  group('fetchPolls', () {
    blocTest<PollCubit, PollState>(
      'fetches polls from repository syncPolls',
      setUp: () {
        final paginated = PaginatedList<Poll>(items: [testPoll], page: 1, total: 1, hasMore: false);
        when(() => mockRepo.syncPolls('trip1')).thenAnswer((_) async => Success(paginated));
      },
      build: () => cubit,
      act: (cubit) => cubit.fetchPolls(),
      verify: (_) {
        verify(() => mockRepo.syncPolls('trip1')).called(1);
      },
      expect: () => [
        const PollLoading(),
        isA<PollLoaded>().having((s) => s.polls, 'polls', [testPoll]).having((s) => s.isSyncing, 'syncing', false),
      ],
    );
  });

  group('createPoll', () {
    blocTest<PollCubit, PollState>(
      'calls repo to create poll',
      setUp: () {
        when(() => mockRepo.create(
              tripId: any(named: 'tripId'),
              title: any(named: 'title'),
              options: any(named: 'options'),
              allowMultiple: any(named: 'allowMultiple'),
            )).thenAnswer((_) async => const Success('p1'));

        final paginated = PaginatedList<Poll>(items: [testPoll], page: 1, total: 1, hasMore: false);
        when(() => mockRepo.syncPolls('trip1')).thenAnswer((_) async => Success(paginated));
      },
      build: () => cubit,
      seed: () => const PollLoaded(polls: [], currentUserId: 'u1'),
      act: (cubit) => cubit.createPoll(title: 'New Poll'),
      verify: (_) {
        verify(() => mockRepo.create(
              tripId: 'trip1',
              title: 'New Poll',
              options: const [],
              allowMultiple: false,
            )).called(1);
      },
      expect: () => [
        isA<PollLoaded>().having((s) => s.isSyncing, 'syncing start', true),
        isA<PollLoaded>().having((s) => s.isSyncing, 'syncing end', false).having((s) => s.polls, 'polls populated', [testPoll]),
      ],
    );
  });
}
