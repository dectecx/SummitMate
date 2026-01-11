import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/data/models/user_profile.dart'; // Assuming UserProfile is here or I need to find it

// Mocks
class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}
class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}
class MockAuthService extends Mock implements IAuthService {}

void main() {
  late TripRepository repository;
  late MockTripLocalDataSource mockLocalDataSource;
  late MockTripRemoteDataSource mockRemoteDataSource;
  late MockAuthService mockAuthService;

  late Trip testTrip;
  late UserProfile testUser;

  setUp(() {
    mockLocalDataSource = MockTripLocalDataSource();
    mockRemoteDataSource = MockTripRemoteDataSource();
    mockAuthService = MockAuthService();
    repository = TripRepository(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      authService: mockAuthService,
    );

    testTrip = Trip(
      id: 'trip_1',
      name: 'Test Trip',
      startDate: DateTime.now(),
    );

    testUser = UserProfile(
      uuid: 'user_1',
      email: 'test@example.com',
      displayName: 'Test User',
      avatar: '🐻',
      isVerified: true,
      role: 'member',
    );
     // Register fallback values for mocktail if needed
    registerFallbackValue(testTrip);
  });

  group('TripRepository', () {
    test('init calls localDataSource.init', () async {
      when(() => mockLocalDataSource.init()).thenAnswer((_) async {});
      
      await repository.init();
      
      verify(() => mockLocalDataSource.init()).called(1);
    });

    group('addTrip', () {
      test('should populate createdBy and updatedBy when user is logged in', () async {
        // Arrange
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockLocalDataSource.addTrip(any())).thenAnswer((_) async {});

        // Act
        await repository.addTrip(testTrip);

        // Assert
        verify(() => mockAuthService.getCachedUserProfile()).called(1);
        final capturedTrip = verify(() => mockLocalDataSource.addTrip(captureAny())).captured.first as Trip;
        
        expect(capturedTrip.createdBy, testUser.email);
        expect(capturedTrip.updatedBy, testUser.email);
      });

      test('should NOT populate createdBy/updatedBy when user is null', () async {
        // Arrange
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => null);
        when(() => mockLocalDataSource.addTrip(any())).thenAnswer((_) async {});

        // Act
        await repository.addTrip(testTrip);

        // Assert
        final capturedTrip = verify(() => mockLocalDataSource.addTrip(captureAny())).captured.first as Trip;
        expect(capturedTrip.createdBy, isNull);
        // updatedBy might be null or default, depending on implementation. In current impl, it shouldn't be set if user is null.
        expect(capturedTrip.updatedBy, isNull);
      });
      
      test('should NOT overwrite existing createdBy', () async {
        // Arrange
        testTrip.createdBy = 'original_creator';
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockLocalDataSource.addTrip(any())).thenAnswer((_) async {});

        // Act
        await repository.addTrip(testTrip);

        // Assert
        final capturedTrip = verify(() => mockLocalDataSource.addTrip(captureAny())).captured.first as Trip;
        expect(capturedTrip.createdBy, 'original_creator');
        expect(capturedTrip.updatedBy, testUser.email); // updatedBy should still update
      });
    });

    group('updateTrip', () {
      test('should populate updatedBy when user is logged in', () async {
        // Arrange
         when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => testUser);
        when(() => mockLocalDataSource.updateTrip(any())).thenAnswer((_) async {});

        // Act
        await repository.updateTrip(testTrip);

        // Assert
        verify(() => mockAuthService.getCachedUserProfile()).called(1);
        final capturedTrip = verify(() => mockLocalDataSource.updateTrip(captureAny())).captured.first as Trip;
        expect(capturedTrip.updatedBy, testUser.email);
      });
    });

    test('getAllTrips delegates to localDataSource', () {
      when(() => mockLocalDataSource.getAllTrips()).thenReturn([testTrip]);
      final result = repository.getAllTrips();
      expect(result, [testTrip]);
      verify(() => mockLocalDataSource.getAllTrips()).called(1);
    });

    test('getTripById delegates to localDataSource', () {
      when(() => mockLocalDataSource.getTripById('trip_1')).thenReturn(testTrip);
      final result = repository.getTripById('trip_1');
      expect(result, testTrip);
      verify(() => mockLocalDataSource.getTripById('trip_1')).called(1);
    });
    
     test('deleteTrip delegates to localDataSource', () async {
      when(() => mockLocalDataSource.deleteTrip('trip_1')).thenAnswer((_) async {});
      await repository.deleteTrip('trip_1');
      verify(() => mockLocalDataSource.deleteTrip('trip_1')).called(1);
    });
  });
}
