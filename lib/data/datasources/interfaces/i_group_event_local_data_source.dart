import '../../models/group_event.dart';

/// 揪團 (GroupEvent) 的本地資料來源介面
///
/// 負責定義對本地資料庫 (Hive) 的 CRUD 操作。
abstract class IGroupEventLocalDataSource {
  /// 初始化資料來源
  Future<void> init();

  /// 取得所有揪團活動
  List<GroupEvent> getAllEvents();

  /// 透過 ID 取得單一揪團
  ///
  /// [id] 揪團 ID
  GroupEvent? getEventById(String id);

  /// 儲存揪團活動列表 (覆寫)
  ///
  /// [events] 揪團列表
  Future<void> saveEvents(List<GroupEvent> events);

  /// 儲存單一揪團
  ///
  /// [event] 揪團資料
  Future<void> saveEvent(GroupEvent event);

  /// 刪除揪團
  ///
  /// [id] 欲刪除的揪團 ID
  Future<void> deleteEvent(String id);

  /// 取得所有報名紀錄
  List<GroupEventApplication> getAllApplications();

  /// 儲存報名紀錄列表
  Future<void> saveApplications(List<GroupEventApplication> applications);

  /// 清除所有揪團資料 (登出時使用)
  Future<void> clear();
}
