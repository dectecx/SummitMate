import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('Given empty email, When calling validateEmail, Then it should return error', () {
        expect(Validators.validateEmail(''), '請輸入 Email');
        expect(Validators.validateEmail(null), '請輸入 Email');
      });

      test('Given invalid email format, When calling validateEmail, Then it should return error', () {
        expect(Validators.validateEmail('test'), '請輸入有效的 Email 格式');
        expect(Validators.validateEmail('test@'), '請輸入有效的 Email 格式');
        expect(Validators.validateEmail('test@com'), '請輸入有效的 Email 格式');
        expect(Validators.validateEmail('@example.com'), '請輸入有效的 Email 格式');
      });

      test('Given valid email, When calling validateEmail, Then it should return null', () {
        expect(Validators.validateEmail('test@example.com'), null);
        expect(Validators.validateEmail('user.name+tag@domain.org'), null);
      });
    });

    group('validatePassword', () {
      test('Given empty password, When calling validatePassword, Then it should return error', () {
        expect(Validators.validatePassword(''), '請輸入密碼');
        expect(Validators.validatePassword(null), '請輸入密碼');
      });

      test('Given short password, When calling validatePassword, Then it should return error', () {
        expect(Validators.validatePassword('1234567'), '密碼至少需要 8 個字元');
      });

      test('Given password without letters, When calling validatePassword, Then it should return error', () {
        expect(Validators.validatePassword('12345678'), '密碼需包含英文字母與數字');
      });

      test('Given password without numbers, When calling validatePassword, Then it should return error', () {
        expect(Validators.validatePassword('abcdefgh'), '密碼需包含英文字母與數字');
      });

      test('Given valid password, When calling validatePassword, Then it should return null', () {
        expect(Validators.validatePassword('password123'), null);
        expect(Validators.validatePassword('P@ssw0rd'), null);
      });
    });

    group('calculatePasswordStrength', () {
      test('Given empty password, When calling calculatePasswordStrength, Then it should return 0', () {
        expect(Validators.calculatePasswordStrength(''), 0);
      });

      test('Given short password, When calling calculatePasswordStrength, Then it should return 0.2', () {
        expect(Validators.calculatePasswordStrength('123'), 0.2);
        expect(Validators.calculatePasswordStrength('abc'), 0.2);
      });

      test('Given long but simple password, When calling calculatePasswordStrength, Then it should return 0.4', () {
        expect(Validators.calculatePasswordStrength('12345678'), 0.4);
        expect(Validators.calculatePasswordStrength('abcdefgh'), 0.4);
      });

      test('Given moderate password, When calling calculatePasswordStrength, Then it should return 0.7', () {
        expect(Validators.calculatePasswordStrength('pass1234'), 0.7);
      });

      test('Given strong password, When calling calculatePasswordStrength, Then it should return 0.85', () {
        expect(Validators.calculatePasswordStrength('password12345'), 0.85);
      });

      test('Given very strong password, When calling calculatePasswordStrength, Then it should return 1.0', () {
        expect(Validators.calculatePasswordStrength('P@ssw0rd12345'), 1.0);
      });
    });
  });
}
