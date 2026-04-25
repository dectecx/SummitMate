// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItineraryItemResponse {

 String get id;@JsonKey(name: 'trip_id') String get tripId;@JsonKey(defaultValue: '') String get day;@JsonKey(defaultValue: '') String get name;@JsonKey(name: 'est_time', defaultValue: '') String get estTime;@JsonKey(name: 'actual_time') DateTime? get actualTime;@JsonKey(defaultValue: 0) int get altitude;@JsonKey(defaultValue: 0.0) double get distance;@JsonKey(defaultValue: '') String get note;@JsonKey(name: 'image_asset') String? get imageAsset;@JsonKey(name: 'is_checked_in', defaultValue: false) bool get isCheckedIn;@JsonKey(name: 'checked_in_at') DateTime? get checkedInAt;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of ItineraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItineraryItemResponseCopyWith<ItineraryItemResponse> get copyWith => _$ItineraryItemResponseCopyWithImpl<ItineraryItemResponse>(this as ItineraryItemResponse, _$identity);

  /// Serializes this ItineraryItemResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItineraryItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.day, day) || other.day == day)&&(identical(other.name, name) || other.name == name)&&(identical(other.estTime, estTime) || other.estTime == estTime)&&(identical(other.actualTime, actualTime) || other.actualTime == actualTime)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.note, note) || other.note == note)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.isCheckedIn, isCheckedIn) || other.isCheckedIn == isCheckedIn)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,day,name,estTime,actualTime,altitude,distance,note,imageAsset,isCheckedIn,checkedInAt,createdAt,updatedAt);

@override
String toString() {
  return 'ItineraryItemResponse(id: $id, tripId: $tripId, day: $day, name: $name, estTime: $estTime, actualTime: $actualTime, altitude: $altitude, distance: $distance, note: $note, imageAsset: $imageAsset, isCheckedIn: $isCheckedIn, checkedInAt: $checkedInAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ItineraryItemResponseCopyWith<$Res>  {
  factory $ItineraryItemResponseCopyWith(ItineraryItemResponse value, $Res Function(ItineraryItemResponse) _then) = _$ItineraryItemResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(defaultValue: '') String day,@JsonKey(defaultValue: '') String name,@JsonKey(name: 'est_time', defaultValue: '') String estTime,@JsonKey(name: 'actual_time') DateTime? actualTime,@JsonKey(defaultValue: 0) int altitude,@JsonKey(defaultValue: 0.0) double distance,@JsonKey(defaultValue: '') String note,@JsonKey(name: 'image_asset') String? imageAsset,@JsonKey(name: 'is_checked_in', defaultValue: false) bool isCheckedIn,@JsonKey(name: 'checked_in_at') DateTime? checkedInAt,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$ItineraryItemResponseCopyWithImpl<$Res>
    implements $ItineraryItemResponseCopyWith<$Res> {
  _$ItineraryItemResponseCopyWithImpl(this._self, this._then);

  final ItineraryItemResponse _self;
  final $Res Function(ItineraryItemResponse) _then;

/// Create a copy of ItineraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? day = null,Object? name = null,Object? estTime = null,Object? actualTime = freezed,Object? altitude = null,Object? distance = null,Object? note = null,Object? imageAsset = freezed,Object? isCheckedIn = null,Object? checkedInAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,estTime: null == estTime ? _self.estTime : estTime // ignore: cast_nullable_to_non_nullable
as String,actualTime: freezed == actualTime ? _self.actualTime : actualTime // ignore: cast_nullable_to_non_nullable
as DateTime?,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,isCheckedIn: null == isCheckedIn ? _self.isCheckedIn : isCheckedIn // ignore: cast_nullable_to_non_nullable
as bool,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ItineraryItemResponse].
extension ItineraryItemResponsePatterns on ItineraryItemResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItineraryItemResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItineraryItemResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItineraryItemResponse value)  $default,){
final _that = this;
switch (_that) {
case _ItineraryItemResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItineraryItemResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ItineraryItemResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(defaultValue: '')  String day, @JsonKey(defaultValue: '')  String name, @JsonKey(name: 'est_time', defaultValue: '')  String estTime, @JsonKey(name: 'actual_time')  DateTime? actualTime, @JsonKey(defaultValue: 0)  int altitude, @JsonKey(defaultValue: 0.0)  double distance, @JsonKey(defaultValue: '')  String note, @JsonKey(name: 'image_asset')  String? imageAsset, @JsonKey(name: 'is_checked_in', defaultValue: false)  bool isCheckedIn, @JsonKey(name: 'checked_in_at')  DateTime? checkedInAt, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItineraryItemResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.day,_that.name,_that.estTime,_that.actualTime,_that.altitude,_that.distance,_that.note,_that.imageAsset,_that.isCheckedIn,_that.checkedInAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(defaultValue: '')  String day, @JsonKey(defaultValue: '')  String name, @JsonKey(name: 'est_time', defaultValue: '')  String estTime, @JsonKey(name: 'actual_time')  DateTime? actualTime, @JsonKey(defaultValue: 0)  int altitude, @JsonKey(defaultValue: 0.0)  double distance, @JsonKey(defaultValue: '')  String note, @JsonKey(name: 'image_asset')  String? imageAsset, @JsonKey(name: 'is_checked_in', defaultValue: false)  bool isCheckedIn, @JsonKey(name: 'checked_in_at')  DateTime? checkedInAt, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ItineraryItemResponse():
return $default(_that.id,_that.tripId,_that.day,_that.name,_that.estTime,_that.actualTime,_that.altitude,_that.distance,_that.note,_that.imageAsset,_that.isCheckedIn,_that.checkedInAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'trip_id')  String tripId, @JsonKey(defaultValue: '')  String day, @JsonKey(defaultValue: '')  String name, @JsonKey(name: 'est_time', defaultValue: '')  String estTime, @JsonKey(name: 'actual_time')  DateTime? actualTime, @JsonKey(defaultValue: 0)  int altitude, @JsonKey(defaultValue: 0.0)  double distance, @JsonKey(defaultValue: '')  String note, @JsonKey(name: 'image_asset')  String? imageAsset, @JsonKey(name: 'is_checked_in', defaultValue: false)  bool isCheckedIn, @JsonKey(name: 'checked_in_at')  DateTime? checkedInAt, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ItineraryItemResponse() when $default != null:
return $default(_that.id,_that.tripId,_that.day,_that.name,_that.estTime,_that.actualTime,_that.altitude,_that.distance,_that.note,_that.imageAsset,_that.isCheckedIn,_that.checkedInAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItineraryItemResponse implements ItineraryItemResponse {
  const _ItineraryItemResponse({required this.id, @JsonKey(name: 'trip_id') required this.tripId, @JsonKey(defaultValue: '') required this.day, @JsonKey(defaultValue: '') required this.name, @JsonKey(name: 'est_time', defaultValue: '') required this.estTime, @JsonKey(name: 'actual_time') this.actualTime, @JsonKey(defaultValue: 0) required this.altitude, @JsonKey(defaultValue: 0.0) required this.distance, @JsonKey(defaultValue: '') required this.note, @JsonKey(name: 'image_asset') this.imageAsset, @JsonKey(name: 'is_checked_in', defaultValue: false) required this.isCheckedIn, @JsonKey(name: 'checked_in_at') this.checkedInAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _ItineraryItemResponse.fromJson(Map<String, dynamic> json) => _$ItineraryItemResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'trip_id') final  String tripId;
@override@JsonKey(defaultValue: '') final  String day;
@override@JsonKey(defaultValue: '') final  String name;
@override@JsonKey(name: 'est_time', defaultValue: '') final  String estTime;
@override@JsonKey(name: 'actual_time') final  DateTime? actualTime;
@override@JsonKey(defaultValue: 0) final  int altitude;
@override@JsonKey(defaultValue: 0.0) final  double distance;
@override@JsonKey(defaultValue: '') final  String note;
@override@JsonKey(name: 'image_asset') final  String? imageAsset;
@override@JsonKey(name: 'is_checked_in', defaultValue: false) final  bool isCheckedIn;
@override@JsonKey(name: 'checked_in_at') final  DateTime? checkedInAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of ItineraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItineraryItemResponseCopyWith<_ItineraryItemResponse> get copyWith => __$ItineraryItemResponseCopyWithImpl<_ItineraryItemResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItineraryItemResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItineraryItemResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.day, day) || other.day == day)&&(identical(other.name, name) || other.name == name)&&(identical(other.estTime, estTime) || other.estTime == estTime)&&(identical(other.actualTime, actualTime) || other.actualTime == actualTime)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.note, note) || other.note == note)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.isCheckedIn, isCheckedIn) || other.isCheckedIn == isCheckedIn)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,day,name,estTime,actualTime,altitude,distance,note,imageAsset,isCheckedIn,checkedInAt,createdAt,updatedAt);

@override
String toString() {
  return 'ItineraryItemResponse(id: $id, tripId: $tripId, day: $day, name: $name, estTime: $estTime, actualTime: $actualTime, altitude: $altitude, distance: $distance, note: $note, imageAsset: $imageAsset, isCheckedIn: $isCheckedIn, checkedInAt: $checkedInAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ItineraryItemResponseCopyWith<$Res> implements $ItineraryItemResponseCopyWith<$Res> {
  factory _$ItineraryItemResponseCopyWith(_ItineraryItemResponse value, $Res Function(_ItineraryItemResponse) _then) = __$ItineraryItemResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'trip_id') String tripId,@JsonKey(defaultValue: '') String day,@JsonKey(defaultValue: '') String name,@JsonKey(name: 'est_time', defaultValue: '') String estTime,@JsonKey(name: 'actual_time') DateTime? actualTime,@JsonKey(defaultValue: 0) int altitude,@JsonKey(defaultValue: 0.0) double distance,@JsonKey(defaultValue: '') String note,@JsonKey(name: 'image_asset') String? imageAsset,@JsonKey(name: 'is_checked_in', defaultValue: false) bool isCheckedIn,@JsonKey(name: 'checked_in_at') DateTime? checkedInAt,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$ItineraryItemResponseCopyWithImpl<$Res>
    implements _$ItineraryItemResponseCopyWith<$Res> {
  __$ItineraryItemResponseCopyWithImpl(this._self, this._then);

  final _ItineraryItemResponse _self;
  final $Res Function(_ItineraryItemResponse) _then;

/// Create a copy of ItineraryItemResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? day = null,Object? name = null,Object? estTime = null,Object? actualTime = freezed,Object? altitude = null,Object? distance = null,Object? note = null,Object? imageAsset = freezed,Object? isCheckedIn = null,Object? checkedInAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ItineraryItemResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,estTime: null == estTime ? _self.estTime : estTime // ignore: cast_nullable_to_non_nullable
as String,actualTime: freezed == actualTime ? _self.actualTime : actualTime // ignore: cast_nullable_to_non_nullable
as DateTime?,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,isCheckedIn: null == isCheckedIn ? _self.isCheckedIn : isCheckedIn // ignore: cast_nullable_to_non_nullable
as bool,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ItineraryItemRequest {

 String get day; String get name;@JsonKey(name: 'est_time') String get estTime; int? get altitude; double? get distance; String? get note;@JsonKey(name: 'image_asset') String? get imageAsset;
/// Create a copy of ItineraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItineraryItemRequestCopyWith<ItineraryItemRequest> get copyWith => _$ItineraryItemRequestCopyWithImpl<ItineraryItemRequest>(this as ItineraryItemRequest, _$identity);

  /// Serializes this ItineraryItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItineraryItemRequest&&(identical(other.day, day) || other.day == day)&&(identical(other.name, name) || other.name == name)&&(identical(other.estTime, estTime) || other.estTime == estTime)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.note, note) || other.note == note)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,name,estTime,altitude,distance,note,imageAsset);

@override
String toString() {
  return 'ItineraryItemRequest(day: $day, name: $name, estTime: $estTime, altitude: $altitude, distance: $distance, note: $note, imageAsset: $imageAsset)';
}


}

/// @nodoc
abstract mixin class $ItineraryItemRequestCopyWith<$Res>  {
  factory $ItineraryItemRequestCopyWith(ItineraryItemRequest value, $Res Function(ItineraryItemRequest) _then) = _$ItineraryItemRequestCopyWithImpl;
@useResult
$Res call({
 String day, String name,@JsonKey(name: 'est_time') String estTime, int? altitude, double? distance, String? note,@JsonKey(name: 'image_asset') String? imageAsset
});




}
/// @nodoc
class _$ItineraryItemRequestCopyWithImpl<$Res>
    implements $ItineraryItemRequestCopyWith<$Res> {
  _$ItineraryItemRequestCopyWithImpl(this._self, this._then);

  final ItineraryItemRequest _self;
  final $Res Function(ItineraryItemRequest) _then;

/// Create a copy of ItineraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? name = null,Object? estTime = null,Object? altitude = freezed,Object? distance = freezed,Object? note = freezed,Object? imageAsset = freezed,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,estTime: null == estTime ? _self.estTime : estTime // ignore: cast_nullable_to_non_nullable
as String,altitude: freezed == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int?,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ItineraryItemRequest].
extension ItineraryItemRequestPatterns on ItineraryItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItineraryItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItineraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItineraryItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _ItineraryItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItineraryItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ItineraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String day,  String name, @JsonKey(name: 'est_time')  String estTime,  int? altitude,  double? distance,  String? note, @JsonKey(name: 'image_asset')  String? imageAsset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItineraryItemRequest() when $default != null:
return $default(_that.day,_that.name,_that.estTime,_that.altitude,_that.distance,_that.note,_that.imageAsset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String day,  String name, @JsonKey(name: 'est_time')  String estTime,  int? altitude,  double? distance,  String? note, @JsonKey(name: 'image_asset')  String? imageAsset)  $default,) {final _that = this;
switch (_that) {
case _ItineraryItemRequest():
return $default(_that.day,_that.name,_that.estTime,_that.altitude,_that.distance,_that.note,_that.imageAsset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String day,  String name, @JsonKey(name: 'est_time')  String estTime,  int? altitude,  double? distance,  String? note, @JsonKey(name: 'image_asset')  String? imageAsset)?  $default,) {final _that = this;
switch (_that) {
case _ItineraryItemRequest() when $default != null:
return $default(_that.day,_that.name,_that.estTime,_that.altitude,_that.distance,_that.note,_that.imageAsset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItineraryItemRequest implements ItineraryItemRequest {
  const _ItineraryItemRequest({required this.day, required this.name, @JsonKey(name: 'est_time') required this.estTime, this.altitude, this.distance, this.note, @JsonKey(name: 'image_asset') this.imageAsset});
  factory _ItineraryItemRequest.fromJson(Map<String, dynamic> json) => _$ItineraryItemRequestFromJson(json);

@override final  String day;
@override final  String name;
@override@JsonKey(name: 'est_time') final  String estTime;
@override final  int? altitude;
@override final  double? distance;
@override final  String? note;
@override@JsonKey(name: 'image_asset') final  String? imageAsset;

/// Create a copy of ItineraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItineraryItemRequestCopyWith<_ItineraryItemRequest> get copyWith => __$ItineraryItemRequestCopyWithImpl<_ItineraryItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItineraryItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItineraryItemRequest&&(identical(other.day, day) || other.day == day)&&(identical(other.name, name) || other.name == name)&&(identical(other.estTime, estTime) || other.estTime == estTime)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.note, note) || other.note == note)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,name,estTime,altitude,distance,note,imageAsset);

@override
String toString() {
  return 'ItineraryItemRequest(day: $day, name: $name, estTime: $estTime, altitude: $altitude, distance: $distance, note: $note, imageAsset: $imageAsset)';
}


}

/// @nodoc
abstract mixin class _$ItineraryItemRequestCopyWith<$Res> implements $ItineraryItemRequestCopyWith<$Res> {
  factory _$ItineraryItemRequestCopyWith(_ItineraryItemRequest value, $Res Function(_ItineraryItemRequest) _then) = __$ItineraryItemRequestCopyWithImpl;
@override @useResult
$Res call({
 String day, String name,@JsonKey(name: 'est_time') String estTime, int? altitude, double? distance, String? note,@JsonKey(name: 'image_asset') String? imageAsset
});




}
/// @nodoc
class __$ItineraryItemRequestCopyWithImpl<$Res>
    implements _$ItineraryItemRequestCopyWith<$Res> {
  __$ItineraryItemRequestCopyWithImpl(this._self, this._then);

  final _ItineraryItemRequest _self;
  final $Res Function(_ItineraryItemRequest) _then;

/// Create a copy of ItineraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? name = null,Object? estTime = null,Object? altitude = freezed,Object? distance = freezed,Object? note = freezed,Object? imageAsset = freezed,}) {
  return _then(_ItineraryItemRequest(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,estTime: null == estTime ? _self.estTime : estTime // ignore: cast_nullable_to_non_nullable
as String,altitude: freezed == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int?,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
