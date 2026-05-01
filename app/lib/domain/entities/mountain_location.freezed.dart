// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mountain_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MountainLocation {

 String get id; String get name; int get altitude; MountainRegion get region; String get introduction; String get features; List<String> get trailheads; String get mapRef; String get jurisdiction; bool get isBeginnerFriendly; List<String> get photoUrls; String get cwaPid; String get windyParams; MountainCategory get category; List<MountainLink> get links;
/// Create a copy of MountainLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MountainLocationCopyWith<MountainLocation> get copyWith => _$MountainLocationCopyWithImpl<MountainLocation>(this as MountainLocation, _$identity);

  /// Serializes this MountainLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MountainLocation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.region, region) || other.region == region)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.features, features) || other.features == features)&&const DeepCollectionEquality().equals(other.trailheads, trailheads)&&(identical(other.mapRef, mapRef) || other.mapRef == mapRef)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.isBeginnerFriendly, isBeginnerFriendly) || other.isBeginnerFriendly == isBeginnerFriendly)&&const DeepCollectionEquality().equals(other.photoUrls, photoUrls)&&(identical(other.cwaPid, cwaPid) || other.cwaPid == cwaPid)&&(identical(other.windyParams, windyParams) || other.windyParams == windyParams)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.links, links));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,altitude,region,introduction,features,const DeepCollectionEquality().hash(trailheads),mapRef,jurisdiction,isBeginnerFriendly,const DeepCollectionEquality().hash(photoUrls),cwaPid,windyParams,category,const DeepCollectionEquality().hash(links));

@override
String toString() {
  return 'MountainLocation(id: $id, name: $name, altitude: $altitude, region: $region, introduction: $introduction, features: $features, trailheads: $trailheads, mapRef: $mapRef, jurisdiction: $jurisdiction, isBeginnerFriendly: $isBeginnerFriendly, photoUrls: $photoUrls, cwaPid: $cwaPid, windyParams: $windyParams, category: $category, links: $links)';
}


}

/// @nodoc
abstract mixin class $MountainLocationCopyWith<$Res>  {
  factory $MountainLocationCopyWith(MountainLocation value, $Res Function(MountainLocation) _then) = _$MountainLocationCopyWithImpl;
@useResult
$Res call({
 String id, String name, int altitude, MountainRegion region, String introduction, String features, List<String> trailheads, String mapRef, String jurisdiction, bool isBeginnerFriendly, List<String> photoUrls, String cwaPid, String windyParams, MountainCategory category, List<MountainLink> links
});




}
/// @nodoc
class _$MountainLocationCopyWithImpl<$Res>
    implements $MountainLocationCopyWith<$Res> {
  _$MountainLocationCopyWithImpl(this._self, this._then);

  final MountainLocation _self;
  final $Res Function(MountainLocation) _then;

/// Create a copy of MountainLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? altitude = null,Object? region = null,Object? introduction = null,Object? features = null,Object? trailheads = null,Object? mapRef = null,Object? jurisdiction = null,Object? isBeginnerFriendly = null,Object? photoUrls = null,Object? cwaPid = null,Object? windyParams = null,Object? category = null,Object? links = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as MountainRegion,introduction: null == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as String,trailheads: null == trailheads ? _self.trailheads : trailheads // ignore: cast_nullable_to_non_nullable
as List<String>,mapRef: null == mapRef ? _self.mapRef : mapRef // ignore: cast_nullable_to_non_nullable
as String,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as String,isBeginnerFriendly: null == isBeginnerFriendly ? _self.isBeginnerFriendly : isBeginnerFriendly // ignore: cast_nullable_to_non_nullable
as bool,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,cwaPid: null == cwaPid ? _self.cwaPid : cwaPid // ignore: cast_nullable_to_non_nullable
as String,windyParams: null == windyParams ? _self.windyParams : windyParams // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MountainCategory,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<MountainLink>,
  ));
}

}


/// Adds pattern-matching-related methods to [MountainLocation].
extension MountainLocationPatterns on MountainLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MountainLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MountainLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MountainLocation value)  $default,){
final _that = this;
switch (_that) {
case _MountainLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MountainLocation value)?  $default,){
final _that = this;
switch (_that) {
case _MountainLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int altitude,  MountainRegion region,  String introduction,  String features,  List<String> trailheads,  String mapRef,  String jurisdiction,  bool isBeginnerFriendly,  List<String> photoUrls,  String cwaPid,  String windyParams,  MountainCategory category,  List<MountainLink> links)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MountainLocation() when $default != null:
return $default(_that.id,_that.name,_that.altitude,_that.region,_that.introduction,_that.features,_that.trailheads,_that.mapRef,_that.jurisdiction,_that.isBeginnerFriendly,_that.photoUrls,_that.cwaPid,_that.windyParams,_that.category,_that.links);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int altitude,  MountainRegion region,  String introduction,  String features,  List<String> trailheads,  String mapRef,  String jurisdiction,  bool isBeginnerFriendly,  List<String> photoUrls,  String cwaPid,  String windyParams,  MountainCategory category,  List<MountainLink> links)  $default,) {final _that = this;
switch (_that) {
case _MountainLocation():
return $default(_that.id,_that.name,_that.altitude,_that.region,_that.introduction,_that.features,_that.trailheads,_that.mapRef,_that.jurisdiction,_that.isBeginnerFriendly,_that.photoUrls,_that.cwaPid,_that.windyParams,_that.category,_that.links);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int altitude,  MountainRegion region,  String introduction,  String features,  List<String> trailheads,  String mapRef,  String jurisdiction,  bool isBeginnerFriendly,  List<String> photoUrls,  String cwaPid,  String windyParams,  MountainCategory category,  List<MountainLink> links)?  $default,) {final _that = this;
switch (_that) {
case _MountainLocation() when $default != null:
return $default(_that.id,_that.name,_that.altitude,_that.region,_that.introduction,_that.features,_that.trailheads,_that.mapRef,_that.jurisdiction,_that.isBeginnerFriendly,_that.photoUrls,_that.cwaPid,_that.windyParams,_that.category,_that.links);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MountainLocation extends MountainLocation {
  const _MountainLocation({required this.id, required this.name, required this.altitude, required this.region, required this.introduction, required this.features, required final  List<String> trailheads, required this.mapRef, required this.jurisdiction, this.isBeginnerFriendly = false, final  List<String> photoUrls = const [], required this.cwaPid, required this.windyParams, required this.category, final  List<MountainLink> links = const []}): _trailheads = trailheads,_photoUrls = photoUrls,_links = links,super._();
  factory _MountainLocation.fromJson(Map<String, dynamic> json) => _$MountainLocationFromJson(json);

@override final  String id;
@override final  String name;
@override final  int altitude;
@override final  MountainRegion region;
@override final  String introduction;
@override final  String features;
 final  List<String> _trailheads;
@override List<String> get trailheads {
  if (_trailheads is EqualUnmodifiableListView) return _trailheads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trailheads);
}

@override final  String mapRef;
@override final  String jurisdiction;
@override@JsonKey() final  bool isBeginnerFriendly;
 final  List<String> _photoUrls;
@override@JsonKey() List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

@override final  String cwaPid;
@override final  String windyParams;
@override final  MountainCategory category;
 final  List<MountainLink> _links;
@override@JsonKey() List<MountainLink> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}


/// Create a copy of MountainLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MountainLocationCopyWith<_MountainLocation> get copyWith => __$MountainLocationCopyWithImpl<_MountainLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MountainLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MountainLocation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.region, region) || other.region == region)&&(identical(other.introduction, introduction) || other.introduction == introduction)&&(identical(other.features, features) || other.features == features)&&const DeepCollectionEquality().equals(other._trailheads, _trailheads)&&(identical(other.mapRef, mapRef) || other.mapRef == mapRef)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.isBeginnerFriendly, isBeginnerFriendly) || other.isBeginnerFriendly == isBeginnerFriendly)&&const DeepCollectionEquality().equals(other._photoUrls, _photoUrls)&&(identical(other.cwaPid, cwaPid) || other.cwaPid == cwaPid)&&(identical(other.windyParams, windyParams) || other.windyParams == windyParams)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._links, _links));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,altitude,region,introduction,features,const DeepCollectionEquality().hash(_trailheads),mapRef,jurisdiction,isBeginnerFriendly,const DeepCollectionEquality().hash(_photoUrls),cwaPid,windyParams,category,const DeepCollectionEquality().hash(_links));

@override
String toString() {
  return 'MountainLocation(id: $id, name: $name, altitude: $altitude, region: $region, introduction: $introduction, features: $features, trailheads: $trailheads, mapRef: $mapRef, jurisdiction: $jurisdiction, isBeginnerFriendly: $isBeginnerFriendly, photoUrls: $photoUrls, cwaPid: $cwaPid, windyParams: $windyParams, category: $category, links: $links)';
}


}

/// @nodoc
abstract mixin class _$MountainLocationCopyWith<$Res> implements $MountainLocationCopyWith<$Res> {
  factory _$MountainLocationCopyWith(_MountainLocation value, $Res Function(_MountainLocation) _then) = __$MountainLocationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int altitude, MountainRegion region, String introduction, String features, List<String> trailheads, String mapRef, String jurisdiction, bool isBeginnerFriendly, List<String> photoUrls, String cwaPid, String windyParams, MountainCategory category, List<MountainLink> links
});




}
/// @nodoc
class __$MountainLocationCopyWithImpl<$Res>
    implements _$MountainLocationCopyWith<$Res> {
  __$MountainLocationCopyWithImpl(this._self, this._then);

  final _MountainLocation _self;
  final $Res Function(_MountainLocation) _then;

/// Create a copy of MountainLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? altitude = null,Object? region = null,Object? introduction = null,Object? features = null,Object? trailheads = null,Object? mapRef = null,Object? jurisdiction = null,Object? isBeginnerFriendly = null,Object? photoUrls = null,Object? cwaPid = null,Object? windyParams = null,Object? category = null,Object? links = null,}) {
  return _then(_MountainLocation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as int,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as MountainRegion,introduction: null == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as String,trailheads: null == trailheads ? _self._trailheads : trailheads // ignore: cast_nullable_to_non_nullable
as List<String>,mapRef: null == mapRef ? _self.mapRef : mapRef // ignore: cast_nullable_to_non_nullable
as String,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as String,isBeginnerFriendly: null == isBeginnerFriendly ? _self.isBeginnerFriendly : isBeginnerFriendly // ignore: cast_nullable_to_non_nullable
as bool,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,cwaPid: null == cwaPid ? _self.cwaPid : cwaPid // ignore: cast_nullable_to_non_nullable
as String,windyParams: null == windyParams ? _self.windyParams : windyParams // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MountainCategory,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<MountainLink>,
  ));
}


}


/// @nodoc
mixin _$MountainLink {

 LinkType get type; String get title; String get url;
/// Create a copy of MountainLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MountainLinkCopyWith<MountainLink> get copyWith => _$MountainLinkCopyWithImpl<MountainLink>(this as MountainLink, _$identity);

  /// Serializes this MountainLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MountainLink&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,title,url);

@override
String toString() {
  return 'MountainLink(type: $type, title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class $MountainLinkCopyWith<$Res>  {
  factory $MountainLinkCopyWith(MountainLink value, $Res Function(MountainLink) _then) = _$MountainLinkCopyWithImpl;
@useResult
$Res call({
 LinkType type, String title, String url
});




}
/// @nodoc
class _$MountainLinkCopyWithImpl<$Res>
    implements $MountainLinkCopyWith<$Res> {
  _$MountainLinkCopyWithImpl(this._self, this._then);

  final MountainLink _self;
  final $Res Function(MountainLink) _then;

/// Create a copy of MountainLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? url = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LinkType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MountainLink].
extension MountainLinkPatterns on MountainLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MountainLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MountainLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MountainLink value)  $default,){
final _that = this;
switch (_that) {
case _MountainLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MountainLink value)?  $default,){
final _that = this;
switch (_that) {
case _MountainLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LinkType type,  String title,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MountainLink() when $default != null:
return $default(_that.type,_that.title,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LinkType type,  String title,  String url)  $default,) {final _that = this;
switch (_that) {
case _MountainLink():
return $default(_that.type,_that.title,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LinkType type,  String title,  String url)?  $default,) {final _that = this;
switch (_that) {
case _MountainLink() when $default != null:
return $default(_that.type,_that.title,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MountainLink implements MountainLink {
  const _MountainLink({required this.type, required this.title, required this.url});
  factory _MountainLink.fromJson(Map<String, dynamic> json) => _$MountainLinkFromJson(json);

@override final  LinkType type;
@override final  String title;
@override final  String url;

/// Create a copy of MountainLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MountainLinkCopyWith<_MountainLink> get copyWith => __$MountainLinkCopyWithImpl<_MountainLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MountainLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MountainLink&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,title,url);

@override
String toString() {
  return 'MountainLink(type: $type, title: $title, url: $url)';
}


}

/// @nodoc
abstract mixin class _$MountainLinkCopyWith<$Res> implements $MountainLinkCopyWith<$Res> {
  factory _$MountainLinkCopyWith(_MountainLink value, $Res Function(_MountainLink) _then) = __$MountainLinkCopyWithImpl;
@override @useResult
$Res call({
 LinkType type, String title, String url
});




}
/// @nodoc
class __$MountainLinkCopyWithImpl<$Res>
    implements _$MountainLinkCopyWith<$Res> {
  __$MountainLinkCopyWithImpl(this._self, this._then);

  final _MountainLink _self;
  final $Res Function(_MountainLink) _then;

/// Create a copy of MountainLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? url = null,}) {
  return _then(_MountainLink(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LinkType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
