// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeatherData {

 double get temperature; double get humidity; int get rainProbability; double get windSpeed; String get condition; DateTime get sunrise; DateTime get sunset; DateTime get timestamp; String get locationName; List<DailyForecast> get dailyForecasts; double? get apparentTemperature; DateTime? get issueTime;
/// Create a copy of WeatherData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherDataCopyWith<WeatherData> get copyWith => _$WeatherDataCopyWithImpl<WeatherData>(this as WeatherData, _$identity);

  /// Serializes this WeatherData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherData&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.rainProbability, rainProbability) || other.rainProbability == rainProbability)&&(identical(other.windSpeed, windSpeed) || other.windSpeed == windSpeed)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.sunrise, sunrise) || other.sunrise == sunrise)&&(identical(other.sunset, sunset) || other.sunset == sunset)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&const DeepCollectionEquality().equals(other.dailyForecasts, dailyForecasts)&&(identical(other.apparentTemperature, apparentTemperature) || other.apparentTemperature == apparentTemperature)&&(identical(other.issueTime, issueTime) || other.issueTime == issueTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,temperature,humidity,rainProbability,windSpeed,condition,sunrise,sunset,timestamp,locationName,const DeepCollectionEquality().hash(dailyForecasts),apparentTemperature,issueTime);

@override
String toString() {
  return 'WeatherData(temperature: $temperature, humidity: $humidity, rainProbability: $rainProbability, windSpeed: $windSpeed, condition: $condition, sunrise: $sunrise, sunset: $sunset, timestamp: $timestamp, locationName: $locationName, dailyForecasts: $dailyForecasts, apparentTemperature: $apparentTemperature, issueTime: $issueTime)';
}


}

/// @nodoc
abstract mixin class $WeatherDataCopyWith<$Res>  {
  factory $WeatherDataCopyWith(WeatherData value, $Res Function(WeatherData) _then) = _$WeatherDataCopyWithImpl;
@useResult
$Res call({
 double temperature, double humidity, int rainProbability, double windSpeed, String condition, DateTime sunrise, DateTime sunset, DateTime timestamp, String locationName, List<DailyForecast> dailyForecasts, double? apparentTemperature, DateTime? issueTime
});




}
/// @nodoc
class _$WeatherDataCopyWithImpl<$Res>
    implements $WeatherDataCopyWith<$Res> {
  _$WeatherDataCopyWithImpl(this._self, this._then);

  final WeatherData _self;
  final $Res Function(WeatherData) _then;

/// Create a copy of WeatherData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? temperature = null,Object? humidity = null,Object? rainProbability = null,Object? windSpeed = null,Object? condition = null,Object? sunrise = null,Object? sunset = null,Object? timestamp = null,Object? locationName = null,Object? dailyForecasts = null,Object? apparentTemperature = freezed,Object? issueTime = freezed,}) {
  return _then(_self.copyWith(
temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as double,rainProbability: null == rainProbability ? _self.rainProbability : rainProbability // ignore: cast_nullable_to_non_nullable
as int,windSpeed: null == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,sunrise: null == sunrise ? _self.sunrise : sunrise // ignore: cast_nullable_to_non_nullable
as DateTime,sunset: null == sunset ? _self.sunset : sunset // ignore: cast_nullable_to_non_nullable
as DateTime,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,dailyForecasts: null == dailyForecasts ? _self.dailyForecasts : dailyForecasts // ignore: cast_nullable_to_non_nullable
as List<DailyForecast>,apparentTemperature: freezed == apparentTemperature ? _self.apparentTemperature : apparentTemperature // ignore: cast_nullable_to_non_nullable
as double?,issueTime: freezed == issueTime ? _self.issueTime : issueTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherData].
extension WeatherDataPatterns on WeatherData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherData value)  $default,){
final _that = this;
switch (_that) {
case _WeatherData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherData value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double temperature,  double humidity,  int rainProbability,  double windSpeed,  String condition,  DateTime sunrise,  DateTime sunset,  DateTime timestamp,  String locationName,  List<DailyForecast> dailyForecasts,  double? apparentTemperature,  DateTime? issueTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherData() when $default != null:
return $default(_that.temperature,_that.humidity,_that.rainProbability,_that.windSpeed,_that.condition,_that.sunrise,_that.sunset,_that.timestamp,_that.locationName,_that.dailyForecasts,_that.apparentTemperature,_that.issueTime);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double temperature,  double humidity,  int rainProbability,  double windSpeed,  String condition,  DateTime sunrise,  DateTime sunset,  DateTime timestamp,  String locationName,  List<DailyForecast> dailyForecasts,  double? apparentTemperature,  DateTime? issueTime)  $default,) {final _that = this;
switch (_that) {
case _WeatherData():
return $default(_that.temperature,_that.humidity,_that.rainProbability,_that.windSpeed,_that.condition,_that.sunrise,_that.sunset,_that.timestamp,_that.locationName,_that.dailyForecasts,_that.apparentTemperature,_that.issueTime);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double temperature,  double humidity,  int rainProbability,  double windSpeed,  String condition,  DateTime sunrise,  DateTime sunset,  DateTime timestamp,  String locationName,  List<DailyForecast> dailyForecasts,  double? apparentTemperature,  DateTime? issueTime)?  $default,) {final _that = this;
switch (_that) {
case _WeatherData() when $default != null:
return $default(_that.temperature,_that.humidity,_that.rainProbability,_that.windSpeed,_that.condition,_that.sunrise,_that.sunset,_that.timestamp,_that.locationName,_that.dailyForecasts,_that.apparentTemperature,_that.issueTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherData extends WeatherData {
  const _WeatherData({required this.temperature, required this.humidity, required this.rainProbability, required this.windSpeed, required this.condition, required this.sunrise, required this.sunset, required this.timestamp, required this.locationName, final  List<DailyForecast> dailyForecasts = const [], this.apparentTemperature, this.issueTime}): _dailyForecasts = dailyForecasts,super._();
  factory _WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);

@override final  double temperature;
@override final  double humidity;
@override final  int rainProbability;
@override final  double windSpeed;
@override final  String condition;
@override final  DateTime sunrise;
@override final  DateTime sunset;
@override final  DateTime timestamp;
@override final  String locationName;
 final  List<DailyForecast> _dailyForecasts;
@override@JsonKey() List<DailyForecast> get dailyForecasts {
  if (_dailyForecasts is EqualUnmodifiableListView) return _dailyForecasts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyForecasts);
}

@override final  double? apparentTemperature;
@override final  DateTime? issueTime;

/// Create a copy of WeatherData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherDataCopyWith<_WeatherData> get copyWith => __$WeatherDataCopyWithImpl<_WeatherData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherData&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.rainProbability, rainProbability) || other.rainProbability == rainProbability)&&(identical(other.windSpeed, windSpeed) || other.windSpeed == windSpeed)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.sunrise, sunrise) || other.sunrise == sunrise)&&(identical(other.sunset, sunset) || other.sunset == sunset)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&const DeepCollectionEquality().equals(other._dailyForecasts, _dailyForecasts)&&(identical(other.apparentTemperature, apparentTemperature) || other.apparentTemperature == apparentTemperature)&&(identical(other.issueTime, issueTime) || other.issueTime == issueTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,temperature,humidity,rainProbability,windSpeed,condition,sunrise,sunset,timestamp,locationName,const DeepCollectionEquality().hash(_dailyForecasts),apparentTemperature,issueTime);

@override
String toString() {
  return 'WeatherData(temperature: $temperature, humidity: $humidity, rainProbability: $rainProbability, windSpeed: $windSpeed, condition: $condition, sunrise: $sunrise, sunset: $sunset, timestamp: $timestamp, locationName: $locationName, dailyForecasts: $dailyForecasts, apparentTemperature: $apparentTemperature, issueTime: $issueTime)';
}


}

/// @nodoc
abstract mixin class _$WeatherDataCopyWith<$Res> implements $WeatherDataCopyWith<$Res> {
  factory _$WeatherDataCopyWith(_WeatherData value, $Res Function(_WeatherData) _then) = __$WeatherDataCopyWithImpl;
@override @useResult
$Res call({
 double temperature, double humidity, int rainProbability, double windSpeed, String condition, DateTime sunrise, DateTime sunset, DateTime timestamp, String locationName, List<DailyForecast> dailyForecasts, double? apparentTemperature, DateTime? issueTime
});




}
/// @nodoc
class __$WeatherDataCopyWithImpl<$Res>
    implements _$WeatherDataCopyWith<$Res> {
  __$WeatherDataCopyWithImpl(this._self, this._then);

  final _WeatherData _self;
  final $Res Function(_WeatherData) _then;

/// Create a copy of WeatherData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? temperature = null,Object? humidity = null,Object? rainProbability = null,Object? windSpeed = null,Object? condition = null,Object? sunrise = null,Object? sunset = null,Object? timestamp = null,Object? locationName = null,Object? dailyForecasts = null,Object? apparentTemperature = freezed,Object? issueTime = freezed,}) {
  return _then(_WeatherData(
temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as double,rainProbability: null == rainProbability ? _self.rainProbability : rainProbability // ignore: cast_nullable_to_non_nullable
as int,windSpeed: null == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as double,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,sunrise: null == sunrise ? _self.sunrise : sunrise // ignore: cast_nullable_to_non_nullable
as DateTime,sunset: null == sunset ? _self.sunset : sunset // ignore: cast_nullable_to_non_nullable
as DateTime,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,dailyForecasts: null == dailyForecasts ? _self._dailyForecasts : dailyForecasts // ignore: cast_nullable_to_non_nullable
as List<DailyForecast>,apparentTemperature: freezed == apparentTemperature ? _self.apparentTemperature : apparentTemperature // ignore: cast_nullable_to_non_nullable
as double?,issueTime: freezed == issueTime ? _self.issueTime : issueTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DailyForecast {

 DateTime get date; String get dayCondition; String get nightCondition; double get maxTemp; double get minTemp; int get rainProbability; double? get maxApparentTemp; double? get minApparentTemp;
/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyForecastCopyWith<DailyForecast> get copyWith => _$DailyForecastCopyWithImpl<DailyForecast>(this as DailyForecast, _$identity);

  /// Serializes this DailyForecast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyForecast&&(identical(other.date, date) || other.date == date)&&(identical(other.dayCondition, dayCondition) || other.dayCondition == dayCondition)&&(identical(other.nightCondition, nightCondition) || other.nightCondition == nightCondition)&&(identical(other.maxTemp, maxTemp) || other.maxTemp == maxTemp)&&(identical(other.minTemp, minTemp) || other.minTemp == minTemp)&&(identical(other.rainProbability, rainProbability) || other.rainProbability == rainProbability)&&(identical(other.maxApparentTemp, maxApparentTemp) || other.maxApparentTemp == maxApparentTemp)&&(identical(other.minApparentTemp, minApparentTemp) || other.minApparentTemp == minApparentTemp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,dayCondition,nightCondition,maxTemp,minTemp,rainProbability,maxApparentTemp,minApparentTemp);

@override
String toString() {
  return 'DailyForecast(date: $date, dayCondition: $dayCondition, nightCondition: $nightCondition, maxTemp: $maxTemp, minTemp: $minTemp, rainProbability: $rainProbability, maxApparentTemp: $maxApparentTemp, minApparentTemp: $minApparentTemp)';
}


}

/// @nodoc
abstract mixin class $DailyForecastCopyWith<$Res>  {
  factory $DailyForecastCopyWith(DailyForecast value, $Res Function(DailyForecast) _then) = _$DailyForecastCopyWithImpl;
@useResult
$Res call({
 DateTime date, String dayCondition, String nightCondition, double maxTemp, double minTemp, int rainProbability, double? maxApparentTemp, double? minApparentTemp
});




}
/// @nodoc
class _$DailyForecastCopyWithImpl<$Res>
    implements $DailyForecastCopyWith<$Res> {
  _$DailyForecastCopyWithImpl(this._self, this._then);

  final DailyForecast _self;
  final $Res Function(DailyForecast) _then;

/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? dayCondition = null,Object? nightCondition = null,Object? maxTemp = null,Object? minTemp = null,Object? rainProbability = null,Object? maxApparentTemp = freezed,Object? minApparentTemp = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,dayCondition: null == dayCondition ? _self.dayCondition : dayCondition // ignore: cast_nullable_to_non_nullable
as String,nightCondition: null == nightCondition ? _self.nightCondition : nightCondition // ignore: cast_nullable_to_non_nullable
as String,maxTemp: null == maxTemp ? _self.maxTemp : maxTemp // ignore: cast_nullable_to_non_nullable
as double,minTemp: null == minTemp ? _self.minTemp : minTemp // ignore: cast_nullable_to_non_nullable
as double,rainProbability: null == rainProbability ? _self.rainProbability : rainProbability // ignore: cast_nullable_to_non_nullable
as int,maxApparentTemp: freezed == maxApparentTemp ? _self.maxApparentTemp : maxApparentTemp // ignore: cast_nullable_to_non_nullable
as double?,minApparentTemp: freezed == minApparentTemp ? _self.minApparentTemp : minApparentTemp // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyForecast].
extension DailyForecastPatterns on DailyForecast {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyForecast value)  $default,){
final _that = this;
switch (_that) {
case _DailyForecast():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyForecast value)?  $default,){
final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String dayCondition,  String nightCondition,  double maxTemp,  double minTemp,  int rainProbability,  double? maxApparentTemp,  double? minApparentTemp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that.date,_that.dayCondition,_that.nightCondition,_that.maxTemp,_that.minTemp,_that.rainProbability,_that.maxApparentTemp,_that.minApparentTemp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String dayCondition,  String nightCondition,  double maxTemp,  double minTemp,  int rainProbability,  double? maxApparentTemp,  double? minApparentTemp)  $default,) {final _that = this;
switch (_that) {
case _DailyForecast():
return $default(_that.date,_that.dayCondition,_that.nightCondition,_that.maxTemp,_that.minTemp,_that.rainProbability,_that.maxApparentTemp,_that.minApparentTemp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String dayCondition,  String nightCondition,  double maxTemp,  double minTemp,  int rainProbability,  double? maxApparentTemp,  double? minApparentTemp)?  $default,) {final _that = this;
switch (_that) {
case _DailyForecast() when $default != null:
return $default(_that.date,_that.dayCondition,_that.nightCondition,_that.maxTemp,_that.minTemp,_that.rainProbability,_that.maxApparentTemp,_that.minApparentTemp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyForecast implements DailyForecast {
  const _DailyForecast({required this.date, required this.dayCondition, required this.nightCondition, required this.maxTemp, required this.minTemp, required this.rainProbability, this.maxApparentTemp, this.minApparentTemp});
  factory _DailyForecast.fromJson(Map<String, dynamic> json) => _$DailyForecastFromJson(json);

@override final  DateTime date;
@override final  String dayCondition;
@override final  String nightCondition;
@override final  double maxTemp;
@override final  double minTemp;
@override final  int rainProbability;
@override final  double? maxApparentTemp;
@override final  double? minApparentTemp;

/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyForecastCopyWith<_DailyForecast> get copyWith => __$DailyForecastCopyWithImpl<_DailyForecast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyForecastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyForecast&&(identical(other.date, date) || other.date == date)&&(identical(other.dayCondition, dayCondition) || other.dayCondition == dayCondition)&&(identical(other.nightCondition, nightCondition) || other.nightCondition == nightCondition)&&(identical(other.maxTemp, maxTemp) || other.maxTemp == maxTemp)&&(identical(other.minTemp, minTemp) || other.minTemp == minTemp)&&(identical(other.rainProbability, rainProbability) || other.rainProbability == rainProbability)&&(identical(other.maxApparentTemp, maxApparentTemp) || other.maxApparentTemp == maxApparentTemp)&&(identical(other.minApparentTemp, minApparentTemp) || other.minApparentTemp == minApparentTemp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,dayCondition,nightCondition,maxTemp,minTemp,rainProbability,maxApparentTemp,minApparentTemp);

@override
String toString() {
  return 'DailyForecast(date: $date, dayCondition: $dayCondition, nightCondition: $nightCondition, maxTemp: $maxTemp, minTemp: $minTemp, rainProbability: $rainProbability, maxApparentTemp: $maxApparentTemp, minApparentTemp: $minApparentTemp)';
}


}

/// @nodoc
abstract mixin class _$DailyForecastCopyWith<$Res> implements $DailyForecastCopyWith<$Res> {
  factory _$DailyForecastCopyWith(_DailyForecast value, $Res Function(_DailyForecast) _then) = __$DailyForecastCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String dayCondition, String nightCondition, double maxTemp, double minTemp, int rainProbability, double? maxApparentTemp, double? minApparentTemp
});




}
/// @nodoc
class __$DailyForecastCopyWithImpl<$Res>
    implements _$DailyForecastCopyWith<$Res> {
  __$DailyForecastCopyWithImpl(this._self, this._then);

  final _DailyForecast _self;
  final $Res Function(_DailyForecast) _then;

/// Create a copy of DailyForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? dayCondition = null,Object? nightCondition = null,Object? maxTemp = null,Object? minTemp = null,Object? rainProbability = null,Object? maxApparentTemp = freezed,Object? minApparentTemp = freezed,}) {
  return _then(_DailyForecast(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,dayCondition: null == dayCondition ? _self.dayCondition : dayCondition // ignore: cast_nullable_to_non_nullable
as String,nightCondition: null == nightCondition ? _self.nightCondition : nightCondition // ignore: cast_nullable_to_non_nullable
as String,maxTemp: null == maxTemp ? _self.maxTemp : maxTemp // ignore: cast_nullable_to_non_nullable
as double,minTemp: null == minTemp ? _self.minTemp : minTemp // ignore: cast_nullable_to_non_nullable
as double,rainProbability: null == rainProbability ? _self.rainProbability : rainProbability // ignore: cast_nullable_to_non_nullable
as int,maxApparentTemp: freezed == maxApparentTemp ? _self.maxApparentTemp : maxApparentTemp // ignore: cast_nullable_to_non_nullable
as double?,minApparentTemp: freezed == minApparentTemp ? _self.minApparentTemp : minApparentTemp // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
