import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/services/gas_api_client.dart';
import 'package:summitmate/services/trip_cloud_service.dart';

// Mock GasApiClient
class MockGasApiClient extends GasApiClient {
  MockGasApiClient() : super(baseUrl: 'https://mock.url');

  Map<String, dynamic>? expectedResponseData;
  bool shouldFail = false;
  int statusCode = 200;

  @override
  Future<Response> post(Map<String, dynamic> body, {bool requiresAuth = false}) async {
    if (shouldFail) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 500,
        statusMessage: 'Error',
      );
    }

    // Simulate GAS response structure
    final responseData = {
      'code': statusCode == 200 ? '0000' : '9999',
      'message': 'Mock Message',
      'data': expectedResponseData ?? {},
    };

    return Response(
      requestOptions: RequestOptions(path: ''),
      data: responseData,
      statusCode: statusCode,
    );
  }
}

void main() {
  late TripCloudService service;
  late MockGasApiClient mockClient;

  setUp(() {
    mockClient = MockGasApiClient();
    service = TripCloudService(apiClient: mockClient);
  });

  group('TripCloudService', () {
    test('fetchTrips returns success with list of trips', () async {
      mockClient.expectedResponseData = {
        'trips': [
          {
            'id': 'trip1',
            'name': 'Trip 1',
            'start_date': '2025-01-01T00:00:00.000Z',
            'end_date': '2025-01-02T00:00:00.000Z',
            'is_active': true,
          },
        ],
      };

      final result = await service.fetchTrips();

      expect(result.isSuccess, true);
      expect(result.data, isA<List<Trip>>());
      expect(result.data!.length, 1);
      expect(result.data!.first.name, 'Trip 1');
    });

    test('fetchTrips handles empty list', () async {
      mockClient.expectedResponseData = {'trips': []};

      final result = await service.fetchTrips();

      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('addTrip returns success with trip ID', () async {
      // API might return the created ID or just success
      mockClient.expectedResponseData = {'id': 'new_trip_id'};

      final trip = Trip(id: 'temp_id', name: 'New Trip', startDate: DateTime.now());

      final result = await service.uploadTrip(trip);

      expect(result.isSuccess, true);
      expect(result.data, 'new_trip_id');
    });

    test('updateTrip returns success', () async {
      final trip = Trip(id: 't1', name: 'Updated', startDate: DateTime.now());

      final result = await service.updateTrip(trip);

      expect(result.isSuccess, true);
    });

    test('deleteTrip returns success', () async {
      final result = await service.deleteTrip('t1');

      expect(result.isSuccess, true);
    });

    test('Handles HTTP error', () async {
      mockClient.shouldFail = true;

      final result = await service.fetchTrips();

      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('HTTP 500'));
    });
  });
}
