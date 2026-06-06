import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:get_it/get_it.dart';
import 'package:summitmate/presentation/cubits/app_error/app_error_cubit.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockAuthService extends Mock implements IAuthService {}

class MockSyncEngine extends Mock implements ISyncEngine {}

class MockAppErrorCubit extends Mock implements AppErrorCubit {}

void main() {
  late MockTripRepository mockTripRepository;
  late MockAuthService mockAuthService;
  late MockSyncEngine mockSyncEngine;
  late MockAppErrorCubit mockAppErrorCubit;

  setUpAll(() {
    registerFallbackValue(
      Trip(
        id: 'fallback',
        userId: 'u1',
        name: 'fallback',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        createdBy: 'u1',
        updatedAt: DateTime.now(),
        updatedBy: 'u1',
      ),
    );
  });

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockAuthService = MockAuthService();
    mockSyncEngine = MockSyncEngine();
    mockAppErrorCubit = MockAppErrorCubit();

    GetIt.I.reset();

    GetIt.I.registerSingleton<ITripRepository>(mockTripRepository);
    GetIt.I.registerSingleton<IAuthService>(mockAuthService);
    GetIt.I.registerSingleton<ISyncEngine>(mockSyncEngine);
    GetIt.I.registerSingleton<AppErrorCubit>(mockAppErrorCubit);

    when(() => mockAuthService.currentUserId).thenReturn('user-1');
    when(() => mockAppErrorCubit.reportError(any())).thenReturn(false);
    when(() => mockTripRepository.tripUpdateStream).thenAnswer((_) => const Stream<String>.empty());
  });

  group('TripCubit', () {
    final trip1 = Trip(
      id: 'trip1',
      userId: 'user-1',
      name: 'Trip 1',
      startDate: DateTime(2023, 1, 1),
      createdAt: DateTime(2023, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime(2023, 1, 1),
      updatedBy: 'user-1',
      isActive: true,
    );
    final trip2 = Trip(
      id: 'trip2',
      userId: 'user-1',
      name: 'Trip 2',
      startDate: DateTime(2023, 2, 1),
      createdAt: DateTime(2023, 2, 1),
      createdBy: 'user-1',
      updatedAt: DateTime(2023, 2, 1),
      updatedBy: 'user-1',
      isActive: false,
    );

    test('Given TripCubit, When executing, Then initial state is TripInitial', () {
      expect(TripCubit(mockTripRepository, mockAuthService, mockSyncEngine).state, const TripInitial());
    });

    blocTest<TripCubit, TripState>(
      'loadTrips emits TripLoading and TripLoaded',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1, trip2]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        return TripCubit(mockTripRepository, mockAuthService, mockSyncEngine);
      },
      act: (cubit) => cubit.loadTrips(),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
    );

    blocTest<TripCubit, TripState>(
      'addTrip adds trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        when(() => mockTripRepository.saveTrip(any())).thenAnswer((_) async => const Success(null));
        when(() => mockTripRepository.setActiveTrip(any(), any())).thenAnswer((_) async => const Success(null));
        return TripCubit(mockTripRepository, mockAuthService, mockSyncEngine);
      },
      act: (cubit) => cubit.addTrip(name: 'New Trip', startDate: DateTime.now()),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.saveTrip(any())).called(1);
        verify(() => mockTripRepository.setActiveTrip(any(), any())).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'importTrip adds trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        when(() => mockTripRepository.saveTrip(any())).thenAnswer((_) async => const Success(null));
        return TripCubit(mockTripRepository, mockAuthService, mockSyncEngine);
      },
      act: (cubit) => cubit.importTrip(trip2),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.saveTrip(any())).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'setActiveTrip calls repo and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1, trip2]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        when(() => mockTripRepository.setActiveTrip(any(), any())).thenAnswer((_) async => const Success(null));
        return TripCubit(mockTripRepository, mockAuthService, mockSyncEngine);
      },
      act: (cubit) => cubit.setActiveTrip('trip2'),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.setActiveTrip(any(), 'trip2')).called(1);
      },
    );

    blocTest<TripCubit, TripState>(
      'deleteTrip deletes trip and reloads',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip2]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(null));
        when(() => mockTripRepository.deleteTrip(any())).thenAnswer((_) async => const Success(null));
        return TripCubit(mockTripRepository, mockAuthService, mockSyncEngine);
      },
      seed: () => TripLoaded(trips: [trip1, trip2], activeTrip: trip2),
      act: (cubit) => cubit.deleteTrip('trip1'),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.deleteTrip('trip1')).called(1);
      },
    );

    test('Given failure, When calling TripCubit, Then loadTrips emits TripError', () async {
      when(
        () => mockTripRepository.getAllTrips(any()),
      ).thenAnswer((_) async => Failure(GeneralException('Load failed')));

      final cubit = TripCubit(mockTripRepository, mockAuthService, mockSyncEngine);

      expectLater(cubit.stream, emitsInOrder([const TripLoading(), isA<TripError>()]));

      await cubit.loadTrips();
      await cubit.close();
    });
  });
}
