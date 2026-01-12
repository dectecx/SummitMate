import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/core/constants.dart';
import 'package:summitmate/data/models/poll.dart';
import 'package:summitmate/data/repositories/interfaces/i_poll_repository.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';
import 'package:summitmate/domain/interfaces/i_poll_service.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/presentation/cubits/poll/poll_cubit.dart';
import 'package:summitmate/presentation/cubits/poll/poll_state.dart';

class MockPollService extends Mock implements IPollService {}

class MockPollRepository extends Mock implements IPollRepository {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPollService mockPollService;
  late MockPollRepository mockRepo;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuthService;
  late MockSharedPreferences mockPrefs;
  late PollCubit cubit;

  final testPoll = Poll(id: 'p1', title: 'Poll 1', creatorId: 'u1', createdAt: DateTime.now(), options: []);

  setUp(() {
    mockPollService = MockPollService();
    mockRepo = MockPollRepository();
    mockConnectivity = MockConnectivityService();
    mockAuthService = MockAuthService();
    mockPrefs = MockSharedPreferences();

    when(() => mockAuthService.currentUserId).thenReturn('u1');
    when(() => mockPrefs.getString(PrefKeys.username)).thenReturn('u1');
    when(() => mockConnectivity.isOffline).thenReturn(false);
    when(() => mockRepo.getAllPolls()).thenReturn([]);
    when(() => mockRepo.getLastSyncTime()).thenReturn(null);

    cubit = PollCubit(
      pollService: mockPollService,
      pollRepository: mockRepo,
      connectivity: mockConnectivity,
      authService: mockAuthService,
      prefs: mockPrefs,
    );
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
        when(() => mockRepo.getAllPolls()).thenReturn([testPoll]);
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
      'fetches polls from service and saves to repo',
      setUp: () {
        when(() => mockRepo.getAllPolls()).thenReturn([]);
        when(() => mockPollService.getPolls(userId: 'u1')).thenAnswer((_) async => [testPoll]);
        when(() => mockRepo.savePolls([testPoll])).thenAnswer((_) async {});
        when(() => mockRepo.saveLastSyncTime(any())).thenAnswer((_) async {});
      },
      build: () => cubit,
      act: (cubit) => cubit.fetchPolls(),
      verify: (_) {
        verify(() => mockPollService.getPolls(userId: 'u1')).called(1);
        verify(() => mockRepo.savePolls([testPoll])).called(1);
      },
      expect: () => [
        const PollLoading(),
        isA<PollLoaded>().having((s) => s.polls, 'polls', [testPoll]).having((s) => s.isSyncing, 'syncing', false),
      ],
    );

    blocTest<PollCubit, PollState>(
      'handles offline mode gracefully',
      setUp: () {
        when(() => mockConnectivity.isOffline).thenReturn(true);
      },
      build: () => cubit,
      seed: () => const PollLoaded(polls: [], currentUserId: 'u1'),
      act: (cubit) => cubit.fetchPolls(),
      expect: () => [], // Should just return, maybe show toast
    );
  });

  group('createPoll', () {
    blocTest<PollCubit, PollState>(
      'calls service to create poll',
      setUp: () {
        when(
          () => mockPollService.createPoll(
            title: 'New Poll',
            description: '', // default
            creatorId: 'u1',
            deadline: null,
            isAllowAddOption: false, // default
            maxOptionLimit: 20, // default
            allowMultipleVotes: false, // default
            initialOptions: const [],
          ),
        ).thenAnswer((_) async {});

        // Mock fetchPolls called internally
        when(() => mockPollService.getPolls(userId: 'u1')).thenAnswer((_) async => [testPoll]);
        when(() => mockRepo.savePolls(any())).thenAnswer((_) async {});
        when(() => mockRepo.saveLastSyncTime(any())).thenAnswer((_) async {});
      },
      build: () => cubit,
      seed: () => const PollLoaded(polls: [], currentUserId: 'u1'),
      act: (cubit) => cubit.createPoll(title: 'New Poll'),
      verify: (_) {
        verify(
          () => mockPollService.createPoll(
            title: 'New Poll',
            description: '',
            creatorId: 'u1',
            deadline: null,
            isAllowAddOption: false,
            maxOptionLimit: 20,
            allowMultipleVotes: false,
            initialOptions: const [],
          ),
        ).called(1);
      },
      expect: () => [
        isA<PollLoaded>().having((s) => s.isSyncing, 'syncing start', true),
        // Wait, inside _performAction we call action then fetchPolls.
        // fetchPolls emits isSyncing=true if in loaded state?
        // fetchPolls calls emit(copyWith(isSyncing: true)) if loaded.
        // But _performAction already did emit(isSyncing: true).
        // So fetchPolls sees isSyncing=true already? No, it emits again likely or distinct check?
        // Cubit doesn't distinct by default unless Equatable props are same.
        // If state is same, bloc skips.
        // _performAction: emits syncing=true.
        // fetchPolls: checks loaded, emits syncing=true (if not already checking? Logic in fetchPolls: emit(copyWith(isSyncing: true))).
        // If it's already true, and I emit true, Equatable props are identical, so no new emission.
        // Then fetch calls service.
        // Then fetch success: emits loaded(syncing: false).
        // So expected emissions:
        // 1. isSyncing=true (from _performAction)
        // 2. isSyncing=false (from fetchPolls success)

        // Let's verify.
        isA<PollLoaded>().having((s) => s.isSyncing, 'syncing end', false).having((s) => s.polls, 'polls populated', [
          testPoll,
        ]),
      ],
    );
  });
}
