// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_library_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearLibraryItemRequest {

 String get name; double get weight; String get category; String? get notes;@JsonKey(name: 'is_archived', defaultValue: false) bool? get isArchived;
/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearLibraryItemRequestCopyWith<GearLibraryItemRequest> get copyWith => _$GearLibraryItemRequestCopyWithImpl<GearLibraryItemRequest>(this as GearLibraryItemRequest, _$identity);

  /// Serializes this GearLibraryItemRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearLibraryItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,weight,category,notes,isArchived);

@override
String toString() {
  return 'GearLibraryItemRequest(name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $GearLibraryItemRequestCopyWith<$Res>  {
  factory $GearLibraryItemRequestCopyWith(GearLibraryItemRequest value, $Res Function(GearLibraryItemRequest) _then) = _$GearLibraryItemRequestCopyWithImpl;
@useResult
$Res call({
 String name, double weight, String category, String? notes,@JsonKey(name: 'is_archived', defaultValue: false) bool? isArchived
});




}
/// @nodoc
class _$GearLibraryItemRequestCopyWithImpl<$Res>
    implements $GearLibraryItemRequestCopyWith<$Res> {
  _$GearLibraryItemRequestCopyWithImpl(this._self, this._then);

  final GearLibraryItemRequest _self;
  final $Res Function(GearLibraryItemRequest) _then;

/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: freezed == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [GearLibraryItemRequest].
extension GearLibraryItemRequestPatterns on GearLibraryItemRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearLibraryItemRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearLibraryItemRequest value)  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItemRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearLibraryItemRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double weight,  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool? isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
return $default(_that.name,_that.weight,_that.category,_that.notes,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double weight,  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool? isArchived)  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItemRequest():
return $default(_that.name,_that.weight,_that.category,_that.notes,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double weight,  String category,  String? notes, @JsonKey(name: 'is_archived', defaultValue: false)  bool? isArchived)?  $default,) {final _that = this;
switch (_that) {
case _GearLibraryItemRequest() when $default != null:
return $default(_that.name,_that.weight,_that.category,_that.notes,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearLibraryItemRequest implements GearLibraryItemRequest {
  const _GearLibraryItemRequest({required this.name, required this.weight, required this.category, this.notes, @JsonKey(name: 'is_archived', defaultValue: false) this.isArchived});
  factory _GearLibraryItemRequest.fromJson(Map<String, dynamic> json) => _$GearLibraryItemRequestFromJson(json);

@override final  String name;
@override final  double weight;
@override final  String category;
@override final  String? notes;
@override@JsonKey(name: 'is_archived', defaultValue: false) final  bool? isArchived;

/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearLibraryItemRequestCopyWith<_GearLibraryItemRequest> get copyWith => __$GearLibraryItemRequestCopyWithImpl<_GearLibraryItemRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearLibraryItemRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearLibraryItemRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.category, category) || other.category == category)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,weight,category,notes,isArchived);

@override
String toString() {
  return 'GearLibraryItemRequest(name: $name, weight: $weight, category: $category, notes: $notes, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$GearLibraryItemRequestCopyWith<$Res> implements $GearLibraryItemRequestCopyWith<$Res> {
  factory _$GearLibraryItemRequestCopyWith(_GearLibraryItemRequest value, $Res Function(_GearLibraryItemRequest) _then) = __$GearLibraryItemRequestCopyWithImpl;
@override @useResult
$Res call({
 String name, double weight, String category, String? notes,@JsonKey(name: 'is_archived', defaultValue: false) bool? isArchived
});




}
/// @nodoc
class __$GearLibraryItemRequestCopyWithImpl<$Res>
    implements _$GearLibraryItemRequestCopyWith<$Res> {
  __$GearLibraryItemRequestCopyWithImpl(this._self, this._then);

  final _GearLibraryItemRequest _self;
  final $Res Function(_GearLibraryItemRequest) _then;

/// Create a copy of GearLibraryItemRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? weight = null,Object? category = null,Object? notes = freezed,Object? isArchived = freezed,}) {
  return _then(_GearLibraryItemRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isArchived: freezed == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
