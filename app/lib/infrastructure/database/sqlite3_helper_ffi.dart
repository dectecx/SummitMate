import 'package:sqlite3/sqlite3.dart' as sqlite;

class SqliteDbWrapper {
  final sqlite.Database _db;
  SqliteDbWrapper(this._db);

  void dispose() {
    _db.dispose();
  }

  List<Map<String, dynamic>> select(String sql, [List<Object?> parameters = const []]) {
    final result = _db.select(sql, parameters);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}

SqliteDbWrapper openSqliteDb(String path) {
  return SqliteDbWrapper(sqlite.sqlite3.open(path));
}
