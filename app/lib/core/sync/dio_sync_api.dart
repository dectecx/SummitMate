import 'package:dio/dio.dart';

import 'sync_api.dart';

/// [SyncApi] over HTTP. The [Dio] must already add the access token and refresh it on 401
/// (the auth layer owns that); a 401 that reaches this class means the session is gone.
class DioSyncApi implements SyncApi {
  DioSyncApi(this._dio);
  final Dio _dio;

  @override
  Future<PullPage> pull({String? since, int limit = 200}) async {
    final data = await _request(() => _dio.get<Map<String, dynamic>>('/sync/changes', queryParameters: {'since': ?since, 'limit': limit}));
    final changes = <String, List<Map<String, Object?>>>{};
    for (final entry in (data['changes'] as Map<String, dynamic>? ?? const {}).entries) {
      changes[entry.key] = [for (final row in entry.value as List) (row as Map).cast<String, Object?>()];
    }
    return PullPage(
      serverTime: data['server_time'] as String,
      nextSince: data['next_since'] as String,
      hasMore: data['has_more'] as bool,
      changes: changes,
    );
  }

  @override
  Future<List<PushOpResult>> push(List<PushRequestOp> ops) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/sync/push',
        data: {
          'ops': [
            for (final op in ops)
              {
                'op_id': op.opId,
                'entity': op.entity,
                'entity_id': op.entityId,
                'type': op.type,
                if (op.patch != null) 'patch': op.patch,
              },
          ],
        },
      ),
    );
    return [
      for (final r in data['results'] as List)
        PushOpResult(
          opId: (r as Map)['op_id'] as String,
          status: PushStatus.values.byName(r['status'] as String),
          message: r['message'] as String?,
          row: (r['row'] as Map?)?.cast<String, Object?>(),
        ),
    ];
  }

  Future<Map<String, dynamic>> _request(Future<Response<Map<String, dynamic>>> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body == null) throw const SyncServerException(502, message: 'empty response');
      return body;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw const SyncAuthException();
      if (status != null) throw SyncServerException(status, message: '${e.response?.data}');
      throw SyncNetworkException('${e.type.name}: ${e.error ?? e.message}');
    }
  }
}
