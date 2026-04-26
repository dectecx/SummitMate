import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../data/api/services/favorites_api_service.dart';
import '../../data/api/services/gear_library_api_service.dart';
import '../../data/api/services/group_event_api_service.dart';
import '../../data/api/services/itinerary_api_service.dart';
import '../../data/api/services/meal_library_api_service.dart';
import '../../data/api/services/message_api_service.dart';
import '../../data/api/services/poll_api_service.dart';
import '../../data/api/services/trip_api_service.dart';
import '../../data/api/services/trip_gear_api_service.dart';
import '../../data/api/services/trip_meal_api_service.dart';
import '../../data/api/services/user_api_service.dart';

@module
abstract class ApiModule {
  @lazySingleton
  FavoritesApiService getFavoritesApi(Dio dio) => FavoritesApiService(dio);

  @lazySingleton
  GearLibraryApiService getGearLibraryApi(Dio dio) => GearLibraryApiService(dio);

  @lazySingleton
  GroupEventApiService getGroupEventApi(Dio dio) => GroupEventApiService(dio);

  @lazySingleton
  ItineraryApiService getItineraryApi(Dio dio) => ItineraryApiService(dio);

  @lazySingleton
  MealLibraryApiService getMealLibraryApi(Dio dio) => MealLibraryApiService(dio);

  @lazySingleton
  MessageApiService getMessageApi(Dio dio) => MessageApiService(dio);

  @lazySingleton
  PollApiService getPollApi(Dio dio) => PollApiService(dio);

  @lazySingleton
  TripApiService getTripApi(Dio dio) => TripApiService(dio);

  @lazySingleton
  TripGearApiService getTripGearApi(Dio dio) => TripGearApiService(dio);

  @lazySingleton
  TripMealApiService getTripMealApi(Dio dio) => TripMealApiService(dio);

  @lazySingleton
  UserApiService getUserApi(Dio dio) => UserApiService(dio);
}
