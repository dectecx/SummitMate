import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/presentation/providers/poll_provider.dart';
import 'package:summitmate/services/poll_service.dart';
import 'package:summitmate/data/models/poll.dart';
import 'package:summitmate/data/repositories/interfaces/i_poll_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_settings_repository.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:summitmate/services/gas_api_client.dart';

// Mocks
class MockClient extends Mock implements http.Client {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockPollRepository extends Mock implements IPollRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockSettings extends Mock implements Settings {}

void main() {
  late MockClient mockClient;
  late MockSharedPreferences mockSharedPreferences;
  late MockPollRepository mockPollRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockSettings mockSettings;
  late PollProvider provider;

  setUp(() async {
    mockClient = MockClient();
    mockSharedPreferences = MockSharedPreferences();
    mockPollRepository = MockPollRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockSettings = MockSettings();

    // Register mocks via GetIt
    final getIt = GetIt.instance;
    await getIt.reset();

    final gasApiClient = GasApiClient(client: mockClient, baseUrl: 'https://mock.api');

    getIt.registerSingleton<SharedPreferences>(mockSharedPreferences);
    getIt.registerSingleton<PollService>(PollService(apiClient: gasApiClient));
    getIt.registerSingleton<IPollRepository>(mockPollRepository);
    getIt.registerSingleton<ISettingsRepository>(mockSettingsRepository);

    // Stub common calls
    when(() => mockSharedPreferences.getString(any())).thenReturn('test_user_1');
    when(() => mockSettingsRepository.getSettings()).thenReturn(mockSettings);
    when(() => mockSettings.isOfflineMode).thenReturn(false);

    // Stub PollRepository calls needed by constructor
    when(() => mockPollRepository.getAllPolls()).thenReturn([]);
    when(() => mockPollRepository.getLastSyncTime()).thenReturn(null);
    when(() => mockPollRepository.savePolls(any())).thenAnswer((_) async {});
    when(() => mockPollRepository.saveLastSyncTime(any())).thenAnswer((_) async {});

    // Register fallback values
    registerFallbackValue(Uri());

    provider = PollProvider();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('PollProvider', () {
    testWidgets('can instantiate', (tester) async {
      expect(provider, isNotNull);
      expect(provider.isLoading, false);
    });

    testWidgets('fetchPolls success', (tester) async {
      final mockResponse = {'success': true, 'polls': []};

      // PollService uses GasApiClient which calls _client.get(uri) WITHOUT headers
      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      await provider.fetchPolls();
      expect(provider.polls.length, 0);
      expect(provider.error, null);
    });

    testWidgets('fetchPolls sets error on failure', (tester) async {
      final mockResponse = {'success': false, 'error': 'Database error'};

      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

      await provider.fetchPolls();

      expect(provider.isLoading, false);
      expect(provider.polls.isEmpty, true);
      // Note: PollProvider catches error and sets it, but also shows toast.
      // ToastService is static, assume it handles itself or we might need to mock it if it crashes.
      // But PollProvider code: _error = e.toString();
      expect(provider.error, contains('Database error'));
    });

    testWidgets('createPoll calls service and refreshes polls', (tester) async {
      // Setup fetch mocks for the refresh call
      final mockFetchResponse = {'success': true, 'polls': []};
      when(() => mockClient.get(any())).thenAnswer((_) async => http.Response(json.encode(mockFetchResponse), 200));

      // Setup create match
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode({'success': true}), 200));

      final result = await provider.createPoll(title: 'New');

      expect(result, true);
      verify(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
      verify(() => mockClient.get(any())).called(1); // Should call fetchPolls
    });
  });
}
