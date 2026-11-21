import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/mountain_models.dart';

/// Result of asking the server for the list.
class MountainsResponse {
  const MountainsResponse.notModified() : payload = null, etag = null;
  const MountainsResponse.fresh(String this.payload, this.etag);
  final String? payload;
  final String? etag;
  bool get notModified => payload == null;
}

abstract interface class ExploreApi {
  /// Sends [etag] as If-None-Match; the server answers 304 when the list has not changed.
  Future<MountainsResponse> fetchMountains({String? etag});
}

class DioExploreApi implements ExploreApi {
  DioExploreApi(this._dio);
  final Dio _dio;

  @override
  Future<MountainsResponse> fetchMountains({String? etag}) async {
    final res = await _dio.get<String>(
      '/explore/mountains',
      options: Options(
        responseType: ResponseType.plain,
        headers: {'If-None-Match': ?etag},
        validateStatus: (s) => s == 200 || s == 304,
      ),
    );
    if (res.statusCode == 304) return const MountainsResponse.notModified();
    return MountainsResponse.fresh(res.data ?? '', res.headers.value('etag'));
  }
}

/// Cached-read mountain data: the last list is shown immediately (it works offline) and is checked
/// against the server only when it is older than [maxAge].
class MountainRepository {
  MountainRepository(this._db, this._api, {DateTime Function()? now, this.maxAge = const Duration(days: 7)}) : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final ExploreApi _api;
  final DateTime Function() _now;
  final Duration maxAge;

  static const _key = 'mountains';

  Stream<MountainsState> watch() async* {
    final row = await (_db.select(_db.httpCache)..where((c) => c.key.equals(_key))).getSingleOrNull();
    MountainList? cached;
    var fresh = false;
    if (row != null) {
      try {
        cached = MountainList.parse(row.payload);
        fresh = _now().difference(row.fetchedAt) < maxAge;
      } on Object {
        cached = null; // unreadable (written by another version): fetch again
      }
    }
    if (cached != null) yield MountainsReady(cached);
    if (fresh) return;
    if (cached == null) yield const MountainsLoading();

    try {
      final res = await _api.fetchMountains(etag: cached == null ? null : row?.etag);
      if (res.notModified && cached != null) {
        await _store(row!.payload, row.etag); // still current: restart the clock
        yield MountainsReady(cached);
        return;
      }
      final payload = res.payload ?? '';
      final list = MountainList.parse(payload); // validates before it is stored
      await _store(payload, res.etag);
      yield MountainsReady(list);
    } on Object {
      yield cached == null ? const MountainsUnavailable() : MountainsReady(cached, refreshFailed: true);
    }
  }

  Future<void> _store(String payload, String? etag) =>
      _db.into(_db.httpCache).insertOnConflictUpdate(HttpCacheCompanion.insert(key: _key, etag: Value(etag), payload: payload, fetchedAt: _now()));
}
