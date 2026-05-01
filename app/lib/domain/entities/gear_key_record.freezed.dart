// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_key_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearKeyRecord {

 String get key; String get title; String get visibility; DateTime get uploadedAt;
/// Create a copy of GearKeyRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearKeyRecordCopyWith<GearKeyRecord> get copyWith => _$GearKeyRecordCopyWithImpl<GearKeyRecord>(this as GearKeyRecord, _$identity);

  /// Serializes this GearKeyRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearKeyRecord&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,title,visibility,uploadedAt);

@override
String toString() {
  return 'GearKeyRecord(key: $key, title: $title, visibility: $visibility, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class $GearKeyRecordCopyWith<$Res>  {
  factory $GearKeyRecordCopyWith(GearKeyRecord value, $Res Function(GearKeyRecord) _then) = _$GearKeyRecordCopyWithImpl;
@useResult
$Res call({
 String key, String title, String visibility, DateTime uploadedAt
});




}
/// @nodoc
class _$GearKeyRecordCopyWithImpl<$Res>
    implements $GearKeyRecordCopyWith<$Res> {
  _$GearKeyRecordCopyWithImpl(this._self, this._then);

  final GearKeyRecord _self;
  final $Res Function(GearKeyRecord) _then;

/// Create a copy of GearKeyRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? title = null,Object? visibility = null,Object? uploadedAt = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GearKeyRecord].
extension GearKeyRecordPatterns on GearKeyRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearKeyRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearKeyRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearKeyRecord value)  $default,){
final _that = this;
switch (_that) {
case _GearKeyRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearKeyRecord value)?  $default,){
final _that = this;
switch (_that) {
case _GearKeyRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String title,  String visibility,  DateTime uploadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearKeyRecord() when $default != null:
return $default(_that.key,_that.title,_that.visibility,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String title,  String visibility,  DateTime uploadedAt)  $default,) {final _that = this;
switch (_that) {
case _GearKeyRecord():
return $default(_that.key,_that.title,_that.visibility,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String title,  String visibility,  DateTime uploadedAt)?  $default,) {final _that = this;
switch (_that) {
case _GearKeyRecord() when $default != null:
return $default(_that.key,_that.title,_that.visibility,_that.uploadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearKeyRecord implements GearKeyRecord {
  const _GearKeyRecord({required this.key, required this.title, this.visibility = 'private', required this.uploadedAt});
  factory _GearKeyRecord.fromJson(Map<String, dynamic> json) => _$GearKeyRecordFromJson(json);

@override final  String key;
@override final  String title;
@override@JsonKey() final  String visibility;
@override final  DateTime uploadedAt;

/// Create a copy of GearKeyRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearKeyRecordCopyWith<_GearKeyRecord> get copyWith => __$GearKeyRecordCopyWithImpl<_GearKeyRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearKeyRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearKeyRecord&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,title,visibility,uploadedAt);

@override
String toString() {
  return 'GearKeyRecord(key: $key, title: $title, visibility: $visibility, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class _$GearKeyRecordCopyWith<$Res> implements $GearKeyRecordCopyWith<$Res> {
  factory _$GearKeyRecordCopyWith(_GearKeyRecord value, $Res Function(_GearKeyRecord) _then) = __$GearKeyRecordCopyWithImpl;
@override @useResult
$Res call({
 String key, String title, String visibility, DateTime uploadedAt
});




}
/// @nodoc
class __$GearKeyRecordCopyWithImpl<$Res>
    implements _$GearKeyRecordCopyWith<$Res> {
  __$GearKeyRecordCopyWithImpl(this._self, this._then);

  final _GearKeyRecord _self;
  final $Res Function(_GearKeyRecord) _then;

/// Create a copy of GearKeyRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? title = null,Object? visibility = null,Object? uploadedAt = null,}) {
  return _then(_GearKeyRecord(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
