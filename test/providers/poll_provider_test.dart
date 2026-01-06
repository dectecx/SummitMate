import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/presentation/providers/poll_provider.dart';
import 'package:summitmate/services/poll_service.dart';
import 'package:summitmate/data/repositories/interfaces/i_poll_repository.dart';
import 'package:summitmate/data/repositories/interfaces/i_settings_repository.dart';
import 'package:summitmate/data/models/settings.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summitmate/services/gas_api_client.dart';

// Mocks
class MockDio extends Mock implements Dio {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockPollRepository extends Mock implements IPollRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}

class MockSettings extends Mock implements Settings {}

void main() {
  late MockDio mockDio;
  late MockSharedPreferences mockSharedPreferences;
  late MockPollRepository mockPollRepository;
  late MockSettingsRepository mockSettingsRepository;
  late MockSettings mockSettings;
  late PollProvider provider;

  setUp(() async {
    mockDio = MockDio();
    mockSharedPreferences = MockSharedPreferences();
    mockPollRepository = MockPollRepository();
    mockSettingsRepository = MockSettingsRepository();
    mockSettings = MockSettings();

    // Register mocks via GetIt
    final getIt = GetIt.instance;
    await getIt.reset();

    final gasApiClient = GasApiClient(dio: mockDio, baseUrl: 'https://mock.api');

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
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
    registerFallbackValue(<String, dynamic>{});

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
      final mockResponseData = {
        'code': '0000',
        'data': {'polls': []},
      };

      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: mockResponseData,
          statusCode: 200,
        ),
      );

      await provider.fetchPolls();
      expect(provider.polls.length, 0);
      expect(provider.error, null);
    });

    testWidgets('fetchPolls sets error on failure', (tester) async {
      final mockResponseData = {'code': '9999', 'message': 'Database error'};

      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: mockResponseData,
          statusCode: 200,
        ),
      );

      await provider.fetchPolls();

      expect(provider.isLoading, false);
      expect(provider.polls.isEmpty, true);
      expect(provider.error, contains('Database error'));
    });

    testWidgets('createPoll calls service and refreshes polls', (tester) async {
      // Setup fetch mocks for the refresh call
      final mockFetchResponse = {
        'code': '0000',
        'data': {'polls': []},
      };
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: mockFetchResponse,
          statusCode: 200,
        ),
      );

      // Setup create match
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'code': '0000', 'message': 'Success'},
          statusCode: 200,
        ),
      );

      final result = await provider.createPoll(title: 'New');

      expect(result, true);
      verify(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
      verify(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).called(1); // Should call fetchPolls
    });
  });
}
