import 'dart:convert';

import 'interfaces/i_token_validator.dart';

/// JWT Token Validator Implementation
/// Decodes and validates JWT tokens on the client side.
/// Note: Signature verification is done server-side.
class JwtTokenValidator implements ITokenValidator {
  @override
  TokenValidationResult validate(String token) {
    final payload = decode(token);

    if (payload == null) {
      return TokenValidationResult.invalid('MALFORMED');
    }

    if (payload.isExpired) {
      return TokenValidationResult.expired(payload);
    }

    return TokenValidationResult.valid(payload);
  }

  @override
  TokenPayload? decode(String token) {
    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode payload (middle part)
      final payloadB64 = parts[1];
      // Add padding if necessary
      final normalized = base64Url.normalize(payloadB64);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;

      // Extract required fields
      final userId = payloadMap['uid'] as String?;
      final iat = payloadMap['iat'];
      final exp = payloadMap['exp'];
      final tokenType = payloadMap['type'] as String? ?? 'access';

      if (userId == null || iat == null || exp == null) {
        return null;
      }

      // Parse timestamps (could be int seconds or milliseconds)
      final issuedAt = _parseTimestamp(iat);
      final expiresAt = _parseTimestamp(exp);

      if (issuedAt == null || expiresAt == null) {
        return null;
      }

      // Extract additional claims
      final claims = Map<String, dynamic>.from(payloadMap)
        ..remove('uid')
        ..remove('iat')
        ..remove('exp')
        ..remove('type');

      return TokenPayload(
        userId: userId,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        tokenType: tokenType,
        claims: claims.isEmpty ? null : claims,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  bool isExpiringSoon(String token, {Duration threshold = const Duration(minutes: 5)}) {
    final payload = decode(token);
    if (payload == null) return true; // Treat malformed as expiring

    return payload.remainingTime <= threshold;
  }

  @override
  bool isExpired(String token) {
    final payload = decode(token);
    if (payload == null) return true; // Treat malformed as expired

    return payload.isExpired;
  }

  /// Parse timestamp from various formats
  DateTime? _parseTimestamp(dynamic value) {
    if (value is int) {
      // Check if milliseconds or seconds
      if (value > 1000000000000) {
        // Likely milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        // Likely seconds
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
