// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;
import 'package:package_info_plus/package_info_plus.dart' as _i655;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/api/services/favorites_api_service.dart' as _i1035;
import '../../data/api/services/gear_library_api_service.dart' as _i83;
import '../../data/api/services/group_event_api_service.dart' as _i912;
import '../../data/api/services/itinerary_api_service.dart' as _i100;
import '../../data/api/services/meal_library_api_service.dart' as _i458;
import '../../data/api/services/message_api_service.dart' as _i367;
import '../../data/api/services/poll_api_service.dart' as _i245;
import '../../data/api/services/trip_api_service.dart' as _i1030;
import '../../data/api/services/trip_gear_api_service.dart' as _i9;
import '../../data/api/services/trip_meal_api_service.dart' as _i579;
import '../../data/api/services/user_api_service.dart' as _i716;
import '../../data/cwa/cwa_weather_source.dart' as _i455;
import '../../data/datasources/interfaces/i_auth_session_local_data_source.dart'
    as _i26;
import '../../data/datasources/interfaces/i_favorites_local_data_source.dart'
    as _i307;
import '../../data/datasources/interfaces/i_favorites_remote_data_source.dart'
    as _i342;
import '../../data/datasources/interfaces/i_gear_key_local_data_source.dart'
    as _i484;
import '../../data/datasources/interfaces/i_gear_library_local_data_source.dart'
    as _i240;
import '../../data/datasources/interfaces/i_gear_library_remote_data_source.dart'
    as _i31;
import '../../data/datasources/interfaces/i_gear_local_data_source.dart'
    as _i691;
import '../../data/datasources/interfaces/i_group_event_local_data_source.dart'
    as _i529;
import '../../data/datasources/interfaces/i_group_event_remote_data_source.dart'
    as _i25;
import '../../data/datasources/interfaces/i_itinerary_local_data_source.dart'
    as _i116;
import '../../data/datasources/interfaces/i_itinerary_remote_data_source.dart'
    as _i307;
import '../../data/datasources/interfaces/i_message_local_data_source.dart'
    as _i21;
import '../../data/datasources/interfaces/i_message_remote_data_source.dart'
    as _i880;
import '../../data/datasources/interfaces/i_poll_local_data_source.dart'
    as _i930;
import '../../data/datasources/interfaces/i_poll_remote_data_source.dart'
    as _i644;
import '../../data/datasources/interfaces/i_settings_local_data_source.dart'
    as _i393;
import '../../data/datasources/interfaces/i_trip_gear_remote_data_source.dart'
    as _i725;
import '../../data/datasources/interfaces/i_trip_local_data_source.dart'
    as _i774;
import '../../data/datasources/interfaces/i_trip_meal_remote_data_source.dart'
    as _i999;
import '../../data/datasources/interfaces/i_trip_remote_data_source.dart'
    as _i941;
import '../../data/datasources/interfaces/i_user_remote_data_source.dart'
    as _i1050;
import '../../data/datasources/local/auth_session_local_data_source.dart'
    as _i4;
import '../../data/datasources/local/favorites_local_data_source.dart' as _i19;
import '../../data/datasources/local/gear_key_local_data_source.dart' as _i835;
import '../../data/datasources/local/gear_library_local_data_source.dart'
    as _i1068;
import '../../data/datasources/local/gear_local_data_source.dart' as _i316;
import '../../data/datasources/local/group_event_local_data_source.dart'
    as _i903;
import '../../data/datasources/local/itinerary_local_data_source.dart' as _i130;
import '../../data/datasources/local/message_local_data_source.dart' as _i783;
import '../../data/datasources/local/poll_local_data_source.dart' as _i432;
import '../../data/datasources/local/settings_local_data_source.dart' as _i179;
import '../../data/datasources/local/trip_local_data_source.dart' as _i688;
import '../../data/datasources/remote/fake_gear_cloud_service.dart' as _i699;
import '../../data/datasources/remote/favorites_remote_data_source.dart'
    as _i168;
import '../../data/datasources/remote/gear_library_remote_data_source.dart'
    as _i781;
import '../../data/datasources/remote/group_event_remote_data_source.dart'
    as _i959;
import '../../data/datasources/remote/itinerary_remote_data_source.dart'
    as _i636;
import '../../data/datasources/remote/message_remote_data_source.dart'
    as _i1017;
import '../../data/datasources/remote/poll_remote_data_source.dart' as _i621;
import '../../data/datasources/remote/trip_gear_remote_data_source.dart'
    as _i391;
import '../../data/datasources/remote/trip_meal_remote_data_source.dart'
    as _i829;
import '../../data/datasources/remote/trip_remote_data_source.dart' as _i989;
import '../../data/datasources/remote/user_remote_data_source.dart' as _i41;
import '../../data/repositories/auth_session_repository.dart' as _i395;
import '../../data/repositories/favorites_repository.dart' as _i803;
import '../../data/repositories/gear_library_repository.dart' as _i540;
import '../../data/repositories/gear_repository.dart' as _i867;
import '../../data/repositories/gear_set_repository.dart' as _i536;
import '../../data/repositories/group_event_repository.dart' as _i354;
import '../../data/repositories/itinerary_repository.dart' as _i790;
import '../../data/repositories/message_repository.dart' as _i1040;
import '../../data/repositories/poll_repository.dart' as _i222;
import '../../data/repositories/settings_repository.dart' as _i373;
import '../../data/repositories/trip_repository.dart' as _i564;
import '../../domain/domain.dart' as _i614;
import '../../domain/interfaces/i_ad_service.dart' as _i730;
import '../../domain/interfaces/i_api_client.dart' as _i418;
import '../../domain/interfaces/i_auth_service.dart' as _i147;
import '../../domain/interfaces/i_connectivity_service.dart' as _i751;
import '../../domain/interfaces/i_gear_cloud_service.dart' as _i1042;
import '../../domain/interfaces/i_geolocator_service.dart' as _i956;
import '../../domain/interfaces/i_poll_service.dart' as _i304;
import '../../domain/interfaces/i_token_validator.dart' as _i1012;
import '../../domain/interfaces/i_weather_service.dart' as _i874;
import '../../domain/repositories/i_auth_session_repository.dart' as _i43;
import '../../domain/repositories/i_favorites_repository.dart' as _i571;
import '../../domain/repositories/i_gear_library_repository.dart' as _i241;
import '../../domain/repositories/i_gear_repository.dart' as _i684;
import '../../domain/repositories/i_gear_set_repository.dart' as _i138;
import '../../domain/repositories/i_group_event_repository.dart' as _i868;
import '../../domain/repositories/i_itinerary_repository.dart' as _i750;
import '../../domain/repositories/i_message_repository.dart' as _i572;
import '../../domain/repositories/i_poll_repository.dart' as _i893;
import '../../domain/repositories/i_settings_repository.dart' as _i868;
import '../../domain/repositories/i_trip_repository.dart' as _i634;
import '../../infrastructure/clients/api_client.dart' as _i1019;
import '../../infrastructure/clients/network_aware_client.dart' as _i7;
import '../../infrastructure/infrastructure.dart' as _i342;
import '../../infrastructure/interceptors/auth_interceptor.dart' as _i27;
import '../../infrastructure/interceptors/connectivity_interceptor.dart'
    as _i254;
import '../../infrastructure/mock/mock_poll_service.dart' as _i133;
import '../../infrastructure/services/ad_service.dart' as _i702;
import '../../infrastructure/services/auth_service.dart' as _i227;
import '../../infrastructure/services/connectivity_service.dart' as _i315;
import '../../infrastructure/services/geolocator_service.dart' as _i548;
import '../../infrastructure/services/jwt_token_validator.dart' as _i1065;
import '../../infrastructure/services/sync_service.dart' as _i724;
import '../../infrastructure/services/weather_service.dart' as _i27;
import '../../infrastructure/tools/hive_service.dart' as _i771;
import '../../infrastructure/tools/usage_tracking_service.dart' as _i755;
import '../../presentation/cubits/auth/auth_cubit.dart' as _i33;
import '../../presentation/cubits/favorites/group_event/group_event_favorites_cubit.dart'
    as _i115;
import '../../presentation/cubits/favorites/mountain/mountain_favorites_cubit.dart'
    as _i748;
import '../../presentation/cubits/gear/gear_cubit.dart' as _i55;
import '../../presentation/cubits/gear_library/gear_library_cubit.dart'
    as _i757;
import '../../presentation/cubits/group_event/comment/group_event_comment_cubit.dart'
    as _i10;
import '../../presentation/cubits/group_event/group_event_cubit.dart' as _i882;
import '../../presentation/cubits/group_event/review/group_event_review_cubit.dart'
    as _i963;
import '../../presentation/cubits/itinerary/itinerary_cubit.dart' as _i354;
import '../../presentation/cubits/map/map_cubit.dart' as _i77;
import '../../presentation/cubits/map/offline_map_cubit.dart' as _i843;
import '../../presentation/cubits/meal/meal_cubit.dart' as _i694;
import '../../presentation/cubits/message/message_cubit.dart' as _i675;
import '../../presentation/cubits/poll/poll_cubit.dart' as _i1040;
import '../../presentation/cubits/settings/settings_cubit.dart' as _i266;
import '../../presentation/cubits/sync/sync_cubit.dart' as _i846;
import '../../presentation/cubits/trip/trip_cubit.dart' as _i32;
import '../location/i_location_resolver.dart' as _i887;
import '../location/township_location_resolver.dart' as _i351;
import '../services/permission_service.dart' as _i165;
import '../services/platform_service.dart' as _i1007;
import 'api_module.dart' as _i804;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final apiModule = _$ApiModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    await gh.factoryAsync<_i655.PackageInfo>(
      () => registerModule.packageInfo,
      preResolve: true,
    );
    gh.factory<_i77.MapCubit>(() => _i77.MapCubit());
    gh.factory<_i843.OfflineMapCubit>(() => _i843.OfflineMapCubit());
    gh.factory<_i694.MealCubit>(() => _i694.MealCubit());
    await gh.singletonAsync<_i342.HiveService>(
      () => registerModule.hiveService,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i973.InternetConnectionChecker>(
      () => registerModule.internetConnectionChecker,
    );
    gh.lazySingleton<_i1007.PlatformService>(() => _i1007.PlatformService());
    gh.lazySingleton<_i455.CwaWeatherSource>(() => _i455.CwaWeatherSource());
    gh.lazySingleton<_i1042.IGearCloudService>(
      () => _i699.FakeGearCloudService(),
    );
    gh.factory<_i115.GroupEventFavoritesCubit>(
      () => _i115.GroupEventFavoritesCubit(gh<_i771.HiveService>()),
    );
    gh.factory<_i748.MountainFavoritesCubit>(
      () => _i748.MountainFavoritesCubit(gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i304.IPollService>(() => _i133.MockPollService());
    gh.lazySingleton<_i116.IItineraryLocalDataSource>(
      () =>
          _i130.ItineraryLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i1012.ITokenValidator>(() => _i1065.JwtTokenValidator());
    gh.lazySingleton<_i730.IAdService>(() => _i702.AdService());
    gh.lazySingleton<_i393.ISettingsLocalDataSource>(
      () => _i179.SettingsLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i484.IGearKeyLocalDataSource>(
      () => _i835.GearKeyLocalDataSource(),
    );
    gh.lazySingleton<_i240.IGearLibraryLocalDataSource>(
      () => _i1068.GearLibraryLocalDataSource(
        hiveService: gh<_i771.HiveService>(),
      ),
    );
    gh.lazySingleton<_i774.ITripLocalDataSource>(
      () => _i688.TripLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i691.IGearLocalDataSource>(
      () => _i316.GearLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i307.IFavoritesLocalDataSource>(
      () => _i19.FavoritesLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i529.IGroupEventLocalDataSource>(
      () =>
          _i903.GroupEventLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i930.IPollLocalDataSource>(
      () => _i432.PollLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.factory<String>(() => registerModule.baseUrl, instanceName: 'baseUrl');
    gh.lazySingleton<_i418.IApiClient>(
      () => _i1019.ApiClient(
        dio: gh<_i361.Dio>(),
        baseUrl: gh<String>(instanceName: 'baseUrl'),
      ),
    );
    gh.lazySingleton<_i138.IGearSetRepository>(
      () => _i536.GearSetRepository(
        gh<_i1042.IGearCloudService>(),
        gh<_i484.IGearKeyLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i956.IGeolocatorService>(() => _i548.GeolocatorService());
    gh.lazySingleton<_i887.ILocationResolver>(
      () => _i351.TownshipLocationResolver(),
    );
    gh.lazySingleton<_i21.IMessageLocalDataSource>(
      () => _i783.MessageLocalDataSource(hiveService: gh<_i771.HiveService>()),
    );
    gh.lazySingleton<_i684.IGearRepository>(
      () => _i867.GearRepository(gh<_i691.IGearLocalDataSource>()),
    );
    gh.factory<_i55.GearCubit>(
      () => _i55.GearCubit(gh<_i684.IGearRepository>()),
    );
    gh.lazySingleton<_i868.ISettingsRepository>(
      () => _i373.SettingsRepository(
        localDataSource: gh<_i393.ISettingsLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i751.IConnectivityService>(
      () => _i315.ConnectivityService(
        checker: gh<_i973.InternetConnectionChecker>(),
        settingsRepo: gh<_i868.ISettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i26.IAuthSessionLocalDataSource>(
      () => _i4.AuthSessionLocalDataSource(
        secureStorage: gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i755.UsageTrackingService>(
      () => _i755.UsageTrackingService(gh<_i418.IApiClient>()),
    );
    gh.lazySingleton<_i874.IWeatherService>(
      () => _i27.WeatherService(
        settingsRepo: gh<_i868.ISettingsRepository>(),
        locationResolver: gh<_i887.ILocationResolver>(),
        cwaSource: gh<_i455.CwaWeatherSource>(),
      ),
    );
    gh.lazySingleton<_i254.ConnectivityInterceptor>(
      () => _i254.ConnectivityInterceptor(gh<_i751.IConnectivityService>()),
    );
    gh.lazySingleton<_i43.IAuthSessionRepository>(
      () => _i395.AuthSessionRepository(
        localDataSource: gh<_i26.IAuthSessionLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i7.NetworkAwareClient>(
      () => _i7.NetworkAwareClient(
        apiClient: gh<_i418.IApiClient>(),
        connectivity: gh<_i751.IConnectivityService>(),
      ),
    );
    gh.factory<_i266.SettingsCubit>(
      () => _i266.SettingsCubit(
        gh<_i868.ISettingsRepository>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i27.AuthInterceptor>(
      () => _i27.AuthInterceptor(gh<_i43.IAuthSessionRepository>()),
    );
    gh.lazySingleton<_i147.IAuthService>(
      () => _i227.AuthService(
        apiClient: gh<_i7.NetworkAwareClient>(),
        sessionRepository: gh<_i43.IAuthSessionRepository>(),
        tokenValidator: gh<_i1012.ITokenValidator>(),
      ),
    );
    gh.factory<_i33.AuthCubit>(
      () => _i33.AuthCubit(
        gh<_i614.IAuthService>(),
        gh<_i342.UsageTrackingService>(),
      ),
    );
    gh.lazySingleton<_i165.PermissionService>(
      () => _i165.PermissionService(gh<_i147.IAuthService>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(
        gh<String>(instanceName: 'baseUrl'),
        gh<_i342.AuthInterceptor>(),
        gh<_i254.ConnectivityInterceptor>(),
      ),
    );
    gh.lazySingleton<_i1035.FavoritesApiService>(
      () => apiModule.getFavoritesApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i83.GearLibraryApiService>(
      () => apiModule.getGearLibraryApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i912.GroupEventApiService>(
      () => apiModule.getGroupEventApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i100.ItineraryApiService>(
      () => apiModule.getItineraryApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i458.MealLibraryApiService>(
      () => apiModule.getMealLibraryApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i367.MessageApiService>(
      () => apiModule.getMessageApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i245.PollApiService>(
      () => apiModule.getPollApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1030.TripApiService>(
      () => apiModule.getTripApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i9.TripGearApiService>(
      () => apiModule.getTripGearApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i579.TripMealApiService>(
      () => apiModule.getTripMealApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i716.UserApiService>(
      () => apiModule.getUserApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i342.IFavoritesRemoteDataSource>(
      () => _i168.FavoritesRemoteDataSource(gh<_i1035.FavoritesApiService>()),
    );
    gh.lazySingleton<_i725.ITripGearRemoteDataSource>(
      () => _i391.TripGearRemoteDataSource(gh<_i9.TripGearApiService>()),
    );
    gh.lazySingleton<_i999.ITripMealRemoteDataSource>(
      () => _i829.TripMealRemoteDataSource(gh<_i579.TripMealApiService>()),
    );
    gh.lazySingleton<_i644.IPollRemoteDataSource>(
      () => _i621.PollRemoteDataSource(gh<_i245.PollApiService>()),
    );
    gh.lazySingleton<_i307.IItineraryRemoteDataSource>(
      () => _i636.ItineraryRemoteDataSource(gh<_i100.ItineraryApiService>()),
    );
    gh.lazySingleton<_i893.IPollRepository>(
      () => _i222.PollRepository(
        gh<_i930.IPollLocalDataSource>(),
        gh<_i644.IPollRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i880.IMessageRemoteDataSource>(
      () => _i1017.MessageRemoteDataSource(gh<_i367.MessageApiService>()),
    );
    gh.lazySingleton<_i1050.IUserRemoteDataSource>(
      () => _i41.UserRemoteDataSource(gh<_i716.UserApiService>()),
    );
    gh.lazySingleton<_i941.ITripRemoteDataSource>(
      () => _i989.TripRemoteDataSource(gh<_i1030.TripApiService>()),
    );
    gh.lazySingleton<_i31.IGearLibraryRemoteDataSource>(
      () => _i781.GearLibraryRemoteDataSource(gh<_i83.GearLibraryApiService>()),
    );
    gh.lazySingleton<_i25.IGroupEventRemoteDataSource>(
      () => _i959.GroupEventRemoteDataSource(gh<_i912.GroupEventApiService>()),
    );
    gh.lazySingleton<_i571.IFavoritesRepository>(
      () => _i803.FavoritesRepository(
        localDataSource: gh<_i307.IFavoritesLocalDataSource>(),
        remoteDataSource: gh<_i342.IFavoritesRemoteDataSource>(),
        authService: gh<_i147.IAuthService>(),
      ),
    );
    gh.lazySingleton<_i634.ITripRepository>(
      () => _i564.TripRepository(
        gh<_i774.ITripLocalDataSource>(),
        gh<_i941.ITripRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i750.IItineraryRepository>(
      () => _i790.ItineraryRepository(
        localDataSource: gh<_i116.IItineraryLocalDataSource>(),
        remoteDataSource: gh<_i307.IItineraryRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i241.IGearLibraryRepository>(
      () => _i540.GearLibraryRepository(
        localDataSource: gh<_i240.IGearLibraryLocalDataSource>(),
        remoteDataSource: gh<_i31.IGearLibraryRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i868.IGroupEventRepository>(
      () => _i354.GroupEventRepository(
        gh<_i529.IGroupEventLocalDataSource>(),
        gh<_i25.IGroupEventRemoteDataSource>(),
      ),
    );
    gh.factory<_i1040.PollCubit>(
      () => _i1040.PollCubit(
        gh<_i614.IPollRepository>(),
        gh<_i614.ITripRepository>(),
        gh<_i614.IConnectivityService>(),
        gh<_i614.IAuthService>(),
      ),
    );
    gh.lazySingleton<_i572.IMessageRepository>(
      () => _i1040.MessageRepository(
        gh<_i21.IMessageLocalDataSource>(),
        gh<_i880.IMessageRemoteDataSource>(),
      ),
    );
    gh.factoryParam<_i963.GroupEventReviewCubit, String?, String?>(
      (eventId, userId) => _i963.GroupEventReviewCubit(
        gh<_i614.IGroupEventRepository>(),
        eventId,
        userId,
      ),
    );
    gh.factory<_i675.MessageCubit>(
      () => _i675.MessageCubit(
        gh<_i614.IMessageRepository>(),
        gh<_i614.ITripRepository>(),
        gh<_i614.IAuthService>(),
      ),
    );
    gh.factory<_i757.GearLibraryCubit>(
      () => _i757.GearLibraryCubit(
        gh<_i614.IGearLibraryRepository>(),
        gh<_i614.IGearRepository>(),
        gh<_i614.ITripRepository>(),
        gh<_i614.IAuthService>(),
        gh<_i31.IGearLibraryRemoteDataSource>(),
      ),
    );
    gh.factory<_i882.GroupEventCubit>(
      () => _i882.GroupEventCubit(
        gh<_i614.IGroupEventRepository>(),
        gh<_i614.IConnectivityService>(),
        gh<_i614.IAuthService>(),
      ),
    );
    gh.factory<_i32.TripCubit>(
      () => _i32.TripCubit(
        gh<_i614.ITripRepository>(),
        gh<_i614.IAuthService>(),
        gh<_i614.IGearRepository>(),
        gh<_i614.IItineraryRepository>(),
        gh<_i725.ITripGearRemoteDataSource>(),
      ),
    );
    gh.factory<_i354.ItineraryCubit>(
      () => _i354.ItineraryCubit(
        gh<_i614.IItineraryRepository>(),
        gh<_i614.ITripRepository>(),
        gh<_i614.IAuthService>(),
      ),
    );
    gh.lazySingleton<_i614.ISyncService>(
      () => _i724.SyncService(
        tripRepo: gh<_i614.ITripRepository>(),
        itineraryRepo: gh<_i614.IItineraryRepository>(),
        messageRepo: gh<_i614.IMessageRepository>(),
        connectivity: gh<_i614.IConnectivityService>(),
        authService: gh<_i614.IAuthService>(),
      ),
    );
    gh.factoryParam<_i10.GroupEventCommentCubit, String?, dynamic>(
      (eventId, _) => _i10.GroupEventCommentCubit(
        gh<_i614.IGroupEventRepository>(),
        gh<_i614.IAuthService>(),
        eventId,
      ),
    );
    gh.factory<_i846.SyncCubit>(
      () => _i846.SyncCubit(
        gh<_i614.ISyncService>(),
        gh<_i614.IConnectivityService>(),
        gh<_i614.IItineraryRepository>(),
        gh<_i614.IAuthService>(),
        gh<_i614.ITripRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$ApiModule extends _i804.ApiModule {}
