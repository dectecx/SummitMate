class SqliteDbWrapper {
  void dispose() {
    throw UnsupportedError('SQLite is not supported on this platform.');
  }

  List<Map<String, dynamic>> select(String sql, [List<Object?> parameters = const []]) {
    throw UnsupportedError('SQLite is not supported on this platform.');
  }
}

SqliteDbWrapper openSqliteDb(String path) {
  throw UnsupportedError('SQLite is not supported on this platform.');
}
