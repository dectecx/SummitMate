import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/services/permission_service.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';
import 'package:summitmate/presentation/screens/trip_list_screen.dart';

// Mocks
class MockTripCubit extends MockCubit<TripState> implements TripCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockTripCubit mockTripCubit;
  late MockAuthCubit mockAuthCubit;
  late MockPermissionService mockPermissionService;

  setUpAll(() {
    registerFallbackValue(
      Trip(
        id: 'fallback',
        userId: 'user',
        name: 'fallback',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'user',
      ),
    );
    registerFallbackValue(UserProfile(id: 'fallback', email: 'a@a.com', displayName: 'Fallback'));
  });

  setUp(() {
    mockTripCubit = MockTripCubit();
    mockAuthCubit = MockAuthCubit();
    mockPermissionService = MockPermissionService();

    // Setup GetIt
    GetIt.I.registerSingleton<PermissionService>(mockPermissionService);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripCubit>.value(value: mockTripCubit),
        BlocProvider<AuthCubit>.value(value: mockAuthCubit),
      ],
      child: const MaterialApp(home: TripListScreen()),
    );
  }

  testWidgets('Should display loading indicator when state is TripLoading', (tester) async {
    when(
      () => mockAuthCubit.state,
    ).thenReturn(const AuthAuthenticated(userId: 'u1', email: 'test@example.com', userName: 'TestUser'));
    when(() => mockTripCubit.state).thenReturn(const TripLoading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Should display empty state when no trips', (tester) async {
    when(
      () => mockAuthCubit.state,
    ).thenReturn(const AuthAuthenticated(userId: 'u1', email: 'test@example.com', userName: 'TestUser'));
    when(() => mockTripCubit.state).thenReturn(const TripLoaded(trips: []));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Allow UI to settle

    expect(find.text('尚無行程'), findsOneWidget);
    expect(find.text('新增行程'), findsOneWidget);
  });

  testWidgets('Should display list of trips when loaded', (tester) async {
    final trip = Trip(
      id: 't1',
      userId: 'u1',
      name: 'Test Trip 2024',
      startDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now(),
      createdBy: 'u1',
    );

    when(
      () => mockAuthCubit.state,
    ).thenReturn(const AuthAuthenticated(userId: 'u1', email: 'test@example.com', userName: 'TestUser'));
    when(() => mockTripCubit.state).thenReturn(TripLoaded(trips: [trip]));

    // Mock PermissionService
    when(() => mockPermissionService.canEditTripSync(any(), any())).thenReturn(true);
    when(() => mockPermissionService.canDeleteTripSync(any(), any())).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Test Trip 2024'), findsOneWidget);
    expect(find.text('進行中 / 未來行程'), findsOneWidget);
  });
}
