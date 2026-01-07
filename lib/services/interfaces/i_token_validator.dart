/// Token Payload - Decoded JWT content
class TokenPayload {
  /// User ID from the token
  final String userId;

  /// Token issued at timestamp
  final DateTime issuedAt;

  /// Token expiration timestamp
  final DateTime expiresAt;

  /// Token type: 'access' or 'refresh'
  final String tokenType;

  /// Additional claims (optional)
  final Map<String, dynamic>? claims;

  const TokenPayload({
    required this.userId,
    required this.issuedAt,
    required this.expiresAt,
    required this.tokenType,
    this.claims,
  });

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining time until expiration
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Check if token is access token
  bool get isAccessToken => tokenType == 'access';

  /// Check if token is refresh token
  bool get isRefreshToken => tokenType == 'refresh';
}

/// Token Validation Result
class TokenValidationResult {
  /// Whether the token is valid
  final bool isValid;

  /// Error code if validation failed
  /// Possible values: 'EXPIRED', 'INVALID_SIGNATURE', 'MALFORMED', 'MISSING'
  final String? errorCode;

  /// Decoded token payload (only present if valid or expired but decodable)
  final TokenPayload? payload;

  const TokenValidationResult({
    required this.isValid,
    this.errorCode,
    this.payload,
  });

  factory TokenValidationResult.valid(TokenPayload payload) {
    return TokenValidationResult(
      isValid: true,
      payload: payload,
    );
  }

  factory TokenValidationResult.expired(TokenPayload payload) {
    return TokenValidationResult(
      isValid: false,
      errorCode: 'EXPIRED',
      payload: payload,
    );
  }

  factory TokenValidationResult.invalid(String errorCode) {
    return TokenValidationResult(
      isValid: false,
      errorCode: errorCode,
    );
  }

  factory TokenValidationResult.missing() {
    return const TokenValidationResult(
      isValid: false,
      errorCode: 'MISSING',
    );
  }
}

/// Token Validator Interface
/// Provides JWT token validation and decoding functionality.
/// This abstraction allows different implementations:
/// - JwtTokenValidator (current, for GAS JWT)
/// - FirebaseTokenValidator (future)
abstract class ITokenValidator {
  /// Validate token and return result
  /// Note: Signature verification should be done server-side.
  /// Client-side validation focuses on expiration and format.
  TokenValidationResult validate(String token);

  /// Decode token payload without validation
  /// Returns null if token is malformed
  TokenPayload? decode(String token);

  /// Check if token is expiring soon
  /// [threshold] - Time before expiration to consider "expiring soon"
  bool isExpiringSoon(
    String token, {
    Duration threshold = const Duration(minutes: 5),
  });

  /// Check if token is expired
  bool isExpired(String token);
}
