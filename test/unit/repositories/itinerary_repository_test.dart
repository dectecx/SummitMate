import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_itinerary_remote_data_source.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/models/user_profile.dart'; // Correct import
import 'package:summitmate/data/repositories/itinerary_repository.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/domain/interfaces/i_connectivity_service.dart';

// Mocks
class MockItineraryLocalDataSource extends Mock implements IItineraryLocalDataSource {}

class MockItineraryRemoteDataSource extends Mock implements IItineraryRemoteDataSource {}

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  late ItineraryRepository repository;
  late MockItineraryLocalDataSource mockLocalDataSource;
  late MockItineraryRemoteDataSource mockRemoteDataSource;
  late MockConnectivityService mockConnectivityService;
  late MockAuthService mockAuthService;

  late ItineraryItem testItem;
  late UserProfile testUser;

  setUp(() {
    mockLocalDataSource = MockItineraryLocalDataSource();
    mockRemoteDataSource = MockItineraryRemoteDataSource();
    mockConnectivityService = MockConnectivityService();
    mockAuthService = MockAuthService();

    repository = ItineraryRepository(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      connectivity: mockConnectivityService,
      authService: mockAuthService,
    );

    testItem = ItineraryItem(uuid: 'item_1', tripId: 'trip_1', day: 'D1', name: 'Test Point');

    testUser = UserProfile(
      uuid: 'user_1',
      email: 'test@example.com',
      displayName: 'Test User',
      avatar: '🐻',
      isVerified: true,
      role: 'member',
    );

    registerFallbackValue(testItem);
  });

  group('ItineraryRepository', () {
    test('init calls localDataSource.init', () async {
      when(() => mockLocalDataSource.init()).thenAnswer((_) async {});
      await repository.init();
      verify(() => mockLocalDataSource.init()).called(1);
    });

    group('addItem', () {
      test('should populate createdBy and updatedBy when user is logged in', () async {
        // Arrange
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        // Act
        await repository.addItem(testItem);

        // Assert
        verify(() => mockAuthService.getCachedUserProfile()).called(1);
        final capturedItem = verify(() => mockLocalDataSource.add(captureAny())).captured.first as ItineraryItem;

        expect(capturedItem.createdBy, testUser.email);
        expect(capturedItem.updatedBy, testUser.email);
      });

      test('should NOT populate createdBy/updatedBy when user is null', () async {
        // Arrange
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => null);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        // Act
        await repository.addItem(testItem);

        // Assert
        final capturedItem = verify(() => mockLocalDataSource.add(captureAny())).captured.first as ItineraryItem;
        expect(capturedItem.createdBy, isNull);
        expect(capturedItem.updatedBy, isNull);
      });

      test('should NOT overwrite existing createdBy', () async {
        // Arrange
        testItem.createdBy = 'original_creator';
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockLocalDataSource.add(any())).thenAnswer((_) async {});

        // Act
        await repository.addItem(testItem);

        // Assert
        final capturedItem = verify(() => mockLocalDataSource.add(captureAny())).captured.first as ItineraryItem;
        expect(capturedItem.createdBy, 'original_creator');
        expect(capturedItem.updatedBy, testUser.email); // updatedBy should still update
      });
    });

    group('updateItem', () {
      test('should populate updatedBy when user is logged in', () async {
        // Arrange
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockLocalDataSource.update(any(), any())).thenAnswer((_) async {});

        // Act
        await repository.updateItem(testItem.uuid, testItem);

        // Assert
        verify(() => mockAuthService.getCachedUserProfile()).called(1);
        final capturedItem =
            verify(() => mockLocalDataSource.update(any(), captureAny())).captured.first as ItineraryItem;
        expect(capturedItem.updatedBy, testUser.email);
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
