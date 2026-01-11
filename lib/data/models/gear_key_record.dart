/// 裝備清單上傳記錄
///
/// 用於本地儲存已上傳至雲端的清單 Key，方便使用者管理與存取。
class GearKeyRecord {
  /// 雲端唯一識別碼 (Key)
  final String key;

  /// 清單標題
  final String title;

  /// 可見度 (public / private / unlisted)
  final String visibility;

  /// 上傳時間
  final DateTime uploadedAt;

  GearKeyRecord({required this.key, required this.title, required this.visibility, required this.uploadedAt});

  /// 序列化為儲存字串 (for SharedPreferences / simple storage)
  String toStorageString() {
    return '$key|$title|$visibility|${uploadedAt.toIso8601String()}';
  }

  factory GearKeyRecord.fromStorageString(String str) {
    final parts = str.split('|');
    return GearKeyRecord(
      key: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      visibility: parts.length > 2 ? parts[2] : 'private',
      uploadedAt: parts.length > 3 ? DateTime.tryParse(parts[3]) ?? DateTime.now() : DateTime.now(),
    );
  }
}
