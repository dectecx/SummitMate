import 'package:json_annotation/json_annotation.dart';

/// 裝備組合可見性
enum GearSetVisibility {
  /// 公開 - 任何人可查看 and 下載
  @JsonValue('public')
  public,

  /// 保護 - 可見標題，需輸入 Key 下載
  @JsonValue('protected')
  protected,

  /// 私人 - 不可見，需 Key 才能查看/下載
  @JsonValue('private')
  private;

  String get visibilityIcon {
    switch (this) {
      case GearSetVisibility.public:
        return '🌐';
      case GearSetVisibility.protected:
        return '🔒';
      case GearSetVisibility.private:
        return '🔐';
    }
  }
}
