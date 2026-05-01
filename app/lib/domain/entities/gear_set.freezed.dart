// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gear_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GearSet {

 String get id; String get title; String get author; double get totalWeight; int get itemCount; GearSetVisibility get visibility; DateTime get uploadedAt; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; List<GearItem>? get items; List<DailyMealPlan>? get meals;
/// Create a copy of GearSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GearSetCopyWith<GearSet> get copyWith => _$GearSetCopyWithImpl<GearSet>(this as GearSet, _$identity);

  /// Serializes this GearSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GearSet&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalWeight, totalWeight) || other.totalWeight == totalWeight)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.meals, meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalWeight,itemCount,visibility,uploadedAt,createdAt,createdBy,updatedAt,updatedBy,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(meals));

@override
String toString() {
  return 'GearSet(id: $id, title: $title, author: $author, totalWeight: $totalWeight, itemCount: $itemCount, visibility: $visibility, uploadedAt: $uploadedAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, items: $items, meals: $meals)';
}


}

/// @nodoc
abstract mixin class $GearSetCopyWith<$Res>  {
  factory $GearSetCopyWith(GearSet value, $Res Function(GearSet) _then) = _$GearSetCopyWithImpl;
@useResult
$Res call({
 String id, String title, String author, double totalWeight, int itemCount, GearSetVisibility visibility, DateTime uploadedAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, List<GearItem>? items, List<DailyMealPlan>? meals
});




}
/// @nodoc
class _$GearSetCopyWithImpl<$Res>
    implements $GearSetCopyWith<$Res> {
  _$GearSetCopyWithImpl(this._self, this._then);

  final GearSet _self;
  final $Res Function(GearSet) _then;

/// Create a copy of GearSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalWeight = null,Object? itemCount = null,Object? visibility = null,Object? uploadedAt = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? items = freezed,Object? meals = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalWeight: null == totalWeight ? _self.totalWeight : totalWeight // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as GearSetVisibility,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,items: freezed == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GearItem>?,meals: freezed == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as List<DailyMealPlan>?,
  ));
}

}


/// Adds pattern-matching-related methods to [GearSet].
extension GearSetPatterns on GearSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GearSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GearSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GearSet value)  $default,){
final _that = this;
switch (_that) {
case _GearSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GearSet value)?  $default,){
final _that = this;
switch (_that) {
case _GearSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String author,  double totalWeight,  int itemCount,  GearSetVisibility visibility,  DateTime uploadedAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  List<GearItem>? items,  List<DailyMealPlan>? meals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GearSet() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.totalWeight,_that.itemCount,_that.visibility,_that.uploadedAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.items,_that.meals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String author,  double totalWeight,  int itemCount,  GearSetVisibility visibility,  DateTime uploadedAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  List<GearItem>? items,  List<DailyMealPlan>? meals)  $default,) {final _that = this;
switch (_that) {
case _GearSet():
return $default(_that.id,_that.title,_that.author,_that.totalWeight,_that.itemCount,_that.visibility,_that.uploadedAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.items,_that.meals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String author,  double totalWeight,  int itemCount,  GearSetVisibility visibility,  DateTime uploadedAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  List<GearItem>? items,  List<DailyMealPlan>? meals)?  $default,) {final _that = this;
switch (_that) {
case _GearSet() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.totalWeight,_that.itemCount,_that.visibility,_that.uploadedAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.items,_that.meals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GearSet extends GearSet {
  const _GearSet({required this.id, required this.title, required this.author, this.totalWeight = 0.0, this.itemCount = 0, this.visibility = GearSetVisibility.public, required this.uploadedAt, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, final  List<GearItem>? items, final  List<DailyMealPlan>? meals}): _items = items,_meals = meals,super._();
  factory _GearSet.fromJson(Map<String, dynamic> json) => _$GearSetFromJson(json);

@override final  String id;
@override final  String title;
@override final  String author;
@override@JsonKey() final  double totalWeight;
@override@JsonKey() final  int itemCount;
@override@JsonKey() final  GearSetVisibility visibility;
@override final  DateTime uploadedAt;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
 final  List<GearItem>? _items;
@override List<GearItem>? get items {
  final value = _items;
  if (value == null) return null;
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<DailyMealPlan>? _meals;
@override List<DailyMealPlan>? get meals {
  final value = _meals;
  if (value == null) return null;
  if (_meals is EqualUnmodifiableListView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of GearSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GearSetCopyWith<_GearSet> get copyWith => __$GearSetCopyWithImpl<_GearSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GearSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GearSet&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalWeight, totalWeight) || other.totalWeight == totalWeight)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._meals, _meals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalWeight,itemCount,visibility,uploadedAt,createdAt,createdBy,updatedAt,updatedBy,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_meals));

@override
String toString() {
  return 'GearSet(id: $id, title: $title, author: $author, totalWeight: $totalWeight, itemCount: $itemCount, visibility: $visibility, uploadedAt: $uploadedAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, items: $items, meals: $meals)';
}


}

/// @nodoc
abstract mixin class _$GearSetCopyWith<$Res> implements $GearSetCopyWith<$Res> {
  factory _$GearSetCopyWith(_GearSet value, $Res Function(_GearSet) _then) = __$GearSetCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String author, double totalWeight, int itemCount, GearSetVisibility visibility, DateTime uploadedAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, List<GearItem>? items, List<DailyMealPlan>? meals
});




}
/// @nodoc
class __$GearSetCopyWithImpl<$Res>
    implements _$GearSetCopyWith<$Res> {
  __$GearSetCopyWithImpl(this._self, this._then);

  final _GearSet _self;
  final $Res Function(_GearSet) _then;

/// Create a copy of GearSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalWeight = null,Object? itemCount = null,Object? visibility = null,Object? uploadedAt = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? items = freezed,Object? meals = freezed,}) {
  return _then(_GearSet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalWeight: null == totalWeight ? _self.totalWeight : totalWeight // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as GearSetVisibility,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,items: freezed == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GearItem>?,meals: freezed == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as List<DailyMealPlan>?,
  ));
}


}

// dart format on
