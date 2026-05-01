import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/domain/interfaces/i_sync_service.dart';

import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';
import 'package:summitmate/core/error/result.dart';

import 'package:summitmate/domain/interfaces/i_auth_service.dart';

import 'package:get_it/get_it.dart';
import 'package:summitmate/domain/repositories/i_itinerary_repository.dart';
import 'package:summitmate/domain/repositories/i_gear_repository.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_gear_remote_data_source.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockSyncService extends Mock implements ISyncService {}

class MockAuthService extends Mock implements IAuthService {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockTripGearRemoteDataSource extends Mock implements ITripGearRemoteDataSource {}

void main() {
  late MockTripRepository mockTripRepository;
  late MockAuthService mockAuthService;
  late MockItineraryRepository mockItineraryRepository;
  late MockGearRepository mockGearRepository;
  late MockTripGearRemoteDataSource mockTripGearRemoteDataSource;

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
    mockItineraryRepository = MockItineraryRepository();
    mockGearRepository = MockGearRepository();
    mockTripGearRemoteDataSource = MockTripGearRemoteDataSource();

    GetIt.I.reset();

    GetIt.I.registerSingleton<IItineraryRepository>(mockItineraryRepository);
    GetIt.I.registerSingleton<IGearRepository>(mockGearRepository);
    GetIt.I.registerSingleton<ITripGearRemoteDataSource>(mockTripGearRemoteDataSource);
    GetIt.I.registerSingleton<ITripRepository>(mockTripRepository);
    GetIt.I.registerSingleton<IAuthService>(mockAuthService);

    when(() => mockAuthService.currentUserId).thenReturn('user-1');
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

    test('initial state is TripInitial', () {
      expect(TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource).state, const TripInitial());
    });

    blocTest<TripCubit, TripState>(
      'loadTrips emits TripLoading and TripLoaded',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([trip1, trip2]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(trip1));
        return TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);
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
        return TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);
      },
      act: (cubit) => cubit.addTrip(name: 'New Trip', startDate: DateTime.now()),
      expect: () => [
        const TripLoading(),
        const TripLoading(),
        isA<TripLoaded>(),
      ],
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
        return TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);
      },
      act: (cubit) => cubit.importTrip(trip2),
      expect: () => [const TripLoading(), const TripLoading(), isA<TripLoaded>()],
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
        return TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);
      },
      act: (cubit) => cubit.setActiveTrip('trip2'),
      expect: () => [const TripLoading(), const TripLoading(), isA<TripLoaded>()],
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
        return TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);
      },
      seed: () => TripLoaded(trips: [trip1, trip2], activeTrip: trip2),
      act: (cubit) => cubit.deleteTrip('trip1'),
      expect: () => [const TripLoading(), isA<TripLoaded>()],
      verify: (_) {
        verify(() => mockTripRepository.deleteTrip('trip1')).called(1);
      },
    );

    test('uploadFullTrip gathers data and calls repo', () async {
      when(() => mockGearRepository.getAllItems()).thenReturn([]);
      when(() => mockTripRepository.uploadToCloud(any())).thenAnswer((_) async => const Success('mock-id'));
      when(() => mockItineraryRepository.sync(any())).thenAnswer((_) async => const Success(null));
      when(() => mockTripGearRemoteDataSource.replaceAllTripGear(any(), any())).thenAnswer((_) async => Future.value());

      final cubit = TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);

      final result = await cubit.uploadFullTrip(trip1);

      expect(result, true);
      verify(() => mockTripRepository.uploadToCloud(trip1)).called(1);
      verify(() => mockItineraryRepository.sync('trip1')).called(1);
    });

    test('loadTrips emits TripError on failure', () async {
      when(
        () => mockTripRepository.getAllTrips(any()),
      ).thenAnswer((_) async => Failure(GeneralException('Load failed')));

      final cubit = TripCubit(mockTripRepository, mockAuthService, mockGearRepository, mockItineraryRepository, mockTripGearRemoteDataSource);

      expectLater(cubit.stream, emitsInOrder([const TripLoading(), isA<TripError>()]));

      await cubit.loadTrips();
      await cubit.close();
    });
  });
}
