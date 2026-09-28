import 'package:jabhouy_core/jabhouy_core.dart';

/// Every row a paged endpoint holds, and whether that is provably all.
class EveryPage<T> {
  const EveryPage(this.items, {required this.complete, this.error});

  final List<T> items;

  /// True only when the server said there is no next page *and* the rows
  /// collected match its `total`. A pull may delete local rows missing
  /// from [items] only when this is true.
  final bool complete;

  /// Why it stopped early, when it did.
  final AppException? error;
}

/// Walks pages of [limit] from 1 until the server says there is no next.
///
/// Completeness asks for two agreeing signals because deleting is the one
/// irreversible step in a pull: `Pagination.fromJson` defaults a missing
/// `totalPages` to 1, which alone would make page 1 look like everything.
/// A missing `total` reads as 0 and never matches a non-empty list, so an
/// unknown total deletes nothing. [maxPages] stops a server that never
/// says it is done; what it stops with is incomplete.
Future<EveryPage<T>> fetchEveryPage<T>(
  Future<Result<PaginatedResponse<T>>> Function(int page, int limit) fetch, {
  int limit = 100,
  int maxPages = 200,
}) async {
  final items = <T>[];
  for (var page = 1; page <= maxPages; page++) {
    switch (await fetch(page, limit)) {
      case Err(:final error):
        return EveryPage(items, complete: false, error: error);
      case Ok(:final value):
        items.addAll(value.items);
        if (value.items.isEmpty || !value.pagination.hasNext) {
          return EveryPage(
            items,
            complete: items.length == (value.pagination.total ?? -1),
          );
        }
    }
  }
  return EveryPage(
    items,
    complete: false,
    error: AppException('Stopped after $maxPages pages'),
  );
}
