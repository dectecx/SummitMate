/// A signed-in person's basic profile (mirrors the server's User).
class AuthUser {
  const AuthUser({required this.id, required this.email, required this.displayName, required this.avatar});
  final String id;
  final String email;
  final String displayName;
  final String avatar;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email && other.displayName == displayName && other.avatar == avatar;
  @override
  int get hashCode => Object.hash(id, email, displayName, avatar);
}

/// Who is using the app. Guests are first-class: everything works locally and syncs after sign-in.
sealed class AuthState {
  const AuthState();
}

/// No account. Data stays on the device until the person signs in.
class Guest extends AuthState {
  const Guest();
}

class SignedIn extends AuthState {
  const SignedIn(this.user);
  final AuthUser user;
}

/// The session was revoked or expired. The app keeps working; only syncing is paused.
class NeedsReauth extends AuthState {
  const NeedsReauth(this.user);
  final AuthUser user;
}
