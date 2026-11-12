import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  test('newId is a version-7 UUID', () {
    expect(
      newId(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('later ids sort after earlier ones', () async {
    final first = newId();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final second = newId();
    expect(first.compareTo(second), lessThan(0));
  });

  test('10,000 ids are unique', () {
    expect({for (var i = 0; i < 10000; i++) newId()}, hasLength(10000));
  });
}
