import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import 'package:summitmate/domain/entities/itinerary_item.dart';
import 'package:summitmate/data/repositories/itinerary_repository.dart';

// Mocks
class MockItineraryLocalDataSource extends Mock implements IItineraryLocalDataSource {}

class MockItineraryRemoteDataSource extends Mock implements IItineraryRemoteDataSource {}

void main() {
  late ItineraryRepository repository;
  late MockItineraryLocalDataSource mockLocalDataSource;
  late MockItineraryRemoteDataSource mockRemoteDataSource;

  late ItineraryItem testItem;

  setUp(() {
    mockLocalDataSource = MockItineraryLocalDataSource();
    mockRemoteDataSource = MockItineraryRemoteDataSource();

    repository = ItineraryRepository(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );

    testItem = const ItineraryItem(id: 'item_1', tripId: 'trip_1', day: 'D1', name: 'Test Point', estTime: '08:00');

    registerFallbackValue(testItem);
  });

  group('ItineraryRepository', () {
    group('add', () {
      test('should call localDataSource.add', () async {
        // Arrange
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        // Act
        await repository.add(testItem);

        // Assert
        verify(() => mockLocalDataSource.add(any())).called(1);
      });
    });

    group('update', () {
      test('should call localDataSource.update', () async {
        // Arrange
        when(() => mockLocalDataSource.update(any())).thenAnswer((_) async {});

        // Act
        await repository.update(testItem);

        // Assert
        verify(() => mockLocalDataSource.update(any())).called(1);
      });
    });

    test('getByTripId delegates to localDataSource', () {
      when(() => mockLocalDataSource.getByTripId(any())).thenReturn([]);
      final result = repository.getByTripId('trip_1');
      expect(result, isEmpty);
      verify(() => mockLocalDataSource.getByTripId('trip_1')).called(1);
    });

    // We can add more tests for checkIn, etc., but audit fields are the main focus here.
  });
}
