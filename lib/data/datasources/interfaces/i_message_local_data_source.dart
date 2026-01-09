import 'package:hive/hive.dart';
import '../../models/message.dart';

abstract class IMessageLocalDataSource {
  Future<void> init();

  List<Message> getAll();
  Message? getByUuid(String uuid);
  Future<void> add(Message message);
  Future<void> delete(dynamic key);
  Future<void> clear();

  Stream<BoxEvent> watch();

  Future<void> saveLastSyncTime(DateTime time);
  DateTime? getLastSyncTime();
}
