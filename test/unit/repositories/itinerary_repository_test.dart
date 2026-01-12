import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/repositories/itinerary_repository.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';

// Mocks
class MockItineraryLocalDataSource extends Mock implements IItineraryLocalDataSource {}

class MockItineraryRemoteDataSource extends Mock implements IItineraryRemoteDataSource {}

class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  late ItineraryRepository repository;
  late MockItineraryLocalDataSource mockLocalDataSource;
  late MockItineraryRemoteDataSource mockRemoteDataSource;
  late MockConnectivityService mockConnectivityService;

  late ItineraryItem testItem;

  setUp(() {
    mockLocalDataSource = MockItineraryLocalDataSource();
    mockRemoteDataSource = MockItineraryRemoteDataSource();
    mockConnectivityService = MockConnectivityService();
    mockConnectivityService = MockConnectivityService();

    repository = ItineraryRepository(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      connectivity: mockConnectivityService,
    );

    testItem = ItineraryItem(uuid: 'item_1', tripId: 'trip_1', day: 'D1', name: 'Test Point');

    registerFallbackValue(testItem);
  });

  group('ItineraryRepository', () {
    test('init calls localDataSource.init', () async {
      when(() => mockLocalDataSource.init()).thenAnswer((_) async {});
      await repository.init();
      verify(() => mockLocalDataSource.init()).called(1);
    });

    group('addItem', () {
      test('should call localDataSource.add', () async {
        // Arrange
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        // Act
        await repository.addItem(testItem);

        // Assert
        verify(() => mockLocalDataSource.add(testItem)).called(1);
      });
    });

    group('updateItem', () {
      test('should call localDataSource.update', () async {
        // Arrange
        when(() => mockLocalDataSource.update(any(), any())).thenAnswer((_) async {});

        // Act
        await repository.updateItem(testItem.uuid, testItem);

        // Assert
        verify(() => mockLocalDataSource.update(testItem.uuid, testItem)).called(1);
      });
    });

    test('getAllItems delegates to localDataSource', () {
      when(() => mockLocalDataSource.getAll()).thenReturn([testItem]);
      final result = repository.getAllItems();
      expect(result, [testItem]);
      verify(() => mockLocalDataSource.getAll()).called(1);
    });

    // We can add more tests for checkIn, etc., but audit fields are the main focus here.
  });
}
