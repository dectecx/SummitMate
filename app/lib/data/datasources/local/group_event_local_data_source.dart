import 'package:hive/hive.dart';
import '../../models/group_event.dart';
import '../../../core/constants.dart';
import '../../../infrastructure/tools/hive_service.dart';
import '../interfaces/i_group_event_local_data_source.dart';

/// 揪團本地資料來源實作 (Hive)
class GroupEventLocalDataSource implements IGroupEventLocalDataSource {
  final HiveService _hiveService;
  Box<GroupEvent>? _eventsBox;
  Box<GroupEventApplication>? _applicationsBox;

  GroupEventLocalDataSource({required HiveService hiveService}) : _hiveService = hiveService;

  @override
  Future<void> init() async {
    _eventsBox = await _hiveService.openBox<GroupEvent>(HiveBoxNames.groupEvents);
    _applicationsBox = await _hiveService.openBox<GroupEventApplication>(HiveBoxNames.groupEventApplications);
  }

  Box<GroupEvent> get _events {
    if (_eventsBox == null || !_eventsBox!.isOpen) {
      throw StateError('GroupEventLocalDataSource not initialized. Call init() first.');
    }
    return _eventsBox!;
  }

  Box<GroupEventApplication> get _applications {
    if (_applicationsBox == null || !_applicationsBox!.isOpen) {
      throw StateError('GroupEventLocalDataSource not initialized. Call init() first.');
    }
    return _applicationsBox!;
  }

  @override
  List<GroupEvent> getAllEvents() => _events.values.toList();

  @override
  GroupEvent? getEventById(String id) {
    try {
      return _events.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveEvents(List<GroupEvent> events) async {
    await _events.clear();
    for (var event in events) {
      await _events.put(event.id, event);
    }
  }

  @override
  Future<void> saveEvent(GroupEvent event) async {
    await _events.put(event.id, event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _events.delete(id);
  }

  @override
  List<GroupEventApplication> getAllApplications() => _applications.values.toList();

  @override
  Future<void> saveApplications(List<GroupEventApplication> applications) async {
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
