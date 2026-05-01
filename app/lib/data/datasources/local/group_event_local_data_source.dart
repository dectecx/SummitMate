import 'package:injectable/injectable.dart';
import 'package:hive_ce/hive.dart';
import '../../models/group_event_model.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_group_event_local_data_source.dart';

/// 揪團本地資料來源實作 (Hive)
@LazySingleton(as: IGroupEventLocalDataSource)
class GroupEventLocalDataSource implements IGroupEventLocalDataSource {
  final Box<GroupEventModel> _events;
  final Box<GroupEventApplicationModel> _applications;

  GroupEventLocalDataSource({required HiveService hiveService})
    : _events = hiveService.getBox<GroupEventModel>(HiveBoxNames.groupEvents),
      _applications = hiveService.getBox<GroupEventApplicationModel>(HiveBoxNames.groupEventApplications);

  @override
  List<GroupEventModel> getAllEvents() => _events.values.toList();

  @override
  GroupEventModel? getEventById(String id) {
    try {
      return _events.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveEvents(List<GroupEventModel> events) async {
    await _events.clear();
    for (var event in events) {
      await _events.put(event.id, event);
    }
  }

  @override
  Future<void> saveEvent(GroupEventModel event) async {
    await _events.put(event.id, event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _events.delete(id);
  }

  @override
  List<GroupEventApplicationModel> getAllApplications() => _applications.values.toList();

  @override
  Future<void> saveApplications(List<GroupEventApplicationModel> applications) async {
    await _applications.clear();
    for (var app in applications) {
      await _applications.put(app.id, app);
    }
  }

  @override
  Future<void> clear() async {
    await _events.clear();
    await _applications.clear();
  }
}
