import 'package:freezed_annotation/freezed_annotation.dart';

/// UTC DateTime Converter for Freezed API models.
///
/// - fromJson: Parses ISO8601 string and converts to local time for display.
/// - toJson: Converts DateTime to UTC ISO8601 string for API transmission.
///
/// Usage with Freezed:
/// ```dart
/// @freezed
/// abstract class MyRequest with _$MyRequest {
///   const factory MyRequest({
///     @DateTimeUtcConverter() required DateTime createdAt,
///     @NullableDateTimeUtcConverter() DateTime? updatedAt,
///   }) = _MyRequest;
/// }
/// ```
class DateTimeUtcConverter implements JsonConverter<DateTime, String> {
  const DateTimeUtcConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json).toLocal();
  }

  @override
  String toJson(DateTime object) {
    return object.toUtc().toIso8601String();
  }
}

/// Nullable variant of [DateTimeUtcConverter].
class NullableDateTimeUtcConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeUtcConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.parse(json).toLocal();
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return object.toUtc().toIso8601String();
  }
}

/// Date-only converter (format: YYYY-MM-DD).
///
/// Use when the backend field is `format: date` in OpenAPI schema,
/// such as event start_date, end_date in GroupEvent.
class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(String json) {
    // Parse YYYY-MM-DD as local midnight
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    // Serialize as YYYY-MM-DD only
    return '${object.year.toString().padLeft(4, '0')}-'
        '${object.month.toString().padLeft(2, '0')}-'
        '${object.day.toString().padLeft(2, '0')}';
  }
}

/// Nullable variant of [DateOnlyConverter].
class NullableDateOnlyConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateOnlyConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.parse(json);
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return '${object.year.toString().padLeft(4, '0')}-'
        '${object.month.toString().padLeft(2, '0')}-'
        '${object.day.toString().padLeft(2, '0')}';
  }
}
