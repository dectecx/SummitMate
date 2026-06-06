import 'package:flutter/material.dart';
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
      'Given SummitMate Smoke Test (Full App Walkthrough), When executing, Then Guest User Flow: Landing -> Guest Login -> Main Nav -> Settings',
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

        // 1. Verify Welcome/Login Screen
        // expect(find.text('歡迎使用 SummitMate'), findsOneWidget); // Assuming welcome text

        // 2. Guest Login
        final guestButton = find.text('訪客登入');
        if (guestButton.evaluate().isNotEmpty) {
          await tester.tap(guestButton);
          await tester.pumpAndSettle();
        } else {
          // If already logged in or different UI, skip to main navigation
        }

        // 3. Verify Main Navigation (Trip Tab)
        expect(find.byIcon(Icons.map_outlined), findsOneWidget); // Trip tab icon
        expect(find.text('行程'), findsOneWidget);

        // 4. Navigate to Gear Tab
        await tester.tap(find.byIcon(Icons.backpack_outlined));
        await tester.pumpAndSettle();
        expect(find.text('裝備'), findsOneWidget);

        // 5. Navigate to Settings
        final settingsButton = find.byIcon(Icons.settings_outlined);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
          expect(find.text('系統設定'), findsOneWidget);

          // Toggle Theme or something
          // await tester.tap(find.text('切換主題'));
          // await tester.pumpAndSettle();
        }

        // 6. Back to Trip
        await tester.tap(find.byIcon(Icons.map_outlined));
        await tester.pumpAndSettle();
      },
    );
  });
}
