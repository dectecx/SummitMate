import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/di/injection.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/main.dart' as app;
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockSyncEngine extends Mock implements ISyncEngine {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockAuthService extends Mock implements IAuthService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityService mockConnectivityService;
  late MockSyncEngine mockSyncEngine;
  late MockTripRepository mockTripRepository;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(const TripInitial());
    registerFallbackValue(SyncResult.success());
  });

  group('SummitMate Smoke Test (Full App Walkthrough)', () {
    testWidgets(
      'Given SummitMate Smoke Test (Full App Walkthrough), When executing, Then Guest User Flow: Login -> Guest Login -> Welcome -> Settings',
      (tester) async {
        mockConnectivityService = MockConnectivityService();
        mockSyncEngine = MockSyncEngine();
        mockTripRepository = MockTripRepository();
        mockAuthService = MockAuthService();

        getIt.allowReassignment = true;

        await app.main();
        await tester.pumpAndSettle();

        // Override dependencies
        getIt.registerSingleton<IConnectivityService>(mockConnectivityService);
        getIt.registerSingleton<ISyncEngine>(mockSyncEngine);
        getIt.registerSingleton<ITripRepository>(mockTripRepository);
        getIt.registerSingleton<IAuthService>(mockAuthService);

        // --- MOCK SETUP ---
        when(() => mockAuthService.onAuthStateChanged).thenAnswer((_) => const Stream.empty());
        when(() => mockAuthService.currentUserId).thenReturn(null);
        when(() => mockConnectivityService.isOffline).thenReturn(false);
        when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => Stream.value(true));
        when(() => mockSyncEngine.watchPendingSyncCount()).thenAnswer((_) => Stream.value(0));
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(null));

        await tester.pumpAndSettle();

        // 1. Login screen offers guest mode
        final guestButton = find.text('以訪客身分繼續');
        expect(guestButton, findsOneWidget);

        // 2. Guest login: confirm the dialog
        await tester.tap(guestButton);
        await tester.pumpAndSettle();
        expect(find.text('訪客模式'), findsOneWidget);
        await tester.tap(find.text('繼續'));
        await tester.pumpAndSettle();

        // 3. With no trips, the welcome screen is shown
        expect(find.text('歡迎使用 SummitMate'), findsOneWidget);
        expect(find.text('您目前還沒有任何行程'), findsOneWidget);
        expect(find.text('建立新行程'), findsOneWidget);

        // 4. Open the settings dialog
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        expect(find.text('設定'), findsOneWidget);

        // 5. Close it and land back on the welcome screen
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('歡迎使用 SummitMate'), findsOneWidget);
      },
    );
  });
}
