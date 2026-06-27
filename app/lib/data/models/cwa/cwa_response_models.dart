import 'package:freezed_annotation/freezed_annotation.dart';

part 'cwa_response_models.freezed.dart';
part 'cwa_response_models.g.dart';

/// CWA 開放資料 API 同時可能回傳 PascalCase 或 camelCase key，
/// 以 PascalCase 為主 key，找不到時退回首字小寫的 camelCase 變體。
Object? _readCwaKey(Map<dynamic, dynamic> json, String key) {
  final camelKey = '${key[0].toLowerCase()}${key.substring(1)}';
  return json[key] ?? json[camelKey];
}

/// records 為頂層小寫 key，缺漏時退回空物件以維持容錯解析。
Object? _readCwaRecords(Map<dynamic, dynamic> json, String key) {
  return json[key] ?? json['Records'] ?? <String, dynamic>{};
}

/// Root Response
@freezed
abstract class CwaApiResponse with _$CwaApiResponse {
  const factory CwaApiResponse({
    @JsonKey(defaultValue: 'false') required String success,
    @JsonKey(name: 'records', readValue: _readCwaRecords) required CwaRecords records,
  }) = _CwaApiResponse;

  factory CwaApiResponse.fromJson(Map<String, dynamic> json) => _$CwaApiResponseFromJson(json);
}

/// Records Wrapper
@freezed
abstract class CwaRecords with _$CwaRecords {
  const factory CwaRecords({
    @JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: []) required List<CwaLocations> locationsList,
  }) = _CwaRecords;

  factory CwaRecords.fromJson(Map<String, dynamic> json) => _$CwaRecordsFromJson(json);
}

/// Locations Group (Usually contains DatasetDescription + List of Location)
@freezed
abstract class CwaLocations with _$CwaLocations {
  const factory CwaLocations({
    @JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '') required String datasetDescription,
    @JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '') required String locationsName,
    @JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: []) required List<CwaLocation> location,
  }) = _CwaLocations;

  factory CwaLocations.fromJson(Map<String, dynamic> json) => _$CwaLocationsFromJson(json);
}

/// Individual Location (e.g. "Xinyi District")
@freezed
abstract class CwaLocation with _$CwaLocation {
  const factory CwaLocation({
    @JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '') required String locationName,
    @JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: [])
    required List<CwaWeatherElement> weatherElement,
  }) = _CwaLocation;

  factory CwaLocation.fromJson(Map<String, dynamic> json) => _$CwaLocationFromJson(json);
}

/// Weather Element (e.g. Temperature series)
@freezed
abstract class CwaWeatherElement with _$CwaWeatherElement {
  const factory CwaWeatherElement({
    @JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '') required String elementName,
    @JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: []) required List<CwaTime> time,
  }) = _CwaWeatherElement;

  factory CwaWeatherElement.fromJson(Map<String, dynamic> json) => _$CwaWeatherElementFromJson(json);
}

/// Time Entry (Start, End, Value)
@freezed
abstract class CwaTime with _$CwaTime {
  const CwaTime._();

  const factory CwaTime({
    @JsonKey(name: 'StartTime', readValue: _readCwaKey) required DateTime startTime,
    @JsonKey(name: 'EndTime', readValue: _readCwaKey) DateTime? endTime,
    @JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: [])
    required List<Map<String, dynamic>> elementValue,
  }) = _CwaTime;

  factory CwaTime.fromJson(Map<String, dynamic> json) => _$CwaTimeFromJson(json);

  /// Helper to get the value string for a specific key preference
  /// e.g. getValue(['Temperature', 'value'])
  String getValue(List<String> keyPreferences) {
    if (elementValue.isEmpty) return '';
    final first = elementValue[0];

    for (final key in keyPreferences) {
      if (first.containsKey(key)) {
        return first[key].toString();
      }
    }
    // Fallback: implicit 'value' key when none of the preferences match.
    if (first.containsKey('value')) return first['value'].toString();
    return '';
  }
}
