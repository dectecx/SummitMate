class AppError {
  final String type;
  final String code;
  final String message;
  final String? param;

  const AppError({required this.type, required this.code, required this.message, this.param});

  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      type: json['type'] as String? ?? 'unknown_error',
      code: json['code'] as String? ?? 'unknown_code',
      message: json['message'] as String? ?? '發生未知錯誤',
      param: json['param'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'code': code, 'message': message, if (param != null) 'param': param};
  }

  @override
  String toString() {
    return 'AppError(type: $type, code: $code, message: $message, param: $param)';
  }
}
