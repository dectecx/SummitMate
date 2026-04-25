import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('should return error for empty email', () {
        expect(Validators.validateEmail(''), '請輸入 Email');
        expect(Validators.validateEmail(null), '請輸入 Email');
      });

      test('should return error for invalid email format', () {
        expect(Validators.validateEmail('test'), '請輸入有效的 Email 格式');
        expect(Validators.validateEmail('test@'), '請輸入有效的 Email 格式');
        expect(Validators.validateEmail('test@com'), '請輸入有效的 Email 格式');
        expect(Validators.validateEmail('@example.com'), '請輸入有效的 Email 格式');
      });

      test('should return null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), null);
        expect(Validators.validateEmail('user.name+tag@domain.org'), null);
      });
    });

    group('validatePassword', () {
      test('should return error for empty password', () {
        expect(Validators.validatePassword(''), '請輸入密碼');
        expect(Validators.validatePassword(null), '請輸入密碼');
      });

      test('should return error for short password', () {
        expect(Validators.validatePassword('1234567'), '密碼至少需要 8 個字元');
      });

      test('should return error for password without letters', () {
        expect(Validators.validatePassword('12345678'), '密碼需包含英文字母與數字');
      });

      test('should return error for password without numbers', () {
        expect(Validators.validatePassword('abcdefgh'), '密碼需包含英文字母與數字');
      });

      test('should return null for valid password', () {
        expect(Validators.validatePassword('password123'), null);
        expect(Validators.validatePassword('P@ssw0rd'), null);
      });
    });

    group('calculatePasswordStrength', () {
      test('should return 0 for empty password', () {
        expect(Validators.calculatePasswordStrength(''), 0);
      });

      test('should return 0.2 for short password', () {
        expect(Validators.calculatePasswordStrength('123'), 0.2);
        expect(Validators.calculatePasswordStrength('abc'), 0.2);
      });

      test('should return 0.4 for long but simple password', () {
        expect(Validators.calculatePasswordStrength('12345678'), 0.4);
        expect(Validators.calculatePasswordStrength('abcdefgh'), 0.4);
      });

      test('should return 0.7 for moderate password', () {
        expect(Validators.calculatePasswordStrength('pass1234'), 0.7);
      });

      test('should return 0.85 for strong password', () {
        expect(Validators.calculatePasswordStrength('password12345'), 0.85);
      });

      test('should return 1.0 for very strong password', () {
        expect(Validators.calculatePasswordStrength('P@ssw0rd12345'), 1.0);
      });
    });
  });
}
