import 'package:dio/dio.dart';

import '../domain/set_item.dart';

/// Who may open a shared set.
enum SharedVisibility {
  public,
  protected,
  private;

  String get label => switch (this) {
    SharedVisibility.public => '公開',
    SharedVisibility.protected => '需要 Key',
    SharedVisibility.private => '只有我',
  };

  static SharedVisibility parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => SharedVisibility.private);
}

class SharedSetSummary {
  const SharedSetSummary({
    required this.id,
    required this.title,
    required this.authorName,
    required this.visibility,
    required this.totalWeight,
    required this.gearCount,
    required this.mealCount,
    required this.createdAt,
    required this.mine,
  });

  final String id;
  final String title;
  final String authorName;
  final SharedVisibility visibility;

  /// Grams, gear only.
  final double totalWeight;
  final int gearCount;
  final int mealCount;
  final DateTime createdAt;
  final bool mine;

  factory SharedSetSummary.fromJson(Map<String, dynamic> j) => SharedSetSummary(
    id: j['id'] as String,
    title: j['title'] as String,
    authorName: (j['author_name'] as String?) ?? '',
    visibility: SharedVisibility.parse(j['visibility'] as String?),
    totalWeight: ((j['total_weight'] as num?) ?? 0).toDouble(),
    gearCount: ((j['gear_count'] as num?) ?? 0).toInt(),
    mealCount: ((j['meal_count'] as num?) ?? 0).toInt(),
    createdAt: DateTime.tryParse((j['created_at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    mine: j['mine'] == true,
  );
}

class SharedSetDetail {
  const SharedSetDetail(this.summary, this.items);
  final SharedSetSummary summary;
  final List<SetItem> items;
}

class SharedSetPage {
  const SharedSetPage(this.items, this.nextCursor);
  final List<SharedSetSummary> items;
  final String? nextCursor;
}

/// A failed request. [code] is the server's error code, or `network` when the server could not be reached.
class SharedSetsException implements Exception {
  const SharedSetsException({required this.code, this.status = 0, this.message = ''});
  final String code;
  final int status;
  final String message;

  bool get needsKey => code == 'access_key_required';
  bool get wrongKey => code == 'invalid_access_key';

  /// What to tell the person.
  String get text => switch (code) {
    'network' => '目前無法連線，請檢查網路後再試。',
    'access_key_required' => '這份組合需要 Key。',
    'invalid_access_key' => 'Key 不正確。',
    'too_many_requests' => 'Key 輸入錯誤太多次，請稍後再試。',
    'shared_set_not_found' => '找不到這份組合，可能已被刪除。',
    'unauthorized' => '請先登入。',
    _ => message.isNotEmpty ? message : '發生錯誤（$code）',
  };

  @override
  String toString() => 'SharedSetsException($status $code)';
}

/// The cloud sharing API (online only).
abstract interface class SharedSetsApi {
  Future<SharedSetPage> list({required String scope, String q = '', String? cursor});
  Future<SharedSetDetail> get(String id, {String? key});
  Future<SharedSetSummary> create({required String title, required SharedVisibility visibility, String? key, required List<SetItem> items});
  Future<void> delete(String id);
}

class DioSharedSetsApi implements SharedSetsApi {
  DioSharedSetsApi(this._dio);
  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw const SharedSetsException(code: 'network');
      final data = res.data;
      throw SharedSetsException(
        status: res.statusCode ?? 0,
        code: data is Map && data['code'] is String ? data['code'] as String : 'http_${res.statusCode}',
        message: data is Map && data['message'] is String ? data['message'] as String : '',
      );
    }
  }

  @override
  Future<SharedSetPage> list({required String scope, String q = '', String? cursor}) => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>('/shared-sets', queryParameters: {'scope': scope, if (q.trim().isNotEmpty) 'q': q.trim(), 'cursor': ?cursor});
    final data = res.data ?? const {};
    return SharedSetPage([for (final s in (data['items'] as List? ?? const [])) SharedSetSummary.fromJson((s as Map).cast<String, dynamic>())], data['next_cursor'] as String?);
  });

  @override
  Future<SharedSetDetail> get(String id, {String? key}) => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>('/shared-sets/$id', options: Options(headers: {if (key != null && key.isNotEmpty) 'X-Access-Key': key}));
    final data = res.data!;
    return SharedSetDetail(SharedSetSummary.fromJson(data), [for (final i in (data['items'] as List? ?? const [])) ?SetItem.tryFromJson(i)]);
  });

  @override
  Future<SharedSetSummary> create({required String title, required SharedVisibility visibility, String? key, required List<SetItem> items}) => _run(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/shared-sets',
      data: {'title': title, 'visibility': visibility.name, if (visibility == SharedVisibility.protected) 'access_key': key, 'items': [for (final i in items.take(maxSetItems)) i.toJson()]},
    );
    return SharedSetSummary.fromJson(res.data!);
  });

  @override
  Future<void> delete(String id) => _run(() async {
    await _dio.delete<void>('/shared-sets/$id');
  });
}
