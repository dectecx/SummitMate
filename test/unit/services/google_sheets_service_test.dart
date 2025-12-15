import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:summitmate/services/google_sheets_service.dart';
import 'package:summitmate/data/models/message.dart';

void main() {
  group('GoogleSheetsService Tests', () {
    test('fetchAll should return itinerary and messages on success', () async {
      final mockClient = MockClient((request) async {
        final responseBody = jsonEncode({
          'itinerary': [
            {
              'day': 'D1',
              'name': 'Mountain Lodge',
              'est_time': '11:30',
              'altitude': 2850,
              'distance': 4.3,
              'note': 'Lunch stop',
            }
          ],
          'messages': [
            {
              'uuid': 'test-uuid-1',
              'parent_id': null,
              'user': 'Alex',
              'category': 'Gear',
              'content': 'Test message',
              'timestamp': '2024-12-15T09:00:00Z',
            }
          ],
        });
        return http.Response(responseBody, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final service = GoogleSheetsService(
        client: mockClient,
        baseUrl: 'https://mock.api.com',
      );

      final result = await service.fetchAll();

      expect(result.success, isTrue);
      expect(result.itinerary.length, 1);
      expect(result.itinerary.first.name, 'Mountain Lodge');
      expect(result.messages.length, 1);
      expect(result.messages.first.user, 'Alex');
    });

    test('fetchAll should return error on HTTP failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = GoogleSheetsService(
        client: mockClient,
        baseUrl: 'https://mock.api.com',
      );

      final result = await service.fetchAll();

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('500'));
    });

    test('addMessage should post message data', () async {
      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response('{"success": true}', 200);
      });

      final service = GoogleSheetsService(
        client: mockClient,
        baseUrl: 'https://mock.api.com',
      );

      final message = Message(
        uuid: 'new-uuid',
        user: 'Bob',
        category: 'Plan',
        content: 'Test message',
        timestamp: DateTime(2024, 12, 15, 10, 0),
      );

      final result = await service.addMessage(message);

      expect(result.success, isTrue);
      expect(capturedBody, isNotNull);
      
      final parsedBody = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(parsedBody['action'], 'add_message');
      expect(parsedBody['data']['uuid'], 'new-uuid');
    });

    test('deleteMessage should send delete request', () async {
      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response('{"success": true}', 200);
      });

      final service = GoogleSheetsService(
        client: mockClient,
        baseUrl: 'https://mock.api.com',
      );

      final result = await service.deleteMessage('uuid-to-delete');

      expect(result.success, isTrue);
      
      final parsedBody = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(parsedBody['action'], 'delete_message');
      expect(parsedBody['uuid'], 'uuid-to-delete');
    });

    test('fetchAll should handle network exceptions', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final service = GoogleSheetsService(
        client: mockClient,
        baseUrl: 'https://mock.api.com',
      );

      final result = await service.fetchAll();

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Network error'));
    });
  });
}
