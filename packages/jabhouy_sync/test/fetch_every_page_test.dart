// Runs under `dart test`. The delete step of a pull trusts `complete`, so
// each way a list can look finished without being so is pinned here.
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:test/test.dart';

Result<PaginatedResponse<int>> page(
  List<int> items, {
  required int page,
  int? totalPages,
  int? total,
}) =>
    Ok(
      PaginatedResponse(
        items: items,
        pagination: Pagination(page: page, totalPage: totalPages, total: total),
      ),
    );

void main() {
  test('walks every page and is complete when the total agrees', () async {
    final asked = <int>[];
    final result = await fetchEveryPage<int>((p, limit) async {
      asked.add(p);
      return page(p == 1 ? [1, 2] : [3], page: p, totalPages: 2, total: 3);
    });

    expect(asked, [1, 2]);
    expect(result.items, [1, 2, 3]);
    expect(result.complete, isTrue);
  });

  test('a missing totalPages cannot pass page 1 off as everything', () async {
    // totalPages absent reads as 1, so hasNext is false after page 1; the
    // total of 250 is what says the list is not all there.
    final result = await fetchEveryPage<int>(
      (p, limit) async => page([1, 2], page: p, total: 250),
    );

    expect(result.complete, isFalse);
  });

  test('a missing total is never complete', () async {
    final result = await fetchEveryPage<int>(
      (p, limit) async => page([1, 2], page: p, totalPages: 1),
    );

    expect(result.complete, isFalse);
  });

  test('an empty server is complete, so its deletions reach the phone',
      () async {
    final result = await fetchEveryPage<int>(
      (p, limit) async => page(const [], page: p, totalPages: 1, total: 0),
    );

    expect(result.items, isEmpty);
    expect(result.complete, isTrue);
  });

  test('a failed page keeps what came and is incomplete', () async {
    final result = await fetchEveryPage<int>((p, limit) async {
      if (p == 2) return const Err(AppException('timeout'));
      return page([1, 2], page: p, totalPages: 3, total: 6);
    });

    expect(result.items, [1, 2]);
    expect(result.complete, isFalse);
    expect(result.error?.message, 'timeout');
  });

  test('a server that never stops is cut off and incomplete', () async {
    final result = await fetchEveryPage<int>(
      (p, limit) async => page([p], page: p, totalPages: 9999, total: 9999),
      maxPages: 3,
    );

    expect(result.items, [1, 2, 3]);
    expect(result.complete, isFalse);
  });
}
