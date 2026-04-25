// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_api_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserResponse {

 String get id; String get email;@JsonKey(name: 'display_name') String get displayName;@JsonKey(defaultValue: '🐻') String? get avatar;@JsonKey(name: 'role_id', defaultValue: '') String get roleId;@JsonKey(defaultValue: 'member') String get role;@JsonKey(defaultValue: []) List<String> get permissions;@JsonKey(name: 'is_verified', defaultValue: false) bool get isVerified;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of UserResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserResponseCopyWith<UserResponse> get copyWith => _$UserResponseCopyWithImpl<UserResponse>(this as UserResponse, _$identity);

  /// Serializes this UserResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,avatar,roleId,role,const DeepCollectionEquality().hash(permissions),isVerified,createdAt,updatedAt);

@override
String toString() {
  return 'UserResponse(id: $id, email: $email, displayName: $displayName, avatar: $avatar, roleId: $roleId, role: $role, permissions: $permissions, isVerified: $isVerified, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserResponseCopyWith<$Res>  {
  factory $UserResponseCopyWith(UserResponse value, $Res Function(UserResponse) _then) = _$UserResponseCopyWithImpl;
@useResult
$Res call({
 String id, String email,@JsonKey(name: 'display_name') String displayName,@JsonKey(defaultValue: '🐻') String? avatar,@JsonKey(name: 'role_id', defaultValue: '') String roleId,@JsonKey(defaultValue: 'member') String role,@JsonKey(defaultValue: []) List<String> permissions,@JsonKey(name: 'is_verified', defaultValue: false) bool isVerified,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$UserResponseCopyWithImpl<$Res>
    implements $UserResponseCopyWith<$Res> {
  _$UserResponseCopyWithImpl(this._self, this._then);

  final UserResponse _self;
  final $Res Function(UserResponse) _then;

/// Create a copy of UserResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? avatar = freezed,Object? roleId = null,Object? role = null,Object? permissions = null,Object? isVerified = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserResponse].
extension UserResponsePatterns on UserResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserResponse value)  $default,){
final _that = this;
switch (_that) {
case _UserResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UserResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email, @JsonKey(name: 'display_name')  String displayName, @JsonKey(defaultValue: '🐻')  String? avatar, @JsonKey(name: 'role_id', defaultValue: '')  String roleId, @JsonKey(defaultValue: 'member')  String role, @JsonKey(defaultValue: [])  List<String> permissions, @JsonKey(name: 'is_verified', defaultValue: false)  bool isVerified, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserResponse() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.avatar,_that.roleId,_that.role,_that.permissions,_that.isVerified,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email, @JsonKey(name: 'display_name')  String displayName, @JsonKey(defaultValue: '🐻')  String? avatar, @JsonKey(name: 'role_id', defaultValue: '')  String roleId, @JsonKey(defaultValue: 'member')  String role, @JsonKey(defaultValue: [])  List<String> permissions, @JsonKey(name: 'is_verified', defaultValue: false)  bool isVerified, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserResponse():
return $default(_that.id,_that.email,_that.displayName,_that.avatar,_that.roleId,_that.role,_that.permissions,_that.isVerified,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email, @JsonKey(name: 'display_name')  String displayName, @JsonKey(defaultValue: '🐻')  String? avatar, @JsonKey(name: 'role_id', defaultValue: '')  String roleId, @JsonKey(defaultValue: 'member')  String role, @JsonKey(defaultValue: [])  List<String> permissions, @JsonKey(name: 'is_verified', defaultValue: false)  bool isVerified, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserResponse() when $default != null:
return $default(_that.id,_that.email,_that.displayName,_that.avatar,_that.roleId,_that.role,_that.permissions,_that.isVerified,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserResponse implements UserResponse {
  const _UserResponse({required this.id, required this.email, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(defaultValue: '🐻') this.avatar, @JsonKey(name: 'role_id', defaultValue: '') required this.roleId, @JsonKey(defaultValue: 'member') required this.role, @JsonKey(defaultValue: []) required final  List<String> permissions, @JsonKey(name: 'is_verified', defaultValue: false) required this.isVerified, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _permissions = permissions;
  factory _UserResponse.fromJson(Map<String, dynamic> json) => _$UserResponseFromJson(json);

@override final  String id;
@override final  String email;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(defaultValue: '🐻') final  String? avatar;
@override@JsonKey(name: 'role_id', defaultValue: '') final  String roleId;
@override@JsonKey(defaultValue: 'member') final  String role;
 final  List<String> _permissions;
@override@JsonKey(defaultValue: []) List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

@override@JsonKey(name: 'is_verified', defaultValue: false) final  bool isVerified;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of UserResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserResponseCopyWith<_UserResponse> get copyWith => __$UserResponseCopyWithImpl<_UserResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,displayName,avatar,roleId,role,const DeepCollectionEquality().hash(_permissions),isVerified,createdAt,updatedAt);

@override
String toString() {
  return 'UserResponse(id: $id, email: $email, displayName: $displayName, avatar: $avatar, roleId: $roleId, role: $role, permissions: $permissions, isVerified: $isVerified, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserResponseCopyWith<$Res> implements $UserResponseCopyWith<$Res> {
  factory _$UserResponseCopyWith(_UserResponse value, $Res Function(_UserResponse) _then) = __$UserResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String email,@JsonKey(name: 'display_name') String displayName,@JsonKey(defaultValue: '🐻') String? avatar,@JsonKey(name: 'role_id', defaultValue: '') String roleId,@JsonKey(defaultValue: 'member') String role,@JsonKey(defaultValue: []) List<String> permissions,@JsonKey(name: 'is_verified', defaultValue: false) bool isVerified,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$UserResponseCopyWithImpl<$Res>
    implements _$UserResponseCopyWith<$Res> {
  __$UserResponseCopyWithImpl(this._self, this._then);

  final _UserResponse _self;
  final $Res Function(_UserResponse) _then;

/// Create a copy of UserResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? displayName = null,Object? avatar = freezed,Object? roleId = null,Object? role = null,Object? permissions = null,Object? isVerified = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_UserResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$UserUpdateRequest {

@JsonKey(name: 'display_name') String? get displayName; String? get avatar;
/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserUpdateRequestCopyWith<UserUpdateRequest> get copyWith => _$UserUpdateRequestCopyWithImpl<UserUpdateRequest>(this as UserUpdateRequest, _$identity);

  /// Serializes this UserUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserUpdateRequest&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,avatar);

@override
String toString() {
  return 'UserUpdateRequest(displayName: $displayName, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $UserUpdateRequestCopyWith<$Res>  {
  factory $UserUpdateRequestCopyWith(UserUpdateRequest value, $Res Function(UserUpdateRequest) _then) = _$UserUpdateRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'display_name') String? displayName, String? avatar
});




}
/// @nodoc
class _$UserUpdateRequestCopyWithImpl<$Res>
    implements $UserUpdateRequestCopyWith<$Res> {
  _$UserUpdateRequestCopyWithImpl(this._self, this._then);

  final UserUpdateRequest _self;
  final $Res Function(UserUpdateRequest) _then;

/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = freezed,Object? avatar = freezed,}) {
  return _then(_self.copyWith(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserUpdateRequest].
extension UserUpdateRequestPatterns on UserUpdateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserUpdateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserUpdateRequest value)  $default,){
final _that = this;
switch (_that) {
case _UserUpdateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserUpdateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UserUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'display_name')  String? displayName,  String? avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserUpdateRequest() when $default != null:
return $default(_that.displayName,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'display_name')  String? displayName,  String? avatar)  $default,) {final _that = this;
switch (_that) {
case _UserUpdateRequest():
return $default(_that.displayName,_that.avatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'display_name')  String? displayName,  String? avatar)?  $default,) {final _that = this;
switch (_that) {
case _UserUpdateRequest() when $default != null:
return $default(_that.displayName,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserUpdateRequest implements UserUpdateRequest {
  const _UserUpdateRequest({@JsonKey(name: 'display_name') this.displayName, this.avatar});
  factory _UserUpdateRequest.fromJson(Map<String, dynamic> json) => _$UserUpdateRequestFromJson(json);

@override@JsonKey(name: 'display_name') final  String? displayName;
@override final  String? avatar;

/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserUpdateRequestCopyWith<_UserUpdateRequest> get copyWith => __$UserUpdateRequestCopyWithImpl<_UserUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserUpdateRequest&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,avatar);

@override
String toString() {
  return 'UserUpdateRequest(displayName: $displayName, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$UserUpdateRequestCopyWith<$Res> implements $UserUpdateRequestCopyWith<$Res> {
  factory _$UserUpdateRequestCopyWith(_UserUpdateRequest value, $Res Function(_UserUpdateRequest) _then) = __$UserUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'display_name') String? displayName, String? avatar
});




}
/// @nodoc
class __$UserUpdateRequestCopyWithImpl<$Res>
    implements _$UserUpdateRequestCopyWith<$Res> {
  __$UserUpdateRequestCopyWithImpl(this._self, this._then);

  final _UserUpdateRequest _self;
  final $Res Function(_UserUpdateRequest) _then;

/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = freezed,Object? avatar = freezed,}) {
  return _then(_UserUpdateRequest(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
