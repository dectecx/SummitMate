import '../error/result.dart';
import '../models/paginated_list.dart';

/// 逐頁取得所有資料。
///
/// 同步需要「完整的遠端清單」才能正確偵測遠端刪除，只取第一頁會把其餘資料誤判為已被刪除。
/// 任何一頁失敗就丟出該例外，由呼叫端（同步 adapter）回報為本輪同步失敗。
///
/// [pageSize] 為每頁筆數（需不超過後端上限）；[maxPages] 是避免後端回應異常時無限迴圈的保險。
Future<List<T>> fetchAllPages<T>(
  Future<Result<PaginatedList<T>, Exception>> Function(int page, int limit) fetchPage, {
  int pageSize = 100,
  int maxPages = 1000,
}) async {
  final all = <T>[];
  for (var page = 1; page <= maxPages; page++) {
    final result = await fetchPage(page, pageSize);
    switch (result) {
      case Failure(exception: final e):
        throw e;
      case Success(value: final list):
        all.addAll(list.items);
        if (!list.hasMore || list.items.isEmpty) return all;
    }
  }
  throw StateError('分頁資料超過 $maxPages 頁，已中止以避免無限迴圈');
}
