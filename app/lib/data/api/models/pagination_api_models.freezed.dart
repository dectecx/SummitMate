// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaginationMetadata {

@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'has_more') bool get hasMore;@JsonKey(name: 'page') int get page;@JsonKey(name: 'limit') int get limit;@JsonKey(name: 'total') int get total;
/// Create a copy of PaginationMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginationMetadataCopyWith<PaginationMetadata> get copyWith => _$PaginationMetadataCopyWithImpl<PaginationMetadata>(this as PaginationMetadata, _$identity);

  /// Serializes this PaginationMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginationMetadata&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nextCursor,hasMore,page,limit,total);

@override
String toString() {
  return 'PaginationMetadata(nextCursor: $nextCursor, hasMore: $hasMore, page: $page, limit: $limit, total: $total)';
}


}

/// @nodoc
abstract mixin class $PaginationMetadataCopyWith<$Res>  {
  factory $PaginationMetadataCopyWith(PaginationMetadata value, $Res Function(PaginationMetadata) _then) = _$PaginationMetadataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'has_more') bool hasMore,@JsonKey(name: 'page') int page,@JsonKey(name: 'limit') int limit,@JsonKey(name: 'total') int total
});




}
/// @nodoc
class _$PaginationMetadataCopyWithImpl<$Res>
    implements $PaginationMetadataCopyWith<$Res> {
  _$PaginationMetadataCopyWithImpl(this._self, this._then);

  final PaginationMetadata _self;
  final $Res Function(PaginationMetadata) _then;

/// Create a copy of PaginationMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nextCursor = freezed,Object? hasMore = null,Object? page = null,Object? limit = null,Object? total = null,}) {
  return _then(_self.copyWith(
nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginationMetadata].
extension PaginationMetadataPatterns on PaginationMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginationMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginationMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginationMetadata value)  $default,){
final _that = this;
switch (_that) {
case _PaginationMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginationMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _PaginationMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'page')  int page, @JsonKey(name: 'limit')  int limit, @JsonKey(name: 'total')  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginationMetadata() when $default != null:
return $default(_that.nextCursor,_that.hasMore,_that.page,_that.limit,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'page')  int page, @JsonKey(name: 'limit')  int limit, @JsonKey(name: 'total')  int total)  $default,) {final _that = this;
switch (_that) {
case _PaginationMetadata():
return $default(_that.nextCursor,_that.hasMore,_that.page,_that.limit,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'page')  int page, @JsonKey(name: 'limit')  int limit, @JsonKey(name: 'total')  int total)?  $default,) {final _that = this;
switch (_that) {
case _PaginationMetadata() when $default != null:
return $default(_that.nextCursor,_that.hasMore,_that.page,_that.limit,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginationMetadata implements PaginationMetadata {
  const _PaginationMetadata({@JsonKey(name: 'next_cursor') this.nextCursor, @JsonKey(name: 'has_more') required this.hasMore, @JsonKey(name: 'page') required this.page, @JsonKey(name: 'limit') required this.limit, @JsonKey(name: 'total') required this.total});
  factory _PaginationMetadata.fromJson(Map<String, dynamic> json) => _$PaginationMetadataFromJson(json);

@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'has_more') final  bool hasMore;
@override@JsonKey(name: 'page') final  int page;
@override@JsonKey(name: 'limit') final  int limit;
@override@JsonKey(name: 'total') final  int total;

/// Create a copy of PaginationMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginationMetadataCopyWith<_PaginationMetadata> get copyWith => __$PaginationMetadataCopyWithImpl<_PaginationMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginationMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginationMetadata&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nextCursor,hasMore,page,limit,total);

@override
String toString() {
  return 'PaginationMetadata(nextCursor: $nextCursor, hasMore: $hasMore, page: $page, limit: $limit, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PaginationMetadataCopyWith<$Res> implements $PaginationMetadataCopyWith<$Res> {
  factory _$PaginationMetadataCopyWith(_PaginationMetadata value, $Res Function(_PaginationMetadata) _then) = __$PaginationMetadataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'has_more') bool hasMore,@JsonKey(name: 'page') int page,@JsonKey(name: 'limit') int limit,@JsonKey(name: 'total') int total
});




}
/// @nodoc
class __$PaginationMetadataCopyWithImpl<$Res>
    implements _$PaginationMetadataCopyWith<$Res> {
  __$PaginationMetadataCopyWithImpl(this._self, this._then);

  final _PaginationMetadata _self;
  final $Res Function(_PaginationMetadata) _then;

/// Create a copy of PaginationMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nextCursor = freezed,Object? hasMore = null,Object? page = null,Object? limit = null,Object? total = null,}) {
  return _then(_PaginationMetadata(
nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
