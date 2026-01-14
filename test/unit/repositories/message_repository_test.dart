import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/datasources/interfaces/i_message_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_message_remote_data_source.dart';
import 'package:summitmate/data/models/message.dart';
import 'package:summitmate/data/repositories/message_repository.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';

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

  setUp(() {
    mockLocalDataSource = MockMessageLocalDataSource();
    mockRemoteDataSource = MockMessageRemoteDataSource();
    mockConnectivity = MockConnectivityService();
    repository = MessageRepository(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      connectivity: mockConnectivity,
    );

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
    );

    registerFallbackValue(testMessage);
  });

  group('MessageRepository', () {
    test('init calls localDataSource.init', () async {
      when(() => mockLocalDataSource.init()).thenAnswer((_) async {});

      await repository.init();

      verify(() => mockLocalDataSource.init()).called(1);
    });

    test('getAllMessages delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getAll()).thenReturn([testMessage]);
      final result = await repository.getAllMessages();
      expect(result, isA<Success>());
      expect((result as Success).value, [testMessage]);
      verify(() => mockLocalDataSource.getAll()).called(1);
    });

    group('addMessage', () {
      test('adds to local and remote when online', () async {
        // Arrange
        when(() => mockConnectivity.isOffline).thenReturn(false);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});
        when(() => mockRemoteDataSource.addMessage(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.addMessage(testMessage);

        // Assert
        expect(result, isA<Success>());
        verify(() => mockLocalDataSource.add(testMessage)).called(1);
        verify(() => mockRemoteDataSource.addMessage(testMessage)).called(1);
      });

      test('returns failure when offline', () async {
        // Arrange
        when(() => mockConnectivity.isOffline).thenReturn(true);

        // Act
        final result = await repository.addMessage(testMessage);

        // Assert
        expect(result, isA<Failure>());
        verifyNever(() => mockLocalDataSource.add(any()));
        verifyNever(() => mockRemoteDataSource.addMessage(any()));
      });

      test('adds to local and catches remote error (best effort)', () async {
        // Arrange
        when(() => mockConnectivity.isOffline).thenReturn(false);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});
        when(() => mockRemoteDataSource.addMessage(any())).thenThrow(Exception('Sync failed'));

        // Act
        final result = await repository.addMessage(testMessage);

        // Assert
        expect(result, isA<Success>()); // Should still succeed
        verify(() => mockLocalDataSource.add(testMessage)).called(1);
        verify(() => mockRemoteDataSource.addMessage(testMessage)).called(1);
      });
    });

    group('deleteById', () {
      test('deletes from local and remote when online', () async {
        // Arrange
        when(() => mockConnectivity.isOffline).thenReturn(false);
        when(() => mockLocalDataSource.getById('msg_1')).thenReturn(testMessage);
        when(() => mockLocalDataSource.delete('0')).thenAnswer((_) async {}); // Assuming deleted via key
        // Mock HiveObject behavior or standard delete if simplified in Repo.
        // In Repo: _localDataSource.getById(id) -> item.delete() or _localDataSource.delete(key).
        // For testing, we might need to mock item.isInBox or just assume Repo logic.
        // The Repo logic is:
        // final item = _localDataSource.getById(id);
        // if (item != null) { if (item.isInBox) await item.delete(); else await _localDataSource.delete(item.key); }

        // Let's simplify and assume the repo logic uses `item.delete()` if we can mock it,
        // OR checks item.isInBox.
        // `testMessage` is a HiveObject. `isInBox` defaults to false.
        // So it will call `_localDataSource.delete(item.key)`.
        // But `item.key` is dynamic. Defaults to null if not in box.
        // Let's rely on `when(() => mockLocalDataSource.delete(any()))`.

        when(() => mockLocalDataSource.delete(any())).thenAnswer((_) async {});
        when(() => mockRemoteDataSource.deleteMessage(any())).thenAnswer((_) async {});

        // Act
        await repository.deleteById('msg_1');

        // Assert
        verify(() => mockLocalDataSource.delete(any())).called(1);
        verify(() => mockRemoteDataSource.deleteMessage('msg_1')).called(1);
      });

      test('returns failure when offline', () async {
        // Arrange
        when(() => mockConnectivity.isOffline).thenReturn(true);

        // Act
        final result = await repository.deleteById('msg_1');

        // Assert
        expect(result, isA<Failure>());
        verifyNever(() => mockLocalDataSource.delete(any()));
        verifyNever(() => mockRemoteDataSource.deleteMessage(any()));
      });
    });
  });
}
