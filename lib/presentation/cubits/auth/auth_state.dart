import 'package:equatable/equatable.dart';
import '../../../data/models/user_profile.dart';
import '../../../core/constants/role_constants.dart';

/// 認證狀態基類
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 認證初始狀態
final class AuthInitial extends AuthState {}

/// 認證載入中
final class AuthLoading extends AuthState {}

/// 已認證 (登入成功)
final class AuthAuthenticated extends AuthState {
  /// 使用者 ID
  final String userId;

  /// 使用者名稱
  final String? userName;

  /// Email
  final String? email;

  /// 頭像 URL
  final String? avatar;

  /// 角色代碼
  final String? roleCode;

  /// 權限列表
  final List<String> permissions;

  /// 是否為訪客
  final bool isGuest;

  /// 是否為離線模式
  final bool isOffline;

  /// 建構子
  ///
  /// [userId] 使用者 ID
  /// [userName] 使用者名稱
  /// [email] Email
  /// [avatar] 頭像 URL
  /// [roleCode] 角色代碼
  /// [permissions] 權限列表
  /// [isGuest] 是否為訪客
  /// [isOffline] 是否為離線模式
  const AuthAuthenticated({
    required this.userId,
    this.userName,
    this.email,
    this.avatar,
    this.roleCode,
    this.permissions = const [],
    this.isGuest = false,
    this.isOffline = false,
  });

  /// 重建 UserProfile 物件 (方便 UI/Service 調用)
  UserProfile get user => UserProfile(
    id: userId,
    email: email ?? '',
    displayName: userName ?? '',
    avatar: avatar ?? '🐻',
    roleCode: roleCode ?? RoleConstants.member,
    permissions: permissions,
    isVerified: true, // 假設已認證，若需準確需存更多欄位
  );

  @override
  List<Object?> get props => [userId, userName, email, avatar, roleCode, permissions, isGuest, isOffline];
}

/// 未認證 (未登入)
final class AuthUnauthenticated extends AuthState {}

/// 認證錯誤
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 操作成功 (例如: 更新資料成功，但狀態仍保持已登入)
final class AuthOperationSuccess extends AuthState {
  final String message;
  const AuthOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// 需要驗證 Email
final class AuthRequiresVerification extends AuthState {
  final String email;
  const AuthRequiresVerification(this.email);

  @override
  List<Object?> get props => [email];
}
