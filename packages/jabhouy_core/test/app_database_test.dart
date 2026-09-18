// Runs under `dart test`, not `flutter test`, and that is the point.
//
// This package must never depend on Flutter. A stray `package:flutter`
// import would resolve fine in the workspace analyzer, because every
// package shares one package_config. It cannot survive here: the plain
// Dart VM has no `dart:ui`, so this suite fails to load. That failure is
// the enforcement behind "jabhouy_core builds with no Flutter".
import 'package:drift/native.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('opens on a plain Dart VM and creates every declared table', () async {
    expect(db.schemaVersion, 6);

    // Each select proves the table exists; a missing one throws here.
    expect(await db.select(db.customers).get(), isEmpty);
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.shopItems).get(), isEmpty);
    expect(await db.select(db.loaners).get(), isEmpty);
    expect(await db.select(db.bankNotifications).get(), isEmpty);
    expect(await db.select(db.outboxEntries).get(), isEmpty);
  });

  test('a shop item round-trips with the category it points at', () async {
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(id: const Value(7), name: 'Drinks'),
        );
    await db.into(db.shopItems).insert(
          ShopItemsCompanion.insert(
            id: const Value(42),
            name: 'Iced coffee',
            defaultPrice: const Value(5000),
            categoryId: const Value(7),
          ),
        );

    final item = await db.select(db.shopItems).getSingle();
    expect(item.id, 42);
    expect(item.name, 'Iced coffee');
    expect(item.defaultPrice, 5000);
    expect(item.categoryId, 7);

    // Defaults the sync engine will replace with a typed SyncStatus.
    expect(item.syncStatus, SyncStatus.synced);
    expect(item.isDeleted, isFalse);
  });

  test('a duplicate bank notification fingerprint is rejected', () async {
    Future<void> insert(String fingerprint) => db
        .into(db.bankNotifications)
        .insert(
          BankNotificationsCompanion.insert(
            fingerprint: fingerprint,
            packageName: 'com.paygo24.ibank',
            bankKey: 'aba',
            message: 'Incoming USD 20',
            receivedAt: DateTime.utc(2026),
          ),
        );

    await insert('abc');

    // The uniqueKeys index is what makes replaying a sync job safe. The
    // outbox engine generalises this guarantee to every entity.
    await expectLater(insert('abc'), throwsA(isA<SqliteException>()));
    expect(await db.select(db.bankNotifications).get(), hasLength(1));
  });

  test('clearUserData empties every table in one transaction', () async {
    await db.into(db.customers).insert(
          CustomersCompanion.insert(id: const Value(1), name: 'Sok'),
        );
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(id: const Value(1), name: 'Drinks'),
        );
    await db.into(db.loaners).insert(
          LoanersCompanion.insert(
            id: const Value(1),
            amount: 20000,
            createdAt: DateTime.utc(2026),
          ),
        );

    await db.clearUserData();

    expect(await db.select(db.customers).get(), isEmpty);
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.loaners).get(), isEmpty);
  });
}
