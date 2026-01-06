/// Interface for providing authentication tokens
/// Used for dependency injection in HTTP clients.
abstract class IAuthTokenProvider {
  /// Get the current authentication token
  /// Returns null if user is not authenticated.
  Future<String?> getAuthToken();
}
