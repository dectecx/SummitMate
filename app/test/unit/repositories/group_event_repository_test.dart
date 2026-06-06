import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/data/datasources/interfaces/i_group_event_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_group_event_remote_data_source.dart';
import 'package:summitmate/data/repositories/group_event_repository.dart';
import 'package:summitmate/domain/domain.dart';

class MockGroupEventLocalDataSource extends Mock implements IGroupEventLocalDataSource {}

class MockGroupEventRemoteDataSource extends Mock implements IGroupEventRemoteDataSource {}

void main() {
  late GroupEventRepository repository;
  late MockGroupEventLocalDataSource mockLocalDataSource;
  late MockGroupEventRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockGroupEventLocalDataSource();
    mockRemoteDataSource = MockGroupEventRemoteDataSource();
    repository = GroupEventRepository(mockLocalDataSource, mockRemoteDataSource);
  });

  group('GroupEventRepository.syncMyEvents', () {
    final tEvent = GroupEvent(
      id: 'evt-1',
      hostId: 'u1',
      title: 'My Event',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'u1',
      updatedAt: DateTime.now(),
      updatedBy: 'u1',
    );

    final tPaginatedList = PaginatedList<GroupEvent>(items: [tEvent], page: 1, total: 1, hasMore: false);

    test(
      'Given success, When calling GroupEventRepository.syncMyEvents, Then it should sync my events from remote and save to local',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getMyEvents(
            type: any(named: 'type'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(tPaginatedList));
        when(() => mockLocalDataSource.saveEvents(any())).thenAnswer((_) async {});

        // Act
        final result = await repository.syncMyEvents(type: 'host', page: 1, limit: 10);

        // Assert
        expect(result, isA<Success<PaginatedList<GroupEvent>, Exception>>());
        expect((result as Success).value, tPaginatedList);

        verify(() => mockRemoteDataSource.getMyEvents(type: 'host', page: 1, limit: 10)).called(1);
        verify(() => mockLocalDataSource.saveEvents([tEvent])).called(1);
      },
    );

    test(
      'Given remote sync fails, When calling GroupEventRepository.syncMyEvents, Then it should return failure',
      () async {
        // Arrange
        final tException = Exception('Remote Error');
        when(
          () => mockRemoteDataSource.getMyEvents(
            type: any(named: 'type'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Failure(tException));

        // Act
        final result = await repository.syncMyEvents(type: 'host');

        // Assert
        expect(result, isA<Failure<PaginatedList<GroupEvent>, Exception>>());
        expect((result as Failure).exception, tException);
        verifyNever(() => mockLocalDataSource.saveEvents(any()));
      },
    );

    test(
      'Given exception occurs, When calling GroupEventRepository.syncMyEvents, Then it should return failure',
      () async {
        // Arrange
        when(
          () => mockRemoteDataSource.getMyEvents(
            type: any(named: 'type'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('Unexpected Error'));

        // Act
        final result = await repository.syncMyEvents(type: 'host');

        // Assert
        expect(result, isA<Failure<PaginatedList<GroupEvent>, Exception>>());
      },
    );
  });
}
