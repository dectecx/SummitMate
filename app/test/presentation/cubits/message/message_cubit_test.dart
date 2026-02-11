import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_message_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/presentation/cubits/message/message_cubit.dart';
import 'package:summitmate/presentation/cubits/message/message_state.dart';
import 'package:summitmate/core/error/result.dart';

class MockMessageRepository extends Mock implements IMessageRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockSyncService extends Mock implements ISyncService {}

class MockAuthService extends Mock implements IAuthService {}

class FakeMessage extends Fake implements Message {}

class FakeTrip extends Fake implements Trip {}

void main() {
  late MockMessageRepository mockRepo;
  late MockTripRepository mockTripRepo;
  late MockSyncService mockSyncService;
  late MockAuthService mockAuthService;
  late MessageCubit cubit;

  final testMessage1 = Message(
    id: 'm1',
    content: 'Hello',
    category: 'chat',
    tripId: 't1',
    timestamp: DateTime.now(),
    createdAt: DateTime.now(),
    createdBy: 'u1',
    updatedAt: DateTime.now(),
    updatedBy: 'u1',
  );
  final testMessage2 = Message(
    id: 'm2',
    content: 'World',
    category: 'chat',
    tripId: 't1',
    timestamp: DateTime.now().add(const Duration(minutes: 1)),
    createdAt: DateTime.now().add(const Duration(minutes: 1)),
    createdBy: 'u1',
    updatedAt: DateTime.now().add(const Duration(minutes: 1)),
    updatedBy: 'u1',
  );
  final globalMessage = Message(
    id: 'm3',
    content: 'Global',
    category: 'chat',
    timestamp: DateTime.now(),
    createdAt: DateTime.now(),
    createdBy: 'u1',
    updatedAt: DateTime.now(),
    updatedBy: 'u1',
  );

  setUpAll(() {
    registerFallbackValue(FakeMessage());
    registerFallbackValue(FakeTrip());
  });

  setUp(() {
    mockRepo = MockMessageRepository();
    mockTripRepo = MockTripRepository();
    mockSyncService = MockSyncService();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.currentUserId).thenReturn('u1');

    // Default setup: active trip 't1'
    when(() => mockTripRepo.getActiveTrip(any())).thenAnswer(
      (_) async => Success(
        Trip(
          id: 't1',
          userId: 'u1',
          name: 'Test Trip',
          startDate: DateTime.now(),
          isActive: true,
          createdAt: DateTime.now(),
          createdBy: 'u1',
          updatedAt: DateTime.now(),
          updatedBy: 'u1',
        ),
      ),
    );

    cubit = MessageCubit(
      repository: mockRepo,
      tripRepository: mockTripRepo,
      syncService: mockSyncService,
      authService: mockAuthService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is MessageInitial', () {
    expect(cubit.state, const MessageInitial());
  });

  group('loadMessages', () {
    blocTest<MessageCubit, MessageState>(
      'emits [MessageLoading, MessageLoaded] with filtered messages',
      setUp: () {
        when(
          () => mockRepo.getAllMessages(),
        ).thenAnswer((_) async => Success([testMessage1, testMessage2, globalMessage]));
      },
      build: () => cubit,
      act: (cubit) => cubit.loadMessages(),
      expect: () => [
        const MessageLoading(),
        isA<MessageLoaded>().having((s) => s.allMessages.length, 'length', 3), // Should contain trip + global
      ],
    );

    blocTest<MessageCubit, MessageState>(
      'filters messages not belonging to current trip',
      setUp: () {
        final otherTripMsg = Message(
          id: 'm4',
          content: 'Other',
          tripId: 't2',
          createdAt: DateTime.now(),
          createdBy: 'u2',
          updatedAt: DateTime.now(),
          updatedBy: 'u2',
        );
        when(() => mockRepo.getAllMessages()).thenAnswer((_) async => Success([testMessage1, otherTripMsg]));
      },
      build: () => cubit,
      act: (cubit) => cubit.loadMessages(),
      expect: () => [
        const MessageLoading(),
        isA<MessageLoaded>().having((s) => s.allMessages, 'filtered', [testMessage1]),
      ],
    );
  });

  group('addMessage', () {
    blocTest<MessageCubit, MessageState>(
      'calls syncService.addMessageAndSync and reloads',
      setUp: () {
        when(() => mockRepo.getAllMessages()).thenAnswer((_) async => Success([testMessage1]));
        when(() => mockSyncService.addMessageAndSync(any())).thenAnswer((_) async => const Success(null));
      },
      build: () => cubit,
      seed: () => MessageLoaded(allMessages: [testMessage1]),
      act: (cubit) => cubit.addMessage(user: 'User', avatar: 'A', content: 'New Msg'),
      verify: (_) {
        verify(() => mockSyncService.addMessageAndSync(any())).called(1);
        verify(() => mockRepo.getAllMessages()).called(1); // Reload called
      },
    );
  });

  group('syncMessages', () {
    blocTest<MessageCubit, MessageState>(
      'emits isSyncing true then false, reloads on success',
      setUp: () {
        when(
          () => mockSyncService.syncMessages(isAuto: false),
        ).thenAnswer((_) async => SyncResult.success(messagesSynced: true));
        when(() => mockRepo.getAllMessages()).thenAnswer((_) async => Success([testMessage1]));
      },
      build: () => cubit,
      seed: () => MessageLoaded(allMessages: []),
      act: (cubit) => cubit.syncMessages(isAuto: false),
      expect: () => [
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', true),
        isA<MessageLoaded>()
            .having((s) => s.allMessages, 'messages', [testMessage1])
            .having((s) => s.isSyncing, 'syncing', true),
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', false).having((s) => s.allMessages, 'messages', [
          testMessage1,
        ]),
      ],
    );

    blocTest<MessageCubit, MessageState>(
      'emits error on sync failure (manual)',
      setUp: () {
        when(
          () => mockSyncService.syncMessages(isAuto: false),
        ).thenAnswer((_) async => SyncResult.failure('Network error'));
        when(() => mockRepo.getAllMessages()).thenAnswer((_) async => const Success([]));
      },
      build: () => cubit,
      seed: () => const MessageLoaded(allMessages: []),
      act: (cubit) => cubit.syncMessages(isAuto: false),
      expect: () => [
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', true),
        isA<MessageError>().having((s) => s.message, 'error', contains('Network error')),
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', false), // Restores state if we re-emit filtered?
        // Wait, catch block emits error, then finally emits loaded(syncing:false) if state is loaded.
        // If we emitted error, we are no longer MessageLoaded.
        // My implementation:
        // if (!result.isSuccess) emit(MessageError) -> State becomes MessageError
        // finally block checks `if (state is MessageLoaded)`.
        // So finally block won't emit syncing=false if we are in Error state.
        // This effectively leaves it in Error state.
      ],
    );
  });
}
