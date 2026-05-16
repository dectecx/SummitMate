import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/di/injection.dart';
import 'package:summitmate/data/datasources/interfaces/i_trip_gear_remote_data_source.dart';
import 'package:summitmate/presentation/cubits/app_error/app_error_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';

class MockTripRepository extends Mock implements ITripRepository {}

class MockAuthService extends Mock implements IAuthService {}

class MockGearRepository extends Mock implements IGearRepository {}

class MockItineraryRepository extends Mock implements IItineraryRepository {}

class MockTripGearRemoteDataSource extends Mock implements ITripGearRemoteDataSource {}

class MockAppErrorCubit extends Mock implements AppErrorCubit {}

void main() {
  late TripCubit tripCubit;
  late MockTripRepository mockTripRepository;
  late MockAuthService mockAuthService;
  late MockGearRepository mockGearRepository;
  late MockItineraryRepository mockItineraryRepository;
  late MockTripGearRemoteDataSource mockTripGearRemoteDataSource;
  late MockAppErrorCubit mockAppErrorCubit;

  setUpAll(() {
    getIt.allowReassignment = true;
  });

  setUp(() {
    mockTripRepository = MockTripRepository();
    mockAuthService = MockAuthService();
    mockGearRepository = MockGearRepository();
    mockItineraryRepository = MockItineraryRepository();
    mockTripGearRemoteDataSource = MockTripGearRemoteDataSource();
    mockAppErrorCubit = MockAppErrorCubit();

    getIt.registerSingleton<AppErrorCubit>(mockAppErrorCubit);

    when(() => mockAuthService.currentUserId).thenReturn('test-user');
    when(() => mockTripRepository.tripUpdateStream).thenAnswer((_) => const Stream<String>.empty());

    tripCubit = TripCubit(
      mockTripRepository,
      mockAuthService,
      mockGearRepository,
      mockItineraryRepository,
      mockTripGearRemoteDataSource,
    );
  });

  tearDown(() {
    tripCubit.close();
  });

  group('TripCubit', () {
    test('initial state is TripInitial', () {
      expect(tripCubit.state, isA<TripInitial>());
    });

    blocTest<TripCubit, TripState>(
      'loadTrips emits [TripLoading, TripLoaded] on success',
      build: () {
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Success([]));
        when(() => mockTripRepository.getActiveTrip(any())).thenAnswer((_) async => Success(null));
        return tripCubit;
      },
      act: (cubit) => cubit.loadTrips(),
      expect: () => [isA<TripLoading>(), isA<TripLoaded>().having((s) => s.trips, 'trips', isEmpty)],
    );

    blocTest<TripCubit, TripState>(
      'loadTrips emits [TripLoading, TripError] on failure',
      build: () {
        final error = Exception('Failed to load');
        when(() => mockTripRepository.getAllTrips(any())).thenAnswer((_) async => Failure(error));
        when(() => mockAppErrorCubit.reportError(any())).thenReturn(false);
        return tripCubit;
      },
      act: (cubit) => cubit.loadTrips(),
      expect: () => [isA<TripLoading>(), isA<TripError>()],
    );
  });
}
