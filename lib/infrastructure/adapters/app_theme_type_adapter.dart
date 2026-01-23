import 'package:hive/hive.dart';
import 'package:summitmate/core/theme.dart';

/// AppThemeType 的手動 Hive Adapter
/// 用於解耦 Core 層與 Hive 的依賴
class AppThemeTypeAdapter extends TypeAdapter<AppThemeType> {
  @override
  final int typeId = 30;

  @override
  AppThemeType read(BinaryReader reader) {
    // 讀取索引值並轉回 Enum
    final index = reader.readByte();
    // 簡單邊界檢查，若越界則回傳預設值 (0: morandi)
    if (index < 0 || index >= AppThemeType.values.length) {
      return AppThemeType.nature;
    }
    return AppThemeType.values[index];
  }

  @override
  void write(BinaryWriter writer, AppThemeType obj) {
    // 將 Enum 轉為索引值儲存 (0, 1, 2...)
    writer.writeByte(obj.index);
  }
}
