import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
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

    repository = ItineraryRepository(localDataSource: mockLocalDataSource, remoteDataSource: mockRemoteDataSource);

    testItem = const ItineraryItem(id: 'item_1', tripId: 'trip_1', day: 'D1', name: 'Test Point', estTime: '08:00');

    registerFallbackValue(testItem);
  });

  group('ItineraryRepository', () {
    group('add', () {
      test('should call localDataSource.addItem', () async {
        // Arrange
        when(() => mockLocalDataSource.addItem(any())).thenAnswer((_) async => {});

        // Act
        await repository.add(testItem);

        // Assert
        verify(() => mockLocalDataSource.addItem(any())).called(1);
      });
    });

    group('update', () {
      test('should call localDataSource.updateItem', () async {
        // Arrange
        when(() => mockLocalDataSource.updateItem(any())).thenAnswer((_) async => {});

        // Act
        await repository.update(testItem);

        // Assert
        verify(() => mockLocalDataSource.updateItem(any())).called(1);
      });
    });

    test('getByTripId delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getByTripId(any())).thenAnswer((_) async => []);
      final result = await repository.getByTripId('trip_1');
      expect(result, isEmpty);
      verify(() => mockLocalDataSource.getByTripId('trip_1')).called(1);
    });
  });
}
