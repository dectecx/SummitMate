/// Domain Layer Exports
///
/// This file exports all domain layer components including interfaces, failures, and DTOs.
/// Usage: import 'package:summitmate/domain/domain.dart';
library;

// Failures
export 'failures/failure.dart' hide Failure;

// Interfaces
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
