import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_state.dart';
import '../../core/providers.dart';
import 'data/weather_repository.dart';
import 'domain/weather_models.dart';

final weatherApiProvider = Provider<WeatherApi>((ref) => DioWeatherApi(ref.watch(authedDioProvider)));
final weatherRepositoryProvider = Provider((ref) => WeatherRepository(ref.watch(appDatabaseProvider), ref.watch(weatherApiProvider)));

final weatherProvider = StreamProvider.family<WeatherState, WeatherQuery>((ref, query) {
  final auth = ref.watch(authStateProvider).value ?? ref.watch(authRepositoryProvider).state;
  return ref.watch(weatherRepositoryProvider).watch(query, signedIn: auth is SignedIn);
});
