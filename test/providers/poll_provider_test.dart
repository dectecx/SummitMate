import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:summitmate/providers/poll_provider.dart';
import 'package:summitmate/services/poll_service.dart';
import 'package:summitmate/data/models/poll.dart';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Reuse generated mocks
@GenerateMocks([http.Client, SharedPreferences])
import 'poll_provider_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late MockSharedPreferences mockSharedPreferences;
  late PollProvider provider;

  setUp(() {
    mockClient = MockClient();
    mockSharedPreferences = MockSharedPreferences();
    
    // Register mock SharedPreferences
    final getIt = GetIt.instance;
    if (getIt.isRegistered<SharedPreferences>()) {
      getIt.unregister<SharedPreferences>();
    }
    getIt.registerSingleton<SharedPreferences>(mockSharedPreferences);
    
    // Stub common calls
    when(mockSharedPreferences.getString(any)).thenReturn('test_user_1');

    PollService.client = mockClient;
    provider = PollProvider();
  });

  tearDown(() {
    GetIt.instance.reset(); 
  });

  group('PollProvider', () {
    test('can instantiate', () {
      expect(provider, isNotNull);
      expect(provider.isLoading, false);
    });

    test('fetchPolls success', () async {
      final mockResponse = {
        'success': true,
        'polls': []
      };
      
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      await provider.fetchPolls();
      expect(provider.polls.length, 0);
      expect(provider.error, null);
    });

    test('fetchPolls sets error on failure', () async {
       final mockResponse = {
        'success': false,
        'error': 'Database error'
      };

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      await provider.fetchPolls();

      expect(provider.isLoading, false);
      expect(provider.polls.isEmpty, true);
      expect(provider.error, contains('Database error'));
    });

    test('createPoll calls service and refreshes polls', () async {
      // Setup fetch mocks for the refresh call
      final mockFetchResponse = {'success': true, 'polls': []};
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(json.encode(mockFetchResponse), 200));

      // Setup create match
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(json.encode({'success': true}), 200));

      final result = await provider.createPoll(title: 'New');

      expect(result, true);
      verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      verify(mockClient.get(any)).called(1); // Should call fetchPolls
    });
  });
}
