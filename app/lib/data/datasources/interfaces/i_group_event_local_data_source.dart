import '../../models/group_event_model.dart';

/// 揪團 (GroupEvent) 的本地資料來源介面
///
/// 負責定義對本地資料庫 (Hive) 的 CRUD 操作。
abstract interface class IGroupEventLocalDataSource {
  /// 取得所有揪團活動
  List<GroupEventModel> getAllEvents();

  /// 透過 ID 取得單一揪團
  ///
  /// [id] 揪團 ID
  GroupEventModel? getEventById(String id);

  /// 儲存揪團活動列表 (覆寫)
  ///
  /// [events] 揪團列表
  Future<void> saveEvents(List<GroupEventModel> events);

  /// 儲存單一揪團
  ///
  /// [event] 揪團資料
  Future<void> saveEvent(GroupEventModel event);

  /// 刪除揪團
  ///
  /// [id] 欲刪除的揪團 ID
  Future<void> deleteEvent(String id);

  /// 取得所有報名紀錄
  List<GroupEventApplicationModel> getAllApplications();

  /// 儲存報名紀錄列表
  Future<void> saveApplications(List<GroupEventApplicationModel> applications);

  /// 清除所有揪團資料 (登出時使用)
  Future<void> clear();
}
