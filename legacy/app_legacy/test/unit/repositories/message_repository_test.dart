import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_message_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_message_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/message_repository.dart';

// Mocks
class MockMessageLocalDataSource extends Mock implements IMessageLocalDataSource {}

class MockMessageRemoteDataSource extends Mock implements IMessageRemoteDataSource {}

class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  late MessageRepository repository;
  late MockMessageLocalDataSource mockLocalDataSource;
  late MockMessageRemoteDataSource mockRemoteDataSource;
  late MockConnectivityService mockConnectivity;

  late Message testMessage;

  setUpAll(() {
    testMessage = Message(
      id: 'msg_1',
      tripId: 'trip_1',
      userId: 'user_1',
      user: 'User 1',
      content: 'Hello',
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'user_1',
      updatedAt: DateTime.now(),
      updatedBy: 'user_1',
      avatar: '🐻',
    );

    registerFallbackValue(testMessage);
  });

  setUp(() {
    mockLocalDataSource = MockMessageLocalDataSource();
    mockRemoteDataSource = MockMessageRemoteDataSource();
    mockConnectivity = MockConnectivityService();
    when(() => mockConnectivity.isOffline).thenReturn(false);
    repository = MessageRepository(mockLocalDataSource, mockRemoteDataSource, mockConnectivity);
  });

  group('MessageRepository', () {
    test(
      'Given MessageRepository, When executing, Then getByTripId delegates to localDataSource getAll and filters',
      () async {
        when(() => mockLocalDataSource.getAll()).thenAnswer((_) async => [testMessage]);
        final result = await repository.getByTripId('trip_1');
        expect(result, [testMessage]);
        verify(() => mockLocalDataSource.getAll()).called(1);
      },
    );

    group('getRemoteMessages', () {
      test('Given getRemoteMessages, When executing, Then fetches from remote and saves to local', () async {
        final paginated = PaginatedList(items: [testMessage], page: 1, total: 1, hasMore: false);
        when(
          () => mockRemoteDataSource.getMessages(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(paginated));
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        final result = await repository.getRemoteMessages('trip_1');

        expect(result, isA<Success>());
        verify(
          () => mockRemoteDataSource.getMessages(
            'trip_1',
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.add(any())).called(1);
      });
    });

    group('addMessage', () {
      test('Given online, When addMessage, Then it posts to remote', () async {
        when(
          () => mockRemoteDataSource.addMessage(
            tripId: any(named: 'tripId'),
            content: any(named: 'content'),
            replyToId: any(named: 'replyToId'),
          ),
        ).thenAnswer((_) async => const Success('msg_1'));

        final result = await repository.addMessage(tripId: 'trip_1', content: 'Hello');

        expect(result, isA<Success>());
        verify(
          () => mockRemoteDataSource.addMessage(
            tripId: 'trip_1',
            content: 'Hello',
            replyToId: any(named: 'replyToId'),
          ),
        ).called(1);
      });

      test('Given offline, When addMessage, Then it returns failure without hitting remote', () async {
        when(() => mockConnectivity.isOffline).thenReturn(true);

        final result = await repository.addMessage(tripId: 'trip_1', content: 'Hello');

        expect(result, isA<Failure>());
        verifyNever(
          () => mockRemoteDataSource.addMessage(
            tripId: any(named: 'tripId'),
            content: any(named: 'content'),
            replyToId: any(named: 'replyToId'),
          ),
        );
      });
    });

    group('deleteById', () {
      test('Given online, When deleteById, Then deletes remote then local', () async {
        when(() => mockLocalDataSource.deleteById(any())).thenAnswer((_) async {});
        when(() => mockRemoteDataSource.deleteMessage(any(), any())).thenAnswer((_) async => const Success(null));

        await repository.deleteById('trip_1', 'msg_1');

        verify(() => mockRemoteDataSource.deleteMessage('trip_1', 'msg_1')).called(1);
        verify(() => mockLocalDataSource.deleteById('msg_1')).called(1);
      });

      test('Given offline, When deleteById, Then it returns failure without deleting', () async {
        when(() => mockConnectivity.isOffline).thenReturn(true);

        final result = await repository.deleteById('trip_1', 'msg_1');

        expect(result, isA<Failure>());
        verifyNever(() => mockRemoteDataSource.deleteMessage(any(), any()));
        verifyNever(() => mockLocalDataSource.deleteById(any()));
      });
    });
  });
}
