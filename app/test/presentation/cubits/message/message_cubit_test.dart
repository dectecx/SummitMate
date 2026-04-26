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
import 'package:summitmate/core/models/paginated_list.dart';

class MockMessageRepository extends Mock implements IMessageRepository {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockSyncService extends Mock implements ISyncService {}

class MockAuthService extends Mock implements IAuthService {}

class FakeMessage extends Fake implements Message {}

class FakeTrip extends Fake implements Trip {}

void main() {
  late MockMessageRepository mockRepo;
  late MockTripRepository mockTripRepo;
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

  setUpAll(() {
    registerFallbackValue(FakeMessage());
    registerFallbackValue(FakeTrip());
  });

  setUp(() {
    mockRepo = MockMessageRepository();
    mockTripRepo = MockTripRepository();
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

    cubit = MessageCubit(mockRepo, mockTripRepo, mockAuthService);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is MessageInitial', () {
    expect(cubit.state, const MessageInitial());
  });

  group('loadMessages', () {
    blocTest<MessageCubit, MessageState>(
      'emits [MessageLoading, MessageLoaded] with messages',
      setUp: () {
        when(() => mockRepo.getByTripId(any())).thenReturn([testMessage1, testMessage2]);
      },
      build: () => cubit,
      act: (cubit) => cubit.loadMessages(),
      expect: () => [const MessageLoading(), isA<MessageLoaded>().having((s) => s.allMessages.length, 'length', 2)],
    );
  });

  group('addMessage', () {
    blocTest<MessageCubit, MessageState>(
      'calls repo.addMessage and reloads',
      setUp: () {
        when(() => mockRepo.getByTripId(any())).thenReturn([testMessage1]);
        when(
          () => mockRepo.addMessage(
            tripId: any(named: 'tripId'),
            content: any(named: 'content'),
            replyToId: any(named: 'replyToId'),
          ),
        ).thenAnswer((_) async => const Success('m_new'));
        when(
          () => mockRepo.getRemoteMessages(any()),
        ).thenAnswer((_) async => Success(PaginatedList<Message>(items: [], page: 1, total: 0, hasMore: false)));
      },
      build: () => cubit,
      seed: () => MessageLoaded(allMessages: [testMessage1]),
      act: (cubit) => cubit.addMessage(user: 'User', avatar: 'A', content: 'New Msg'),
      verify: (_) {
        verify(() => mockRepo.addMessage(tripId: 't1', content: 'New Msg', replyToId: null)).called(1);
        verify(() => mockRepo.getByTripId('t1')).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('syncMessages', () {
    blocTest<MessageCubit, MessageState>(
      'emits isSyncing true then false, reloads on success',
      setUp: () {
        when(() => mockRepo.getRemoteMessages(any())).thenAnswer(
          (_) async => Success(PaginatedList<Message>(items: [testMessage1], page: 1, total: 1, hasMore: false)),
        );
        when(() => mockRepo.getByTripId(any())).thenReturn([testMessage1]);
      },
      build: () => cubit,
      seed: () => const MessageLoaded(allMessages: []),
      act: (cubit) => cubit.syncMessages(isAuto: false),
      expect: () => [
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', true),
        isA<MessageLoaded>()
            .having((s) => s.allMessages, 'messages', [testMessage1])
            .having((s) => s.isSyncing, 'syncing', false),
      ],
    );

    blocTest<MessageCubit, MessageState>(
      'emits error on sync failure (manual)',
      setUp: () {
        when(
          () => mockRepo.getRemoteMessages(any()),
        ).thenAnswer((_) async => Failure(GeneralException('Network error')));
        when(() => mockRepo.getByTripId(any())).thenReturn([]);
      },
      build: () => cubit,
      seed: () => const MessageLoaded(allMessages: []),
      act: (cubit) => cubit.syncMessages(isAuto: false),
      expect: () => [
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', true),
        isA<MessageError>().having((s) => s.message, 'error', contains('Network error')),
        isA<MessageLoaded>().having((s) => s.isSyncing, 'syncing', false),
      ],
    );
  });
}
