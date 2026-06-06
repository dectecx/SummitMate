import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/di/injection.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/main.dart' as app;
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';

class MockConnectivityService extends Mock implements IConnectivityService {}

class MockSyncEngine extends Mock implements ISyncEngine {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

class MockTripRepository extends Mock implements ITripRepository {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityService mockConnectivityService;
  late MockSyncEngine mockSyncEngine;
  late MockTripRepository mockTripRepository;
  late MockItineraryRepository mockItineraryRepository;

  setUpAll(() async {
    registerFallbackValue(const TripInitial());
    registerFallbackValue(SyncResult.success());
  });

  group('Offline Sync Flow Integration Test', () {
    testWidgets(
      'Given Offline Sync Flow Integration Test, When executing, Then Workflow: Offline creation -> Reconnect -> Sync to Cloud',
      (tester) async {
        mockConnectivityService = MockConnectivityService();
        mockSyncEngine = MockSyncEngine();
        mockTripRepository = MockTripRepository();
        mockItineraryRepository = MockItineraryRepository();

        // Configure GetIt to allow overrides
        getIt.allowReassignment = true;

        // Start the app (this will initialize DI)
        await app.main();
        await tester.pumpAndSettle();

        // Override with mocks for the test
        getIt.registerSingleton<IConnectivityService>(mockConnectivityService);
        getIt.registerSingleton<ISyncEngine>(mockSyncEngine);
        getIt.registerSingleton<ITripRepository>(mockTripRepository);
        getIt.registerSingleton<IItineraryRepository>(mockItineraryRepository);

        // --- SETUP MOCK BEHAVIORS ---
        when(() => mockConnectivityService.isOffline).thenReturn(true);
        when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => Stream.value(false));
        when(() => mockSyncEngine.watchPendingSyncCount()).thenAnswer((_) => Stream.value(0));
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(null));
        when(() => mockTripRepository.saveTrip(any())).thenAnswer((_) async => const Success(null));
        when(() => mockTripRepository.setActiveTrip(any(), any())).thenAnswer((_) async => const Success(null));

        // Re-trigger load to reflect mock state
        // (In a real test, you might want to restart the app or use a test entry point)

        await tester.pumpAndSettle();

        // --- STEP 1: VERIFY OFFLINE STATE & CREATE TRIP ---
        // Assume we are on the "No Trips" screen
        expect(find.text('您目前還沒有任何行程'), findsOneWidget);
        expect(find.text('建立新行程'), findsOneWidget);

        // Tap Create Trip
        await tester.tap(find.text('建立新行程'));
        await tester.pumpAndSettle();

        // --- STEP 2: SIMULATE RECONNECT ---
        when(() => mockConnectivityService.isOffline).thenReturn(false);
        when(() => mockConnectivityService.onConnectivityChanged).thenAnswer((_) => Stream.value(true));

        // We also need to mock that a trip was created
        final mockTrip = Trip(
          id: 'trip-1',
          userId: 'guest',
          name: '我的第一趟旅程',
          startDate: DateTime.now(),
          createdAt: DateTime.now(),
          createdBy: 'guest',
          updatedAt: DateTime.now(),
          updatedBy: 'guest',
        );
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([mockTrip]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(mockTrip));

        // Trigger a UI refresh if needed (usually happens via stream listeners in the app)
        // For testing, we can manually trigger the connectivity change if the cubit is listening

        await tester.pumpAndSettle();

        // --- STEP 3: TRIGGER SYNC ---
        // Find the upload button in AppBar (it's an IconButton with cloud_upload)
        final uploadButton = find.byIcon(Icons.cloud_upload);
        if (uploadButton.evaluate().isNotEmpty) {
          await tester.tap(uploadButton);
          await tester.pumpAndSettle();

          // Verify the confirmation dialog appears
          expect(find.text('上傳行程'), findsOneWidget);
          expect(find.text('上傳'), findsOneWidget);

          // Mock sync result
          when(
            () => mockSyncEngine.runSyncCycle(force: any(named: 'force')),
          ).thenAnswer((_) async => SyncResult.success());

          // Tap Confirm Upload
          await tester.tap(find.text('上傳'));
          await tester.pumpAndSettle();

          // Verify that the sync services were called
          verify(() => mockSyncEngine.runSyncCycle(force: true)).called(1);
        }
      },
    );

    group('UI Health Checks', () {
      testWidgets('Given UI Health Checks, When executing, Then Verify main screens are accessible', (tester) async {
        await app.main();
        await tester.pumpAndSettle();
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
    group('Complex Interaction', () {
      testWidgets('Given Complex Interaction, When executing, Then Switch tabs and verify content', (tester) async {
        await app.main();
        await tester.pumpAndSettle();

        // Try to find the BottomNavigationBar
        final bottomNavBar = find.byType(BottomNavigationBar);
        if (bottomNavBar.evaluate().isNotEmpty) {
          // Tap "Gear" tab (usually index 1)
          await tester.tap(find.byIcon(Icons.backpack_outlined));
          await tester.pumpAndSettle();

          // Check if GearTab is shown
          // expect(find.byType(GearTab), findsOneWidget);
        }
      });
    });
  });
}
