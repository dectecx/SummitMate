class Validators {
  static final RegExp _emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  static final RegExp _letterRegExp = RegExp(r'[a-zA-Z]');
  static final RegExp _numberRegExp = RegExp(r'[0-9]');

  /// 驗證 Email 格式
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入 Email';
    }
    if (!_emailRegExp.hasMatch(value)) {
      return '請輸入有效的 Email 格式';
    }
    return null;
  }

  /// 驗證密碼強度
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入密碼';
    }
    if (value.length < 8) {
      return '密碼至少需要 8 個字元';
    }
    if (!_letterRegExp.hasMatch(value) || !_numberRegExp.hasMatch(value)) {
      return '密碼需包含英文字母與數字';
    }
    return null;
  }

  /// 計算密碼強度 (0.0 to 1.0)
  static double calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    if (password.length < 8) return 0.2;

    bool hasLetters = _letterRegExp.hasMatch(password);
    bool hasNumbers = _numberRegExp.hasMatch(password);
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasLetters || !hasNumbers) return 0.4; // 弱
    if (password.length < 10) return 0.7; // 中
    if (hasSpecial) return 1.0; // 強 (10+ 且有特殊字元)
    return 0.85; // 強 (10+)
  }
}
