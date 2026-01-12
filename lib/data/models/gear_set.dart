import 'gear_item.dart';
import 'meal_item.dart';

/// 裝備組合可見性
enum GearSetVisibility {
  /// 公開 - 任何人可查看和下載
  public,

  /// 保護 - 可見標題，需輸入 Key 下載
  protected,

  /// 私人 - 不可見，需 Key 才能查看/下載
  private,
}

/// 雲端裝備組合
class GearSet {
  /// 唯一識別碼
  final String id;

  /// 組合標題
  final String title;

  /// 上傳者暱稱
  final String author;

  /// 總重量 (g)
  final double totalWeight;

  /// 裝備數量
  final int itemCount;

  /// 可見性
  final GearSetVisibility visibility;

  /// 上傳時間
  final DateTime uploadedAt;

  /// 裝備列表 (下載時才有完整資料)
  final List<GearItem>? items;

  /// 糧食計畫 (下載時才有完整資料)
  final List<DailyMealPlan>? meals;

  GearSet({
    required this.id,
    required this.title,
    required this.author,
    required this.totalWeight,
    required this.itemCount,
    required this.visibility,
    required this.uploadedAt,
    this.items,
    this.meals,
  });

  /// 從 JSON 建立 (API 回應)
  factory GearSet.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) throw ArgumentError('GearSet ID is required');
    if (json['title'] == null) throw ArgumentError('GearSet title is required');
    if (json['author'] == null) throw ArgumentError('GearSet author is required');
    if (json['uploaded_at'] == null) throw ArgumentError('GearSet uploaded_at is required');

    return GearSet(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      totalWeight: (json['total_weight'] as num?)?.toDouble() ?? 0.0,
      itemCount: json['item_count'] as int? ?? 0,
      visibility: _parseVisibility(json['visibility'] as String?),
      uploadedAt: DateTime.parse(json['uploaded_at'] as String).toLocal(),
      items: (json['items'] as List<dynamic>?)?.map((item) => GearItem.fromJson(item as Map<String, dynamic>)).toList(),
      meals: (json['meals'] as List<dynamic>?)?.map((m) => DailyMealPlan.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  /// 轉換為 JSON (上傳用)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'total_weight': totalWeight,
      'item_count': itemCount,
      'visibility': visibility.name,
      'uploaded_at': uploadedAt.toIso8601String(),
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
      if (meals != null) 'meals': meals!.map((m) => m.toJson()).toList(),
    };
  }

  /// 解析可見性字串
  static GearSetVisibility _parseVisibility(String? value) {
    switch (value) {
      case 'public':
        return GearSetVisibility.public;
      case 'protected':
        return GearSetVisibility.protected;
      case 'private':
        return GearSetVisibility.private;
      default:
        return GearSetVisibility.public;
    }
  }

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
}
