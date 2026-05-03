import '../../../domain/entities/group_event.dart';

/// 揪團 (GroupEvent) 的本地資料來源介面
abstract interface class IGroupEventLocalDataSource {
  /// 取得所有揪團活動
  Future<List<GroupEvent>> getAllEvents();

  /// 透過 ID 取得單一揪團
  Future<GroupEvent?> getEventById(String id);

  /// 儲存揪團活動列表 (覆寫)
  Future<void> saveEvents(List<GroupEvent> events);

  /// 儲存單一揪團
  Future<void> saveEvent(GroupEvent event);

  /// 刪除揪團
  Future<void> deleteEvent(String id);

  /// 取得所有報名紀錄
  Future<List<GroupEventApplication>> getAllApplications();

  /// 儲存報名紀錄列表
  Future<void> saveApplications(List<GroupEventApplication> applications);

  /// 清除所有揪團資料
  Future<void> clear();
}
