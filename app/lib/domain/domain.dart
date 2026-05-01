/// Domain Layer Exports
///
/// 匯出所有 Domain 層的元件：實體、Repository 介面、Service 介面。
/// 使用方式：import 'package:summitmate/domain/domain.dart';
library;

// Failures
export 'failures/failure.dart' hide Failure;

// Entities
export 'entities/gear_item.dart';
export 'entities/itinerary_item.dart';
export 'entities/trip.dart';
export 'entities/message.dart';

// Repository Interfaces（完整清單）
export 'repositories/i_gear_repository.dart';
export 'repositories/i_itinerary_repository.dart';
export 'repositories/i_auth_session_repository.dart';
export 'repositories/i_favorites_repository.dart';
export 'repositories/i_gear_library_repository.dart';
export 'repositories/i_gear_set_repository.dart';
export 'repositories/i_group_event_repository.dart';
export 'repositories/i_message_repository.dart';
export 'repositories/i_poll_repository.dart';
export 'repositories/i_settings_repository.dart';
export 'repositories/i_trip_repository.dart';

// Service Interfaces
export 'interfaces/i_ad_service.dart';
export 'interfaces/i_auth_service.dart';
export 'interfaces/i_connectivity_service.dart';
export 'interfaces/i_data_service.dart';
export 'interfaces/i_gear_cloud_service.dart';
export 'interfaces/i_gear_library_cloud_service.dart';
export 'interfaces/i_geolocator_service.dart';
export 'interfaces/i_poll_service.dart';
export 'interfaces/i_sync_service.dart';
export 'interfaces/i_token_validator.dart';
export 'interfaces/i_weather_service.dart';

export 'entities/settings.dart';
export 'entities/poll.dart';
export 'entities/gear_library_item.dart';
export 'entities/group_event.dart';