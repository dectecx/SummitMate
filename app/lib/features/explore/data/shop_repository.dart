import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/shop_models.dart';
import 'mountain_repository.dart' show MountainsResponse;

abstract interface class ShopsApi {
  Future<MountainsResponse> fetchShops({String? etag});
}

class DioShopsApi implements ShopsApi {
  DioShopsApi(this._dio);
  final Dio _dio;

  @override
  Future<MountainsResponse> fetchShops({String? etag}) async {
    final res = await _dio.get<String>(
      '/explore/shops',
      options: Options(responseType: ResponseType.plain, headers: {'If-None-Match': ?etag}, validateStatus: (s) => s == 200 || s == 304),
    );
    if (res.statusCode == 304) return const MountainsResponse.notModified();
    return MountainsResponse.fresh(res.data ?? '', res.headers.value('etag'));
  }
}

/// Cached-read shop list, the same way as the mountains: the last list shows at once (and offline) and is
/// checked against the server only when older than [maxAge].
class ShopRepository {
  ShopRepository(this._db, this._api, {DateTime Function()? now, this.maxAge = const Duration(days: 7)}) : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final ShopsApi _api;
  final DateTime Function() _now;
  final Duration maxAge;

  static const _key = 'shops';

  Stream<ShopsState> watch() async* {
    final row = await (_db.select(_db.httpCache)..where((c) => c.key.equals(_key))).getSingleOrNull();
    ShopList? cached;
    var fresh = false;
    if (row != null) {
      try {
        cached = ShopList.parse(row.payload);
        fresh = _now().difference(row.fetchedAt) < maxAge;
      } on Object {
        cached = null;
      }
    }
    if (cached != null) yield ShopsReady(cached);
    if (fresh) return;
    if (cached == null) yield const ShopsLoading();
    try {
      final res = await _api.fetchShops(etag: cached == null ? null : row?.etag);
      if (res.notModified && cached != null) {
        await _store(row!.payload, row.etag);
        yield ShopsReady(cached);
        return;
      }
      final payload = res.payload ?? '';
      final list = ShopList.parse(payload);
      await _store(payload, res.etag);
      yield ShopsReady(list);
    } on Object {
      yield cached == null ? const ShopsUnavailable() : ShopsReady(cached, refreshFailed: true);
    }
  }

  Future<void> _store(String payload, String? etag) =>
      _db.into(_db.httpCache).insertOnConflictUpdate(HttpCacheCompanion.insert(key: _key, etag: Value(etag), payload: payload, fetchedAt: _now()));
}
