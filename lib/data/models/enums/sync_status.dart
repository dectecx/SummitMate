
import 'package:hive/hive.dart';

part 'sync_status.g.dart';

@HiveType(typeId: 20)
enum SyncStatus {
  @HiveField(0)
  synced,

  @HiveField(1)
  pendingCreate,

  @HiveField(2)
  pendingUpdate,

  @HiveField(3)
  pendingDelete,

  @HiveField(4)
  error,
}
