import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/trip_gear_api_models.dart';
import 'package:summitmate/data/api/services/trip_gear_api_service.dart';
import 'package:summitmate/data/datasources/remote/trip_gear_remote_data_source.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/domain/entities/gear_item.dart';

class MockTripGearApiService extends Mock implements TripGearApiService {}

class FakeTripGearItemRequest extends Fake implements TripGearItemRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTripGearItemRequest());
  });

  late TripGearRemoteDataSource dataSource;
  late MockTripGearApiService mockApiService;

  setUp(() {
    mockApiService = MockTripGearApiService();
    // 注入測試用 Dio（不會被真正使用，因為 ApiService 已 mock）
    dataSource = TripGearRemoteDataSource(mockApiService);
  });

  final testResponse = TripGearItemResponse(
    id: 'gear-1',
    tripId: 'trip-1',
    name: 'Tent',
    category: 'Sleep',
    weight: 2000,
    quantity: 1,
    isChecked: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final testItem = GearItem(id: 'gear-1', name: 'Tent', category: 'Sleep', weight: 2000);

  group('TripGearRemoteDataSource.getTripGear', () {
    test('returns list of gear items on success', () async {
      when(() => mockApiService.listGear('trip-1')).thenAnswer((_) async => [testResponse]);

      final result = await dataSource.getTripGear('trip-1');

      expect(result.length, 1);
      expect(result[0].name, 'Tent');
      verify(() => mockApiService.listGear('trip-1')).called(1);
    });

    test('rethrows exception on failure', () async {
      when(() => mockApiService.listGear(any())).thenThrow(Exception('Network error'));

      expect(() => dataSource.getTripGear('trip-1'), throwsException);
    });
  });

  group('TripGearRemoteDataSource CRUD', () {
    test('addTripGear calls api and returns mapped item', () async {
      when(() => mockApiService.addGear('trip-1', any())).thenAnswer((_) async => testResponse);

      final result = await dataSource.addTripGear('trip-1', testItem);

      expect(result.name, 'Tent');
      verify(() => mockApiService.addGear('trip-1', any())).called(1);
    });

    test('updateTripGear calls api and returns mapped item', () async {
      when(() => mockApiService.updateGear('trip-1', 'gear-1', any())).thenAnswer((_) async => testResponse);

      final result = await dataSource.updateTripGear('trip-1', testItem);

      expect(result.name, 'Tent');
      verify(() => mockApiService.updateGear('trip-1', 'gear-1', any())).called(1);
    });

    test('deleteTripGear calls api', () async {
      when(() => mockApiService.deleteGear('trip-1', 'gear-1')).thenAnswer((_) async {});

      await dataSource.deleteTripGear('trip-1', 'gear-1');

      verify(() => mockApiService.deleteGear('trip-1', 'gear-1')).called(1);
    });

    test('replaceAllTripGear calls api with mapped requests', () async {
      when(() => mockApiService.replaceAllGear('trip-1', any())).thenAnswer((_) async {});

      await dataSource.replaceAllTripGear('trip-1', [testItem]);

      verify(() => mockApiService.replaceAllGear('trip-1', any())).called(1);
    });
  });
}
