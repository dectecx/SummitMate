import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../models/message.dart';
import '../interfaces/i_message_local_data_source.dart';

class MessageLocalDataSource implements IMessageLocalDataSource {
  static const String _boxName = HiveBoxNames.messages;
  static const String _prefKeyLastSync = 'msg_last_sync_time';

  Box<Message>? _box;

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Message>(_boxName);
    } else {
      _box = Hive.box<Message>(_boxName);
    }
  }

  Box<Message> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('MessageLocalDataSource not initialized. Call init() first.');
    }
    return _box!;
  }

  @override
  List<Message> getAll() {
    return box.values.toList();
  }

  @override
  Message? getByUuid(String uuid) {
    try {
      return box.values.firstWhere((m) => m.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(Message message) async {
    await box.add(message);
  }

  @override
  Future<void> delete(dynamic key) async {
    await box.delete(key);
  }

  @override
  Future<void> clear() async {
    await box.clear();
  }

  @override
  Stream<BoxEvent> watch() {
    return box.watch();
  }

  @override
  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_prefKeyLastSync, time.toIso8601String());
  }

  @override
  DateTime? getLastSyncTime() {
    final prefs = getIt<SharedPreferences>();
    final str = prefs.getString(_prefKeyLastSync);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
