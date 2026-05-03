import 'package:drift/drift.dart';
import '../../../domain/enums/sync_status.dart';

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(String fromDb) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == fromDb,
      orElse: () => SyncStatus.synced,
    );
  }

  @override
  String toSql(SyncStatus value) {
    return value.name;
  }
}
