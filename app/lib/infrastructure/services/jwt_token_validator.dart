import 'dart:convert';

import '../../domain/interfaces/i_token_validator.dart';

/// JWT Token 驗證器實作
/// 在用戶端解碼並驗證 JWT Token。
/// 注意：簽章驗證由伺服器端進行。
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
      // JWT 格式: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // 解碼 Payload (中間部分)
      final payloadB64 = parts[1];
      // 若需要則補齊 Padding
      final normalized = base64Url.normalize(payloadB64);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;

      // 提取必要欄位
      final userId = payloadMap['uid'] as String?;
      final iat = payloadMap['iat'];
      final exp = payloadMap['exp'];
      final tokenType = payloadMap['type'] as String? ?? 'access';

      if (userId == null || iat == null || exp == null) {
        return null;
      }

      // 解析時間戳 (可能為秒或毫秒)
      final issuedAt = _parseTimestamp(iat);
      final expiresAt = _parseTimestamp(exp);

      if (issuedAt == null || expiresAt == null) {
        return null;
      }

      // 提取額外 Claims
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
    if (payload == null) return true; // 視格式錯誤為即將過期

    return payload.remainingTime <= threshold;
  }

  @override
  bool isExpired(String token) {
    final payload = decode(token);
    if (payload == null) return true; // 視格式錯誤為已過期

    return payload.isExpired;
  }

  /// 解析多種格式的時間戳
  DateTime? _parseTimestamp(dynamic value) {
    if (value is int) {
      // 檢查是毫秒還是秒
      if (value > 1000000000000) {
        // 應為毫秒
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        // 應為秒
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
