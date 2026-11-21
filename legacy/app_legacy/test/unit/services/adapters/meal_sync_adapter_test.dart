import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_local_data_source.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_meal_remote_data_source.dart';
import 'package:summitmate/domain/entities/meal_plan_day.dart';
import 'package:summitmate/domain/entities/trip.dart';
import 'package:summitmate/domain/enums/sync_status.dart';
import 'package:summitmate/infrastructure/services/adapters/meal_sync_adapter.dart';

class MockTripLocalDataSource extends Mock implements ITripLocalDataSource {}

class MockTripMealRemoteDataSource extends Mock implements ITripMealRemoteDataSource {}

void main() {
  late MealSyncAdapter adapter;
  late MockTripLocalDataSource mockTripLocal;
  late MockTripMealRemoteDataSource mockRemote;

  setUp(() {
    mockTripLocal = MockTripLocalDataSource();
    mockRemote = MockTripMealRemoteDataSource();
    adapter = MealSyncAdapter(mockTripLocal, mockRemote);
  });

  final sampleTrip = Trip(
    id: 'trip-1',
    userId: 'user-1',
    name: 'Snow Mountain Trek',
    startDate: DateTime(2026, 7, 1),
    createdAt: DateTime(2026, 6, 1),
    createdBy: 'user-1',
    updatedAt: DateTime(2026, 6, 1),
    updatedBy: 'user-1',
    syncStatus: SyncStatus.synced,
  );

  final sampleMealDays = [
    const MealPlanDay(id: 'day-1', name: 'Day 1', linkedItineraryDay: 'Day 1'),
    const MealPlanDay(id: 'day-2', name: 'Day 2', linkedItineraryDay: 'Day 2'),
  ];

  group('MealSyncAdapter - Push operations (no-op)', () {
    test('pushPending returns successful empty result', () async {
      final result = await adapter.pushPending();
      expect(result.isSuccess, isTrue);
      expect(result.pushedCount, 0);
    });

    test('pushPendingForTrip returns successful empty result', () async {
      final result = await adapter.pushPendingForTrip('trip-1');
      expect(result.isSuccess, isTrue);
      expect(result.pushedCount, 0);
    });
  });

  group('MealSyncAdapter - Pull operations', () {
    test('pullRemote pulls meal days for all non-deleted trips and replaces local days', () async {
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [sampleTrip]);
      when(() => mockRemote.getMealPlanDays('trip-1')).thenAnswer((_) async => sampleMealDays);
      when(() => mockTripLocal.replaceMealPlanDays('trip-1', any())).thenAnswer((_) async {});

      final result = await adapter.pullRemote();

      expect(result.isSuccess, isTrue);
      expect(result.pulledCount, 2);
      expect(result.remoteWinsCount, 2);
      verify(() => mockRemote.getMealPlanDays('trip-1')).called(1);
      verify(() => mockTripLocal.replaceMealPlanDays('trip-1', sampleMealDays)).called(1);
    });

    test('pullRemote skips trips with pendingDelete status', () async {
      final pendingDeleteTrip = sampleTrip.copyWith(syncStatus: SyncStatus.pendingDelete);
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [pendingDeleteTrip]);

      final result = await adapter.pullRemote();

      expect(result.isSuccess, isTrue);
      expect(result.pulledCount, 0);
      verifyNever(() => mockRemote.getMealPlanDays(any()));
    });

    test('pullRemoteForTrip pulls and replaces meal days for single trip', () async {
      when(() => mockRemote.getMealPlanDays('trip-1')).thenAnswer((_) async => sampleMealDays);
      when(() => mockTripLocal.replaceMealPlanDays('trip-1', any())).thenAnswer((_) async {});

      final result = await adapter.pullRemoteForTrip('trip-1');

      expect(result.isSuccess, isTrue);
      expect(result.pulledCount, 2);
      verify(() => mockRemote.getMealPlanDays('trip-1')).called(1);
      verify(() => mockTripLocal.replaceMealPlanDays('trip-1', sampleMealDays)).called(1);
    });

    test('pullRemote records error when remote datasource throws', () async {
      when(() => mockTripLocal.getAllTrips()).thenAnswer((_) async => [sampleTrip]);
      when(() => mockRemote.getMealPlanDays('trip-1')).thenThrow(Exception('network error'));

      final result = await adapter.pullRemote();

      expect(result.isSuccess, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('pull 失敗'));
    });
  });
}
