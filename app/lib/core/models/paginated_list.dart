class PaginatedList<T> {
  final List<T> items;
  final int page;
  final int total;
  final bool hasMore;

  const PaginatedList({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedList.empty() => const PaginatedList(items: [], page: 1, total: 0, hasMore: false);
}
