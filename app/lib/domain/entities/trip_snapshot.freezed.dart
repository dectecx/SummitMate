// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripSnapshot {

 String get name; DateTime get startDate; DateTime? get endDate; List<ItineraryItem> get itinerary;
/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripSnapshotCopyWith<TripSnapshot> get copyWith => _$TripSnapshotCopyWithImpl<TripSnapshot>(this as TripSnapshot, _$identity);

  /// Serializes this TripSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripSnapshot&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.itinerary, itinerary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,endDate,const DeepCollectionEquality().hash(itinerary));

@override
String toString() {
  return 'TripSnapshot(name: $name, startDate: $startDate, endDate: $endDate, itinerary: $itinerary)';
}


}

/// @nodoc
abstract mixin class $TripSnapshotCopyWith<$Res>  {
  factory $TripSnapshotCopyWith(TripSnapshot value, $Res Function(TripSnapshot) _then) = _$TripSnapshotCopyWithImpl;
@useResult
$Res call({
 String name, DateTime startDate, DateTime? endDate, List<ItineraryItem> itinerary
});




}
/// @nodoc
class _$TripSnapshotCopyWithImpl<$Res>
    implements $TripSnapshotCopyWith<$Res> {
  _$TripSnapshotCopyWithImpl(this._self, this._then);

  final TripSnapshot _self;
  final $Res Function(TripSnapshot) _then;

/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? startDate = null,Object? endDate = freezed,Object? itinerary = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,itinerary: null == itinerary ? _self.itinerary : itinerary // ignore: cast_nullable_to_non_nullable
as List<ItineraryItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripSnapshot].
extension TripSnapshotPatterns on TripSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TripSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  DateTime startDate,  DateTime? endDate,  List<ItineraryItem> itinerary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
return $default(_that.name,_that.startDate,_that.endDate,_that.itinerary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  DateTime startDate,  DateTime? endDate,  List<ItineraryItem> itinerary)  $default,) {final _that = this;
switch (_that) {
case _TripSnapshot():
return $default(_that.name,_that.startDate,_that.endDate,_that.itinerary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  DateTime startDate,  DateTime? endDate,  List<ItineraryItem> itinerary)?  $default,) {final _that = this;
switch (_that) {
case _TripSnapshot() when $default != null:
return $default(_that.name,_that.startDate,_that.endDate,_that.itinerary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripSnapshot implements TripSnapshot {
  const _TripSnapshot({required this.name, required this.startDate, this.endDate, final  List<ItineraryItem> itinerary = const []}): _itinerary = itinerary;
  factory _TripSnapshot.fromJson(Map<String, dynamic> json) => _$TripSnapshotFromJson(json);

@override final  String name;
@override final  DateTime startDate;
@override final  DateTime? endDate;
 final  List<ItineraryItem> _itinerary;
@override@JsonKey() List<ItineraryItem> get itinerary {
  if (_itinerary is EqualUnmodifiableListView) return _itinerary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itinerary);
}


/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripSnapshotCopyWith<_TripSnapshot> get copyWith => __$TripSnapshotCopyWithImpl<_TripSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripSnapshot&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other._itinerary, _itinerary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,startDate,endDate,const DeepCollectionEquality().hash(_itinerary));

@override
String toString() {
  return 'TripSnapshot(name: $name, startDate: $startDate, endDate: $endDate, itinerary: $itinerary)';
}


}

/// @nodoc
abstract mixin class _$TripSnapshotCopyWith<$Res> implements $TripSnapshotCopyWith<$Res> {
  factory _$TripSnapshotCopyWith(_TripSnapshot value, $Res Function(_TripSnapshot) _then) = __$TripSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String name, DateTime startDate, DateTime? endDate, List<ItineraryItem> itinerary
});




}
/// @nodoc
class __$TripSnapshotCopyWithImpl<$Res>
    implements _$TripSnapshotCopyWith<$Res> {
  __$TripSnapshotCopyWithImpl(this._self, this._then);

  final _TripSnapshot _self;
  final $Res Function(_TripSnapshot) _then;

/// Create a copy of TripSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? startDate = null,Object? endDate = freezed,Object? itinerary = null,}) {
  return _then(_TripSnapshot(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,itinerary: null == itinerary ? _self._itinerary : itinerary // ignore: cast_nullable_to_non_nullable
as List<ItineraryItem>,
  ));
}


}

// dart format on
