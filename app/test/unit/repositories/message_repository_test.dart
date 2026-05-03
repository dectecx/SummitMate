import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_message_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_message_remote_data_source.dart';
import 'package:summitmate/data/models/message_model.dart';
import 'package:summitmate/data/repositories/message_repository.dart';

// Mocks
class MockMessageLocalDataSource extends Mock implements IMessageLocalDataSource {}

class MockMessageRemoteDataSource extends Mock implements IMessageRemoteDataSource {}

void main() {
  late MessageRepository repository;
  late MockMessageLocalDataSource mockLocalDataSource;
  late MockMessageRemoteDataSource mockRemoteDataSource;

  late MessageModel testMessageModel;

  setUpAll(() {
    testMessageModel = MessageModel(
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
      category: 'general',
      avatar: '🐻',
    );

    registerFallbackValue(testMessageModel);
    registerFallbackValue(testMessageModel.toDomain());
  });

  setUp(() {
    mockLocalDataSource = MockMessageLocalDataSource();
    mockRemoteDataSource = MockMessageRemoteDataSource();
    repository = MessageRepository(mockLocalDataSource, mockRemoteDataSource);
  });

  group('MessageRepository', () {
    test('getByTripId delegates to localDataSource getAll and filters', () {
      when(() => mockLocalDataSource.getAll()).thenReturn([testMessageModel]);
      final result = repository.getByTripId('trip_1');
      expect(result, [testMessageModel.toDomain()]);
      verify(() => mockLocalDataSource.getAll()).called(1);
    });

    group('getRemoteMessages', () {
      test('fetches from remote and saves to local', () async {
        final paginated = PaginatedList(items: [testMessageModel.toDomain()], page: 1, total: 1, hasMore: false);
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
      test('adds to remote and triggers sync', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.addMessage(
            tripId: any(named: 'tripId'),
            content: any(named: 'content'),
            replyToId: any(named: 'replyToId'),
          ),
        ).thenAnswer((_) async => const Success('msg_1'));

        // Mock the sync call that happens inside addMessage
        when(
          () => mockRemoteDataSource.getMessages(
            any(),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Success(PaginatedList(items: [testMessageModel.toDomain()], page: 1, total: 1, hasMore: false)),
        );
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.addMessage(tripId: 'trip_1', content: 'Hello');

        // Assert
        expect(result, isA<Success>());
        verify(
          () => mockRemoteDataSource.addMessage(
            tripId: 'trip_1',
            content: 'Hello',
            replyToId: any(named: 'replyToId'),
          ),
        ).called(1);
        verify(() => mockLocalDataSource.add(any())).called(greaterThanOrEqualTo(1));
      });
    });

    group('deleteById', () {
      test('deletes from local and remote', () async {
        // Arrange
        when(() => mockLocalDataSource.delete(any())).thenAnswer((_) async {});
        when(() => mockRemoteDataSource.deleteMessage(any(), any())).thenAnswer((_) async => const Success(null));

        // Act
        await repository.deleteById('trip_1', 'msg_1');

        // Assert
        verify(() => mockLocalDataSource.delete('msg_1')).called(1);
        verify(() => mockRemoteDataSource.deleteMessage('trip_1', 'msg_1')).called(1);
      });
    });
  });
}
