import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_message_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_data_service.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';
import 'package:summitmate/presentation/cubits/message/message_cubit.dart';
import 'package:summitmate/presentation/cubits/message/message_state.dart';

class MockMessageRepository extends Mock implements IMessageRepository {}
class MockTripRepository extends Mock implements ITripRepository {}
class MockSyncService extends Mock implements ISyncService {}

void main() {
  group('MessageCubit', () {
    late MessageCubit messageCubit;
    late MockMessageRepository mockMessageRepo;
    late MockTripRepository mockTripRepo;
    late MockSyncService mockSyncService;

    final testMessage = Message(
      uuid: '1',
      user: 'Test',
      category: 'General',
      content: 'Hello',
      timestamp: DateTime.now(),
    );

    setUp(() {
      mockMessageRepo = MockMessageRepository();
      mockTripRepo = MockTripRepository();
      mockSyncService = MockSyncService();

      when(() => mockMessageRepo.getAllMessages()).thenReturn([testMessage]);
      when(() => mockTripRepo.getActiveTrip()).thenReturn(Trip(id: 't1', name: 'Trip1', startDate: DateTime.now()));
      // Mock SyncService response
      when(() => mockSyncService.addMessageAndSync(any())).thenAnswer((_) async => ApiResult(isSuccess: true));
      
      registerFallbackValue(testMessage);

      messageCubit = MessageCubit(
        repository: mockMessageRepo,
        tripRepository: mockTripRepo,
        syncService: mockSyncService,
      );
    });

    tearDown(() {
      messageCubit.close();
    });

    test('initial state is MessageInitial', () {
      expect(messageCubit.state, isA<MessageInitial>());
    });

    blocTest<MessageCubit, MessageState>(
      'loadMessages loads from repo',
      build: () => messageCubit,
      act: (cubit) => cubit.loadMessages(),
      expect: () => [
        isA<MessageLoading>(),
        isA<MessageLoaded>().having((s) => s.allMessages.length, 'messages count', 1),
      ],
    );

    blocTest<MessageCubit, MessageState>(
      'addMessage calls sync service',
      build: () => messageCubit,
      seed: () => MessageLoaded(allMessages: [testMessage]),
      act: (cubit) => cubit.addMessage(user: 'User', avatar: 'A', content: 'New Msg'),
      verify: (_) {
        verify(() => mockSyncService.addMessageAndSync(any())).called(1);
      },
    );
  });
}
