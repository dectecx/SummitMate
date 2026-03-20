import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/trip_gear_remote_data_source.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/infrastructure/clients/network_aware_client.dart';

class MockNetworkAwareClient extends Mock implements NetworkAwareClient {}

void main() {
  late TripGearRemoteDataSource dataSource;
  late MockNetworkAwareClient mockApiClient;

  setUp(() {
    mockApiClient = MockNetworkAwareClient();
    dataSource = TripGearRemoteDataSource(apiClient: mockApiClient);
  });

  final testGear = GearItem(uuid: 'gear-1', name: 'Tent', category: 'Sleep', weight: 2000);

  group('TripGearRemoteDataSource.getTripGear', () {
    test('returns list of gear items on success', () async {
      final tripId = 'trip-1';
      final responseData = [testGear.toJson()];

      when(() => mockApiClient.get('/trips/$tripId/gear')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getTripGear(tripId);

      expect(result.length, 1);
      expect(result[0].name, 'Tent');
    });
  });

  group('TripGearRemoteDataSource CRUD', () {
    test('addTripGear calls post and returns item', () async {
      final tripId = 'trip-1';
      when(() => mockApiClient.post('/trips/$tripId/gear', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: testGear.toJson(),
          statusCode: 201,
        ),
      );

      final result = await dataSource.addTripGear(tripId, testGear);

      expect(result.name, 'Tent');
      verify(() => mockApiClient.post('/trips/$tripId/gear', data: any(named: 'data'))).called(1);
    });

    test('updateTripGear calls put', () async {
      final tripId = 'trip-1';
      when(
        () => mockApiClient.put('/trips/$tripId/gear/${testGear.uuid}', data: any(named: 'data')),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200));

      await dataSource.updateTripGear(tripId, testGear);

      verify(() => mockApiClient.put('/trips/$tripId/gear/${testGear.uuid}', data: any(named: 'data'))).called(1);
    });
  });
}
