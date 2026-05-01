import 'package:json_annotation/json_annotation.dart';
import 'gear_item_model.dart';
import 'meal_item.dart';

part 'gear_set.g.dart';

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
  private,
}

/// 雲端裝備組合
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GearSet {
  /// 唯一識別碼
  final String id;

  /// 組合標題
  final String title;

  /// 上傳者暱稱
  final String author;

  /// 總重量 (g)
  @JsonKey(defaultValue: 0.0)
  final double totalWeight;

  /// 裝備數量
  @JsonKey(defaultValue: 0)
  final int itemCount;

  /// 可見性
  @JsonKey(defaultValue: GearSetVisibility.public)
  final GearSetVisibility visibility;

  /// 上傳時間
  @JsonKey(fromJson: _parseDateTime)
  final DateTime uploadedAt;

  /// 建立時間
  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;

  /// 建立者
  final String createdBy;

  /// 更新時間
  @JsonKey(fromJson: _parseDateTime)
  final DateTime updatedAt;

  /// 更新者
  final String updatedBy;

  /// 裝備列表 (下載時才有完整資料)
  final List<GearItemModel>? items;

  /// 糧食計畫 (下載時才有完整資料)
  final List<DailyMealPlan>? meals;

  GearSet({
    required this.id,
    required this.title,
    required this.author,
    this.totalWeight = 0.0,
    this.itemCount = 0,
    this.visibility = GearSetVisibility.public,
    required this.uploadedAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.items,
    this.meals,
  });

  factory GearSet.fromJson(Map<String, dynamic> json) => _$GearSetFromJson(json);
  Map<String, dynamic> toJson() => _$GearSetToJson(this);

  /// 可見性圖示
  String get visibilityIcon {
    switch (visibility) {
      case GearSetVisibility.public:
        return '🌐';
      case GearSetVisibility.protected:
        return '🔒';
      case GearSetVisibility.private:
        return '🔐';
    }
  }

  /// 格式化重量顯示
  String get formattedWeight {
    if (totalWeight >= 1000) {
      return '${(totalWeight / 1000).toStringAsFixed(1)} kg';
    }
    return '${totalWeight.toStringAsFixed(0)} g';
  }

  // DateTime parsing helper
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) throw ArgumentError('DateTime is required');
    if (value is DateTime) return value;
    return DateTime.parse(value.toString()).toLocal();
  }
}
