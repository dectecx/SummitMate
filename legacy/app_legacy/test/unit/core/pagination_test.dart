import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/core/models/paginated_list.dart';
import 'package:summitmate/core/utils/pagination.dart';

PaginatedList<int> _page(List<int> items, {required int page, required bool hasMore}) =>
    PaginatedList<int>(items: items, page: page, total: 0, hasMore: hasMore);

void main() {
  group('fetchAllPages', () {
    test('Given several pages, When fetching all, Then every item is returned in order', () async {
      final requested = <int>[];

      final all = await fetchAllPages<int>((page, limit) async {
        requested.add(page);
        return Success(switch (page) {
          1 => _page([1, 2], page: 1, hasMore: true),
          2 => _page([3, 4], page: 2, hasMore: true),
          _ => _page([5], page: 3, hasMore: false),
        });
      }, pageSize: 2);

      expect(all, [1, 2, 3, 4, 5]);
      expect(requested, [1, 2, 3]);
    });

    test('Given a single page, When fetching all, Then only one request is made', () async {
      var calls = 0;

      final all = await fetchAllPages<int>((page, limit) async {
        calls++;
        return Success(_page([1], page: 1, hasMore: false));
      });

      expect(all, [1]);
      expect(calls, 1);
    });

    test('Given the page size, When fetching, Then it is passed to every request', () async {
      final limits = <int>[];

      await fetchAllPages<int>((page, limit) async {
        limits.add(limit);
        return Success(_page(page == 1 ? [1] : [2], page: page, hasMore: page == 1));
      }, pageSize: 50);

      expect(limits, [50, 50]);
    });

    test(
      'Given a page that fails, When fetching all, Then the exception is thrown instead of returning partial data',
      () async {
        final failure = Exception('network down');

        expect(
          () => fetchAllPages<int>((page, limit) async {
            if (page == 2) return Failure(failure);
            return Success(_page([1], page: 1, hasMore: true));
          }),
          throwsA(same(failure)),
        );
      },
    );

    test('Given a server that always claims more pages, When fetching all, Then it stops with an error', () async {
      expect(
        () => fetchAllPages<int>((page, limit) async => Success(_page([page], page: page, hasMore: true)), maxPages: 5),
        throwsStateError,
      );
    });

    test('Given an empty page that claims more data, When fetching all, Then it stops instead of looping', () async {
      var calls = 0;

      final all = await fetchAllPages<int>((page, limit) async {
        calls++;
        return Success(_page(const [], page: page, hasMore: true));
      });

      expect(all, isEmpty);
      expect(calls, 1);
    });
  });
}
