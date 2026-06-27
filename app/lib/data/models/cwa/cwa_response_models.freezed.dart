// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cwa_response_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CwaApiResponse {

@JsonKey(defaultValue: 'false') String get success;@JsonKey(name: 'records', readValue: _readCwaRecords) CwaRecords get records;
/// Create a copy of CwaApiResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CwaApiResponseCopyWith<CwaApiResponse> get copyWith => _$CwaApiResponseCopyWithImpl<CwaApiResponse>(this as CwaApiResponse, _$identity);

  /// Serializes this CwaApiResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CwaApiResponse&&(identical(other.success, success) || other.success == success)&&(identical(other.records, records) || other.records == records));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,records);

@override
String toString() {
  return 'CwaApiResponse(success: $success, records: $records)';
}


}

/// @nodoc
abstract mixin class $CwaApiResponseCopyWith<$Res>  {
  factory $CwaApiResponseCopyWith(CwaApiResponse value, $Res Function(CwaApiResponse) _then) = _$CwaApiResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(defaultValue: 'false') String success,@JsonKey(name: 'records', readValue: _readCwaRecords) CwaRecords records
});


$CwaRecordsCopyWith<$Res> get records;

}
/// @nodoc
class _$CwaApiResponseCopyWithImpl<$Res>
    implements $CwaApiResponseCopyWith<$Res> {
  _$CwaApiResponseCopyWithImpl(this._self, this._then);

  final CwaApiResponse _self;
  final $Res Function(CwaApiResponse) _then;

/// Create a copy of CwaApiResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? records = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as String,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as CwaRecords,
  ));
}
/// Create a copy of CwaApiResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CwaRecordsCopyWith<$Res> get records {
  
  return $CwaRecordsCopyWith<$Res>(_self.records, (value) {
    return _then(_self.copyWith(records: value));
  });
}
}


/// Adds pattern-matching-related methods to [CwaApiResponse].
extension CwaApiResponsePatterns on CwaApiResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CwaApiResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CwaApiResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CwaApiResponse value)  $default,){
final _that = this;
switch (_that) {
case _CwaApiResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CwaApiResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CwaApiResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: 'false')  String success, @JsonKey(name: 'records', readValue: _readCwaRecords)  CwaRecords records)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CwaApiResponse() when $default != null:
return $default(_that.success,_that.records);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(defaultValue: 'false')  String success, @JsonKey(name: 'records', readValue: _readCwaRecords)  CwaRecords records)  $default,) {final _that = this;
switch (_that) {
case _CwaApiResponse():
return $default(_that.success,_that.records);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(defaultValue: 'false')  String success, @JsonKey(name: 'records', readValue: _readCwaRecords)  CwaRecords records)?  $default,) {final _that = this;
switch (_that) {
case _CwaApiResponse() when $default != null:
return $default(_that.success,_that.records);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CwaApiResponse implements CwaApiResponse {
  const _CwaApiResponse({@JsonKey(defaultValue: 'false') required this.success, @JsonKey(name: 'records', readValue: _readCwaRecords) required this.records});
  factory _CwaApiResponse.fromJson(Map<String, dynamic> json) => _$CwaApiResponseFromJson(json);

@override@JsonKey(defaultValue: 'false') final  String success;
@override@JsonKey(name: 'records', readValue: _readCwaRecords) final  CwaRecords records;

/// Create a copy of CwaApiResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CwaApiResponseCopyWith<_CwaApiResponse> get copyWith => __$CwaApiResponseCopyWithImpl<_CwaApiResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CwaApiResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CwaApiResponse&&(identical(other.success, success) || other.success == success)&&(identical(other.records, records) || other.records == records));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,records);

@override
String toString() {
  return 'CwaApiResponse(success: $success, records: $records)';
}


}

/// @nodoc
abstract mixin class _$CwaApiResponseCopyWith<$Res> implements $CwaApiResponseCopyWith<$Res> {
  factory _$CwaApiResponseCopyWith(_CwaApiResponse value, $Res Function(_CwaApiResponse) _then) = __$CwaApiResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(defaultValue: 'false') String success,@JsonKey(name: 'records', readValue: _readCwaRecords) CwaRecords records
});


@override $CwaRecordsCopyWith<$Res> get records;

}
/// @nodoc
class __$CwaApiResponseCopyWithImpl<$Res>
    implements _$CwaApiResponseCopyWith<$Res> {
  __$CwaApiResponseCopyWithImpl(this._self, this._then);

  final _CwaApiResponse _self;
  final $Res Function(_CwaApiResponse) _then;

/// Create a copy of CwaApiResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? records = null,}) {
  return _then(_CwaApiResponse(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as String,records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as CwaRecords,
  ));
}

/// Create a copy of CwaApiResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CwaRecordsCopyWith<$Res> get records {
  
  return $CwaRecordsCopyWith<$Res>(_self.records, (value) {
    return _then(_self.copyWith(records: value));
  });
}
}


/// @nodoc
mixin _$CwaRecords {

@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: []) List<CwaLocations> get locationsList;
/// Create a copy of CwaRecords
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CwaRecordsCopyWith<CwaRecords> get copyWith => _$CwaRecordsCopyWithImpl<CwaRecords>(this as CwaRecords, _$identity);

  /// Serializes this CwaRecords to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CwaRecords&&const DeepCollectionEquality().equals(other.locationsList, locationsList));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(locationsList));

@override
String toString() {
  return 'CwaRecords(locationsList: $locationsList)';
}


}

/// @nodoc
abstract mixin class $CwaRecordsCopyWith<$Res>  {
  factory $CwaRecordsCopyWith(CwaRecords value, $Res Function(CwaRecords) _then) = _$CwaRecordsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: []) List<CwaLocations> locationsList
});




}
/// @nodoc
class _$CwaRecordsCopyWithImpl<$Res>
    implements $CwaRecordsCopyWith<$Res> {
  _$CwaRecordsCopyWithImpl(this._self, this._then);

  final CwaRecords _self;
  final $Res Function(CwaRecords) _then;

/// Create a copy of CwaRecords
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locationsList = null,}) {
  return _then(_self.copyWith(
locationsList: null == locationsList ? _self.locationsList : locationsList // ignore: cast_nullable_to_non_nullable
as List<CwaLocations>,
  ));
}

}


/// Adds pattern-matching-related methods to [CwaRecords].
extension CwaRecordsPatterns on CwaRecords {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CwaRecords value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CwaRecords() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CwaRecords value)  $default,){
final _that = this;
switch (_that) {
case _CwaRecords():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CwaRecords value)?  $default,){
final _that = this;
switch (_that) {
case _CwaRecords() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: [])  List<CwaLocations> locationsList)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CwaRecords() when $default != null:
return $default(_that.locationsList);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: [])  List<CwaLocations> locationsList)  $default,) {final _that = this;
switch (_that) {
case _CwaRecords():
return $default(_that.locationsList);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: [])  List<CwaLocations> locationsList)?  $default,) {final _that = this;
switch (_that) {
case _CwaRecords() when $default != null:
return $default(_that.locationsList);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CwaRecords implements CwaRecords {
  const _CwaRecords({@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: []) required final  List<CwaLocations> locationsList}): _locationsList = locationsList;
  factory _CwaRecords.fromJson(Map<String, dynamic> json) => _$CwaRecordsFromJson(json);

 final  List<CwaLocations> _locationsList;
@override@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: []) List<CwaLocations> get locationsList {
  if (_locationsList is EqualUnmodifiableListView) return _locationsList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locationsList);
}


/// Create a copy of CwaRecords
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CwaRecordsCopyWith<_CwaRecords> get copyWith => __$CwaRecordsCopyWithImpl<_CwaRecords>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CwaRecordsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CwaRecords&&const DeepCollectionEquality().equals(other._locationsList, _locationsList));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_locationsList));

@override
String toString() {
  return 'CwaRecords(locationsList: $locationsList)';
}


}

/// @nodoc
abstract mixin class _$CwaRecordsCopyWith<$Res> implements $CwaRecordsCopyWith<$Res> {
  factory _$CwaRecordsCopyWith(_CwaRecords value, $Res Function(_CwaRecords) _then) = __$CwaRecordsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Locations', readValue: _readCwaKey, defaultValue: []) List<CwaLocations> locationsList
});




}
/// @nodoc
class __$CwaRecordsCopyWithImpl<$Res>
    implements _$CwaRecordsCopyWith<$Res> {
  __$CwaRecordsCopyWithImpl(this._self, this._then);

  final _CwaRecords _self;
  final $Res Function(_CwaRecords) _then;

/// Create a copy of CwaRecords
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locationsList = null,}) {
  return _then(_CwaRecords(
locationsList: null == locationsList ? _self._locationsList : locationsList // ignore: cast_nullable_to_non_nullable
as List<CwaLocations>,
  ));
}


}


/// @nodoc
mixin _$CwaLocations {

@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '') String get datasetDescription;@JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '') String get locationsName;@JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: []) List<CwaLocation> get location;
/// Create a copy of CwaLocations
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CwaLocationsCopyWith<CwaLocations> get copyWith => _$CwaLocationsCopyWithImpl<CwaLocations>(this as CwaLocations, _$identity);

  /// Serializes this CwaLocations to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CwaLocations&&(identical(other.datasetDescription, datasetDescription) || other.datasetDescription == datasetDescription)&&(identical(other.locationsName, locationsName) || other.locationsName == locationsName)&&const DeepCollectionEquality().equals(other.location, location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,datasetDescription,locationsName,const DeepCollectionEquality().hash(location));

@override
String toString() {
  return 'CwaLocations(datasetDescription: $datasetDescription, locationsName: $locationsName, location: $location)';
}


}

/// @nodoc
abstract mixin class $CwaLocationsCopyWith<$Res>  {
  factory $CwaLocationsCopyWith(CwaLocations value, $Res Function(CwaLocations) _then) = _$CwaLocationsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '') String datasetDescription,@JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '') String locationsName,@JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: []) List<CwaLocation> location
});




}
/// @nodoc
class _$CwaLocationsCopyWithImpl<$Res>
    implements $CwaLocationsCopyWith<$Res> {
  _$CwaLocationsCopyWithImpl(this._self, this._then);

  final CwaLocations _self;
  final $Res Function(CwaLocations) _then;

/// Create a copy of CwaLocations
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? datasetDescription = null,Object? locationsName = null,Object? location = null,}) {
  return _then(_self.copyWith(
datasetDescription: null == datasetDescription ? _self.datasetDescription : datasetDescription // ignore: cast_nullable_to_non_nullable
as String,locationsName: null == locationsName ? _self.locationsName : locationsName // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as List<CwaLocation>,
  ));
}

}


/// Adds pattern-matching-related methods to [CwaLocations].
extension CwaLocationsPatterns on CwaLocations {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CwaLocations value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CwaLocations() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CwaLocations value)  $default,){
final _that = this;
switch (_that) {
case _CwaLocations():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CwaLocations value)?  $default,){
final _that = this;
switch (_that) {
case _CwaLocations() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '')  String datasetDescription, @JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '')  String locationsName, @JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: [])  List<CwaLocation> location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CwaLocations() when $default != null:
return $default(_that.datasetDescription,_that.locationsName,_that.location);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '')  String datasetDescription, @JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '')  String locationsName, @JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: [])  List<CwaLocation> location)  $default,) {final _that = this;
switch (_that) {
case _CwaLocations():
return $default(_that.datasetDescription,_that.locationsName,_that.location);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '')  String datasetDescription, @JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '')  String locationsName, @JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: [])  List<CwaLocation> location)?  $default,) {final _that = this;
switch (_that) {
case _CwaLocations() when $default != null:
return $default(_that.datasetDescription,_that.locationsName,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CwaLocations implements CwaLocations {
  const _CwaLocations({@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '') required this.datasetDescription, @JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '') required this.locationsName, @JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: []) required final  List<CwaLocation> location}): _location = location;
  factory _CwaLocations.fromJson(Map<String, dynamic> json) => _$CwaLocationsFromJson(json);

@override@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '') final  String datasetDescription;
@override@JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '') final  String locationsName;
 final  List<CwaLocation> _location;
@override@JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: []) List<CwaLocation> get location {
  if (_location is EqualUnmodifiableListView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_location);
}


/// Create a copy of CwaLocations
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CwaLocationsCopyWith<_CwaLocations> get copyWith => __$CwaLocationsCopyWithImpl<_CwaLocations>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CwaLocationsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CwaLocations&&(identical(other.datasetDescription, datasetDescription) || other.datasetDescription == datasetDescription)&&(identical(other.locationsName, locationsName) || other.locationsName == locationsName)&&const DeepCollectionEquality().equals(other._location, _location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,datasetDescription,locationsName,const DeepCollectionEquality().hash(_location));

@override
String toString() {
  return 'CwaLocations(datasetDescription: $datasetDescription, locationsName: $locationsName, location: $location)';
}


}

/// @nodoc
abstract mixin class _$CwaLocationsCopyWith<$Res> implements $CwaLocationsCopyWith<$Res> {
  factory _$CwaLocationsCopyWith(_CwaLocations value, $Res Function(_CwaLocations) _then) = __$CwaLocationsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'DatasetDescription', readValue: _readCwaKey, defaultValue: '') String datasetDescription,@JsonKey(name: 'LocationsName', readValue: _readCwaKey, defaultValue: '') String locationsName,@JsonKey(name: 'Location', readValue: _readCwaKey, defaultValue: []) List<CwaLocation> location
});




}
/// @nodoc
class __$CwaLocationsCopyWithImpl<$Res>
    implements _$CwaLocationsCopyWith<$Res> {
  __$CwaLocationsCopyWithImpl(this._self, this._then);

  final _CwaLocations _self;
  final $Res Function(_CwaLocations) _then;

/// Create a copy of CwaLocations
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? datasetDescription = null,Object? locationsName = null,Object? location = null,}) {
  return _then(_CwaLocations(
datasetDescription: null == datasetDescription ? _self.datasetDescription : datasetDescription // ignore: cast_nullable_to_non_nullable
as String,locationsName: null == locationsName ? _self.locationsName : locationsName // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as List<CwaLocation>,
  ));
}


}


/// @nodoc
mixin _$CwaLocation {

@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '') String get locationName;@JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: []) List<CwaWeatherElement> get weatherElement;
/// Create a copy of CwaLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CwaLocationCopyWith<CwaLocation> get copyWith => _$CwaLocationCopyWithImpl<CwaLocation>(this as CwaLocation, _$identity);

  /// Serializes this CwaLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CwaLocation&&(identical(other.locationName, locationName) || other.locationName == locationName)&&const DeepCollectionEquality().equals(other.weatherElement, weatherElement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,locationName,const DeepCollectionEquality().hash(weatherElement));

@override
String toString() {
  return 'CwaLocation(locationName: $locationName, weatherElement: $weatherElement)';
}


}

/// @nodoc
abstract mixin class $CwaLocationCopyWith<$Res>  {
  factory $CwaLocationCopyWith(CwaLocation value, $Res Function(CwaLocation) _then) = _$CwaLocationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '') String locationName,@JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: []) List<CwaWeatherElement> weatherElement
});




}
/// @nodoc
class _$CwaLocationCopyWithImpl<$Res>
    implements $CwaLocationCopyWith<$Res> {
  _$CwaLocationCopyWithImpl(this._self, this._then);

  final CwaLocation _self;
  final $Res Function(CwaLocation) _then;

/// Create a copy of CwaLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locationName = null,Object? weatherElement = null,}) {
  return _then(_self.copyWith(
locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,weatherElement: null == weatherElement ? _self.weatherElement : weatherElement // ignore: cast_nullable_to_non_nullable
as List<CwaWeatherElement>,
  ));
}

}


/// Adds pattern-matching-related methods to [CwaLocation].
extension CwaLocationPatterns on CwaLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CwaLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CwaLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CwaLocation value)  $default,){
final _that = this;
switch (_that) {
case _CwaLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CwaLocation value)?  $default,){
final _that = this;
switch (_that) {
case _CwaLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '')  String locationName, @JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: [])  List<CwaWeatherElement> weatherElement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CwaLocation() when $default != null:
return $default(_that.locationName,_that.weatherElement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '')  String locationName, @JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: [])  List<CwaWeatherElement> weatherElement)  $default,) {final _that = this;
switch (_that) {
case _CwaLocation():
return $default(_that.locationName,_that.weatherElement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '')  String locationName, @JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: [])  List<CwaWeatherElement> weatherElement)?  $default,) {final _that = this;
switch (_that) {
case _CwaLocation() when $default != null:
return $default(_that.locationName,_that.weatherElement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CwaLocation implements CwaLocation {
  const _CwaLocation({@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '') required this.locationName, @JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: []) required final  List<CwaWeatherElement> weatherElement}): _weatherElement = weatherElement;
  factory _CwaLocation.fromJson(Map<String, dynamic> json) => _$CwaLocationFromJson(json);

@override@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '') final  String locationName;
 final  List<CwaWeatherElement> _weatherElement;
@override@JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: []) List<CwaWeatherElement> get weatherElement {
  if (_weatherElement is EqualUnmodifiableListView) return _weatherElement;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weatherElement);
}


/// Create a copy of CwaLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CwaLocationCopyWith<_CwaLocation> get copyWith => __$CwaLocationCopyWithImpl<_CwaLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CwaLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CwaLocation&&(identical(other.locationName, locationName) || other.locationName == locationName)&&const DeepCollectionEquality().equals(other._weatherElement, _weatherElement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,locationName,const DeepCollectionEquality().hash(_weatherElement));

@override
String toString() {
  return 'CwaLocation(locationName: $locationName, weatherElement: $weatherElement)';
}


}

/// @nodoc
abstract mixin class _$CwaLocationCopyWith<$Res> implements $CwaLocationCopyWith<$Res> {
  factory _$CwaLocationCopyWith(_CwaLocation value, $Res Function(_CwaLocation) _then) = __$CwaLocationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'LocationName', readValue: _readCwaKey, defaultValue: '') String locationName,@JsonKey(name: 'WeatherElement', readValue: _readCwaKey, defaultValue: []) List<CwaWeatherElement> weatherElement
});




}
/// @nodoc
class __$CwaLocationCopyWithImpl<$Res>
    implements _$CwaLocationCopyWith<$Res> {
  __$CwaLocationCopyWithImpl(this._self, this._then);

  final _CwaLocation _self;
  final $Res Function(_CwaLocation) _then;

/// Create a copy of CwaLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locationName = null,Object? weatherElement = null,}) {
  return _then(_CwaLocation(
locationName: null == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String,weatherElement: null == weatherElement ? _self._weatherElement : weatherElement // ignore: cast_nullable_to_non_nullable
as List<CwaWeatherElement>,
  ));
}


}


/// @nodoc
mixin _$CwaWeatherElement {

@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '') String get elementName;@JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: []) List<CwaTime> get time;
/// Create a copy of CwaWeatherElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CwaWeatherElementCopyWith<CwaWeatherElement> get copyWith => _$CwaWeatherElementCopyWithImpl<CwaWeatherElement>(this as CwaWeatherElement, _$identity);

  /// Serializes this CwaWeatherElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CwaWeatherElement&&(identical(other.elementName, elementName) || other.elementName == elementName)&&const DeepCollectionEquality().equals(other.time, time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,elementName,const DeepCollectionEquality().hash(time));

@override
String toString() {
  return 'CwaWeatherElement(elementName: $elementName, time: $time)';
}


}

/// @nodoc
abstract mixin class $CwaWeatherElementCopyWith<$Res>  {
  factory $CwaWeatherElementCopyWith(CwaWeatherElement value, $Res Function(CwaWeatherElement) _then) = _$CwaWeatherElementCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '') String elementName,@JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: []) List<CwaTime> time
});




}
/// @nodoc
class _$CwaWeatherElementCopyWithImpl<$Res>
    implements $CwaWeatherElementCopyWith<$Res> {
  _$CwaWeatherElementCopyWithImpl(this._self, this._then);

  final CwaWeatherElement _self;
  final $Res Function(CwaWeatherElement) _then;

/// Create a copy of CwaWeatherElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? elementName = null,Object? time = null,}) {
  return _then(_self.copyWith(
elementName: null == elementName ? _self.elementName : elementName // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as List<CwaTime>,
  ));
}

}


/// Adds pattern-matching-related methods to [CwaWeatherElement].
extension CwaWeatherElementPatterns on CwaWeatherElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CwaWeatherElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CwaWeatherElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CwaWeatherElement value)  $default,){
final _that = this;
switch (_that) {
case _CwaWeatherElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CwaWeatherElement value)?  $default,){
final _that = this;
switch (_that) {
case _CwaWeatherElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '')  String elementName, @JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: [])  List<CwaTime> time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CwaWeatherElement() when $default != null:
return $default(_that.elementName,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '')  String elementName, @JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: [])  List<CwaTime> time)  $default,) {final _that = this;
switch (_that) {
case _CwaWeatherElement():
return $default(_that.elementName,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '')  String elementName, @JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: [])  List<CwaTime> time)?  $default,) {final _that = this;
switch (_that) {
case _CwaWeatherElement() when $default != null:
return $default(_that.elementName,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CwaWeatherElement implements CwaWeatherElement {
  const _CwaWeatherElement({@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '') required this.elementName, @JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: []) required final  List<CwaTime> time}): _time = time;
  factory _CwaWeatherElement.fromJson(Map<String, dynamic> json) => _$CwaWeatherElementFromJson(json);

@override@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '') final  String elementName;
 final  List<CwaTime> _time;
@override@JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: []) List<CwaTime> get time {
  if (_time is EqualUnmodifiableListView) return _time;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_time);
}


/// Create a copy of CwaWeatherElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CwaWeatherElementCopyWith<_CwaWeatherElement> get copyWith => __$CwaWeatherElementCopyWithImpl<_CwaWeatherElement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CwaWeatherElementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CwaWeatherElement&&(identical(other.elementName, elementName) || other.elementName == elementName)&&const DeepCollectionEquality().equals(other._time, _time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,elementName,const DeepCollectionEquality().hash(_time));

@override
String toString() {
  return 'CwaWeatherElement(elementName: $elementName, time: $time)';
}


}

/// @nodoc
abstract mixin class _$CwaWeatherElementCopyWith<$Res> implements $CwaWeatherElementCopyWith<$Res> {
  factory _$CwaWeatherElementCopyWith(_CwaWeatherElement value, $Res Function(_CwaWeatherElement) _then) = __$CwaWeatherElementCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'ElementName', readValue: _readCwaKey, defaultValue: '') String elementName,@JsonKey(name: 'Time', readValue: _readCwaKey, defaultValue: []) List<CwaTime> time
});




}
/// @nodoc
class __$CwaWeatherElementCopyWithImpl<$Res>
    implements _$CwaWeatherElementCopyWith<$Res> {
  __$CwaWeatherElementCopyWithImpl(this._self, this._then);

  final _CwaWeatherElement _self;
  final $Res Function(_CwaWeatherElement) _then;

/// Create a copy of CwaWeatherElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? elementName = null,Object? time = null,}) {
  return _then(_CwaWeatherElement(
elementName: null == elementName ? _self.elementName : elementName // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self._time : time // ignore: cast_nullable_to_non_nullable
as List<CwaTime>,
  ));
}


}


/// @nodoc
mixin _$CwaTime {

@JsonKey(name: 'StartTime', readValue: _readCwaKey) DateTime get startTime;@JsonKey(name: 'EndTime', readValue: _readCwaKey) DateTime? get endTime;@JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: []) List<Map<String, dynamic>> get elementValue;
/// Create a copy of CwaTime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CwaTimeCopyWith<CwaTime> get copyWith => _$CwaTimeCopyWithImpl<CwaTime>(this as CwaTime, _$identity);

  /// Serializes this CwaTime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CwaTime&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&const DeepCollectionEquality().equals(other.elementValue, elementValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,const DeepCollectionEquality().hash(elementValue));

@override
String toString() {
  return 'CwaTime(startTime: $startTime, endTime: $endTime, elementValue: $elementValue)';
}


}

/// @nodoc
abstract mixin class $CwaTimeCopyWith<$Res>  {
  factory $CwaTimeCopyWith(CwaTime value, $Res Function(CwaTime) _then) = _$CwaTimeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'StartTime', readValue: _readCwaKey) DateTime startTime,@JsonKey(name: 'EndTime', readValue: _readCwaKey) DateTime? endTime,@JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: []) List<Map<String, dynamic>> elementValue
});




}
/// @nodoc
class _$CwaTimeCopyWithImpl<$Res>
    implements $CwaTimeCopyWith<$Res> {
  _$CwaTimeCopyWithImpl(this._self, this._then);

  final CwaTime _self;
  final $Res Function(CwaTime) _then;

/// Create a copy of CwaTime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startTime = null,Object? endTime = freezed,Object? elementValue = null,}) {
  return _then(_self.copyWith(
startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,elementValue: null == elementValue ? _self.elementValue : elementValue // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [CwaTime].
extension CwaTimePatterns on CwaTime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CwaTime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CwaTime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CwaTime value)  $default,){
final _that = this;
switch (_that) {
case _CwaTime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CwaTime value)?  $default,){
final _that = this;
switch (_that) {
case _CwaTime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'StartTime', readValue: _readCwaKey)  DateTime startTime, @JsonKey(name: 'EndTime', readValue: _readCwaKey)  DateTime? endTime, @JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: [])  List<Map<String, dynamic>> elementValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CwaTime() when $default != null:
return $default(_that.startTime,_that.endTime,_that.elementValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'StartTime', readValue: _readCwaKey)  DateTime startTime, @JsonKey(name: 'EndTime', readValue: _readCwaKey)  DateTime? endTime, @JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: [])  List<Map<String, dynamic>> elementValue)  $default,) {final _that = this;
switch (_that) {
case _CwaTime():
return $default(_that.startTime,_that.endTime,_that.elementValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'StartTime', readValue: _readCwaKey)  DateTime startTime, @JsonKey(name: 'EndTime', readValue: _readCwaKey)  DateTime? endTime, @JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: [])  List<Map<String, dynamic>> elementValue)?  $default,) {final _that = this;
switch (_that) {
case _CwaTime() when $default != null:
return $default(_that.startTime,_that.endTime,_that.elementValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CwaTime extends CwaTime {
  const _CwaTime({@JsonKey(name: 'StartTime', readValue: _readCwaKey) required this.startTime, @JsonKey(name: 'EndTime', readValue: _readCwaKey) this.endTime, @JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: []) required final  List<Map<String, dynamic>> elementValue}): _elementValue = elementValue,super._();
  factory _CwaTime.fromJson(Map<String, dynamic> json) => _$CwaTimeFromJson(json);

@override@JsonKey(name: 'StartTime', readValue: _readCwaKey) final  DateTime startTime;
@override@JsonKey(name: 'EndTime', readValue: _readCwaKey) final  DateTime? endTime;
 final  List<Map<String, dynamic>> _elementValue;
@override@JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: []) List<Map<String, dynamic>> get elementValue {
  if (_elementValue is EqualUnmodifiableListView) return _elementValue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elementValue);
}


/// Create a copy of CwaTime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CwaTimeCopyWith<_CwaTime> get copyWith => __$CwaTimeCopyWithImpl<_CwaTime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CwaTimeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CwaTime&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&const DeepCollectionEquality().equals(other._elementValue, _elementValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startTime,endTime,const DeepCollectionEquality().hash(_elementValue));

@override
String toString() {
  return 'CwaTime(startTime: $startTime, endTime: $endTime, elementValue: $elementValue)';
}


}

/// @nodoc
abstract mixin class _$CwaTimeCopyWith<$Res> implements $CwaTimeCopyWith<$Res> {
  factory _$CwaTimeCopyWith(_CwaTime value, $Res Function(_CwaTime) _then) = __$CwaTimeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'StartTime', readValue: _readCwaKey) DateTime startTime,@JsonKey(name: 'EndTime', readValue: _readCwaKey) DateTime? endTime,@JsonKey(name: 'ElementValue', readValue: _readCwaKey, defaultValue: []) List<Map<String, dynamic>> elementValue
});




}
/// @nodoc
class __$CwaTimeCopyWithImpl<$Res>
    implements _$CwaTimeCopyWith<$Res> {
  __$CwaTimeCopyWithImpl(this._self, this._then);

  final _CwaTime _self;
  final $Res Function(_CwaTime) _then;

/// Create a copy of CwaTime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startTime = null,Object? endTime = freezed,Object? elementValue = null,}) {
  return _then(_CwaTime(
startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,elementValue: null == elementValue ? _self._elementValue : elementValue // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
