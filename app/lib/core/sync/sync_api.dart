/// Wire types and the transport interface of the sync protocol (see `backend/api/openapi.yaml`).
library;

class PullPage {
  const PullPage({required this.serverTime, required this.nextSince, required this.hasMore, required this.changes});

  final String serverTime;

  /// Kept as the server's raw string so its microsecond precision survives.
  final String nextSince;
  final bool hasMore;

  /// Entity name -> changed rows (tombstones have a non-null `deleted_at`).
  final Map<String, List<Map<String, Object?>>> changes;
}

class PushRequestOp {
  const PushRequestOp({required this.opId, required this.entity, required this.entityId, required this.type, this.patch});

  final String opId;
  final String entity;
  final String entityId;

  /// `upsert` or `delete`.
  final String type;
  final Map<String, Object?>? patch;
}

enum PushStatus { applied, gone, forbidden, invalid }

class PushOpResult {
  const PushOpResult({required this.opId, required this.status, this.message, this.row});

  final String opId;
  final PushStatus status;
  final String? message;
  final Map<String, Object?>? row;
}

abstract interface class SyncApi {
  Future<PullPage> pull({String? since, int limit});
  Future<List<PushOpResult>> push(List<PushRequestOp> ops);
}

/// The request never completed (offline, timeout, DNS). Retry later.
class SyncNetworkException implements Exception {
  const SyncNetworkException([this.message = 'network error']);
  final String message;
  @override
  String toString() => 'SyncNetworkException: $message';
}

/// The server rejected our credentials and a token refresh did not help.
class SyncAuthException implements Exception {
  const SyncAuthException();
  @override
  String toString() => 'SyncAuthException';
}

/// An unexpected server response. [retryable] is true for 5xx.
class SyncServerException implements Exception {
  const SyncServerException(this.statusCode, {this.message = ''});
  final int statusCode;
  final String message;
  bool get retryable => statusCode >= 500;
  @override
  String toString() => 'SyncServerException($statusCode): $message';
}
