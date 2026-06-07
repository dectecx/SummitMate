import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_remote_data_source.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/data/repositories/trip_repository.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/exceptions/offline_exception.dart';

// Mocks
class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockTripRemoteDataSource extends Mock implements ITripRemoteDataSource {}

class MockConnectivityService extends Mock implements IConnectivityService {}

void main() {
  late TripRepository repository;
  late MockTripLocalDataSource mockLocalDataSource;
  late MockTripRemoteDataSource mockRemoteDataSource;
  late MockConnectivityService mockConnectivityService;

  late Trip testTrip;

  setUpAll(() {
    testTrip = Trip(
      id: 'trip_1',
      userId: 'user_1',
      name: 'Test Trip',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'user_1',
      updatedAt: DateTime.now(),
      updatedBy: 'user_1',
    );

    registerFallbackValue(testTrip);
  });

  setUp(() {
    mockLocalDataSource = MockTripLocalDataSource();
    mockRemoteDataSource = MockTripRemoteDataSource();
    mockConnectivityService = MockConnectivityService();
    // Default online behavior
    when(() => mockConnectivityService.isOffline).thenReturn(false);
    repository = TripRepository(mockLocalDataSource, mockRemoteDataSource, mockConnectivityService);
  });

  group('TripRepository', () {
    test('Given TripRepository, When executing, Then getAllTrips delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getAllTrips()).thenAnswer((_) async => [testTrip]);
      final result = await repository.getAllTrips('user_1');
      expect(result, isA<Success>());
      expect((result as Success).value, [testTrip]);
      verify(() => mockLocalDataSource.getAllTrips()).called(1);
    });

    test('Given TripRepository, When executing, Then getTripById delegates to localDataSource', () async {
      when(() => mockLocalDataSource.getTripById('trip_1')).thenAnswer((_) async => testTrip);
      final result = await repository.getTripById('trip_1');
      expect(result, isA<Success>());
      expect((result as Success).value, testTrip);
      verify(() => mockLocalDataSource.getTripById('trip_1')).called(1);
    });

    test('Given TripRepository and trip is pendingCreate, When deleteTrip is called, Then it should call deleteTrip on localDataSource', () async {
      when(() => mockLocalDataSource.getTripById('trip_1')).thenAnswer((_) async => testTrip);
      when(() => mockLocalDataSource.deleteTrip('trip_1')).thenAnswer((_) async => {});
      await repository.deleteTrip('trip_1');
      verify(() => mockLocalDataSource.deleteTrip('trip_1')).called(1);
    });

    test('Given TripRepository and trip is synced, When deleteTrip is called, Then it should update syncStatus to pendingDelete and call updateTrip', () async {
      final syncedTrip = testTrip.copyWith(syncStatus: SyncStatus.synced);
      when(() => mockLocalDataSource.getTripById('trip_1')).thenAnswer((_) async => syncedTrip);
      when(() => mockLocalDataSource.updateTrip(any())).thenAnswer((_) async => {});
      await repository.deleteTrip('trip_1');
      verify(() => mockLocalDataSource.updateTrip(any())).called(1);
    });

    test('Given not found, When calling TripRepository, Then Negative: getTripById returns null', () async {
      when(() => mockLocalDataSource.getTripById('unknown')).thenAnswer((_) async => null);
      final result = await repository.getTripById('unknown');
      expect(result, isA<Success>());
      expect((result as Success).value, isNull);
    });

    test('Given TripRepository, When executing, Then Extreme: getAllTrips handles large number of trips', () async {
      final manyTrips = List.generate(
        100,
        (i) => Trip(
          id: 't_$i',
          userId: 'u1',
          name: 'Trip $i',
          startDate: DateTime.now().add(Duration(days: i)),
          createdAt: DateTime.now(),
          createdBy: 'u1',
          updatedAt: DateTime.now(),
          updatedBy: 'u1',
        ),
      );
      when(() => mockLocalDataSource.getAllTrips()).thenAnswer((_) async => manyTrips);

      final result = await repository.getAllTrips('u1');

      expect(result, isA<Success>());
      final trips = (result as Success).value as List<Trip>;
      expect(trips.length, 100);
      // Repository sorts by startDate DESC
      expect(trips[0].name, 'Trip 99');
    });

    group('Remote Operations Offline Check', () {
      setUp(() {
        when(() => mockConnectivityService.isOffline).thenReturn(true);
      });

      test('Given offline status, When calling getTripMembers, Then it should return Failure with OfflineException', () async {
        final result = await repository.getTripMembers('trip_1');
        expect(result, isA<Failure>());
        final exception = (result as Failure).exception;
        expect(exception, isA<OfflineException>());
        expect((exception as OfflineException).message, '此功能在離線時不可用');
      });

      test('Given offline status, When calling updateMemberRole, Then it should return Failure with OfflineException', () async {
        final result = await repository.updateMemberRole('trip_1', 'user_1', 'member');
        expect(result, isA<Failure>());
        final exception = (result as Failure).exception;
        expect(exception, isA<OfflineException>());
      });

      test('Given offline status, When calling removeMember, Then it should return Failure with OfflineException', () async {
        final result = await repository.removeMember('trip_1', 'user_1');
        expect(result, isA<Failure>());
        final exception = (result as Failure).exception;
        expect(exception, isA<OfflineException>());
      });

      test('Given offline status, When calling addMemberByEmail, Then it should return Failure with OfflineException', () async {
        final result = await repository.addMemberByEmail('trip_1', 'test@test.com');
        expect(result, isA<Failure>());
        final exception = (result as Failure).exception;
        expect(exception, isA<OfflineException>());
      });

      test('Given offline status, When calling searchUserByEmail, Then it should return Failure with OfflineException', () async {
        final result = await repository.searchUserByEmail('test@test.com');
        expect(result, isA<Failure>());
        final exception = (result as Failure).exception;
        expect(exception, isA<OfflineException>());
      });
    });
  });
}
