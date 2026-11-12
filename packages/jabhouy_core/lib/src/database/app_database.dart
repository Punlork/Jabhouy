import 'package:drift/drift.dart';
import 'package:jabhouy_core/src/sync/outbox.dart';
import 'package:jabhouy_core/src/sync/sync_status.dart';

part 'app_database.g.dart';

class Customers extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer()
      .map(const SyncStatusConverter())
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer()
      .map(const SyncStatusConverter())
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ShopItems extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get defaultPrice => integer().nullable()();
  IntColumn get customerPrice => integer().nullable()();
  IntColumn get sellerPrice => integer().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer()
      .map(const SyncStatusConverter())
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Loaners extends Table {
  IntColumn get id => integer()();
  IntColumn get amount => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get customer => text().nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer()
      .map(const SyncStatusConverter())
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class BankNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fingerprint => text()();
  TextColumn get packageName => text()();
  TextColumn get bankKey => text()();
  TextColumn get title => text().nullable()();
  TextColumn get message => text()();
  TextColumn get rawPayload => text().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  BoolColumn get isIncome => boolean().withDefault(const Constant(true))();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('native'))();
  IntColumn get syncStatus => integer()
      .map(const SyncStatusConverter())
      .withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {fingerprint},
      ];
}

// Redesign tables (schema 9). They mirror jabhouy-api's schema and its
// singular SQL names, and sit beside the old tables until schema 10 drops
// those at release. Class names end in `Table` and rows in `Row` because
// the old `Customers` table already owns the `Customer` row class.

/// Columns every synced redesign row carries. The server sets them.
mixin SyncedColumns on Table {
  TextColumn get shopId => text()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get updatedBy => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('ShopSettingsRow')
class ShopSettingsTable extends Table with SyncedColumns {
  @override
  String get tableName => 'shop_settings';

  BoolColumn get useWholesalePrice =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get useCostPrice => boolean().withDefault(const Constant(true))();
  TextColumn get defaultCurrency => text().withDefault(const Constant('KHR'))();
  IntColumn get khrPerUsd => integer().withDefault(const Constant(4000))();
  BoolColumn get showConverted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get rateUpdatedAt => dateTime().nullable()();
  TextColumn get rateUpdatedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {shopId};
}

@DataClassName('MemberRow')
class MemberTable extends Table with SyncedColumns {
  @override
  String get tableName => 'member';

  TextColumn get userId => text()();
  TextColumn get displayName => text().nullable()();

  /// `owner`, `editor` or `viewer`.
  TextColumn get role => text()();

  @override
  Set<Column> get primaryKey => {shopId, userId};
}

@DataClassName('CategoryRow')
class CategoryTable extends Table with SyncedColumns {
  @override
  String get tableName => 'category';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Child of [CategoryTable]; travels inside it.
@DataClassName('CategoryUnitRow')
class CategoryUnitTable extends Table {
  @override
  String get tableName => 'category_unit';

  TextColumn get categoryId => text()();
  TextColumn get unit => text()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {categoryId, unit};
}

@DataClassName('ItemRow')
class ItemTable extends Table with SyncedColumns {
  @override
  String get tableName => 'item';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Other names people use, as a JSON list of strings.
  TextColumn get nicknames => text().withDefault(const Constant('[]'))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One Price option; child of [ItemTable], replaced as a set on save.
@DataClassName('ItemPriceRow')
class ItemPriceTable extends Table {
  @override
  String get tableName => 'item_price';

  TextColumn get id => text()();
  TextColumn get itemId => text()();
  TextColumn get unit => text()();
  IntColumn get packQty => integer().nullable()();

  /// Unique within a Shop, checked on the phone only (decision 41).
  TextColumn get barcode => text().nullable()();
  TextColumn get currency => text()();

  /// Whole riel or cents. Null means no price yet, never 0.
  IntColumn get price => integer().nullable()();
  IntColumn get wholesale => integer().nullable()();
  IntColumn get cost => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Items this phone opened, per Shop; never synced (decision 46).
@DataClassName('RecentItemRow')
class RecentItemTable extends Table {
  @override
  String get tableName => 'recent_item';

  TextColumn get shopId => text()();
  TextColumn get itemId => text()();
  DateTimeColumn get viewedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {shopId, itemId};
}

/// How far this phone has pulled each Shop's `/changes`: the highest
/// `seq` applied (decision 36). Not user data a pull may overwrite.
@DataClassName('ShopSyncCursorRow')
class ShopSyncCursors extends Table {
  TextColumn get shopId => text()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {shopId};
}

@DataClassName('CustomerRow')
class CustomerTable extends Table with SyncedColumns {
  @override
  String get tableName => 'customer';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CreditRow')
class CreditTable extends Table with SyncedColumns {
  @override
  String get tableName => 'credit';

  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get currency => text()();

  /// Null means no amount yet.
  IntColumn get amount => integer().nullable()();

  /// The shop's rate when this credit was made; never follows later changes.
  IntColumn get khrPerUsd => integer()();

  /// `unpaid` or `paid`.
  TextColumn get status => text()();
  DateTimeColumn get takenAt => dateTime()();

  /// `YYYY-MM-DD`, the local day.
  TextColumn get dueDate => text().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Child of [CreditTable]: a copy of what was taken, at that time's price.
@DataClassName('CreditItemRow')
class CreditItemTable extends Table {
  @override
  String get tableName => 'credit_item';

  TextColumn get id => text()();
  TextColumn get creditId => text()();
  TextColumn get priceId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  IntColumn get qty => integer()();
  TextColumn get currency => text()();
  IntColumn get unitPrice => integer()();
  IntColumn get total => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Customers,
    Categories,
    ShopItems,
    Loaners,
    BankNotifications,
    OutboxEntries,
    SyncCursors,
    ShopSettingsTable,
    MemberTable,
    CategoryTable,
    CategoryUnitTable,
    ItemTable,
    ItemPriceTable,
    CustomerTable,
    CreditTable,
    CreditItemTable,
    RecentItemTable,
    ShopSyncCursors,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Takes its executor rather than opening one, so this package stays
  /// free of `dart:io`, path_provider and sqlite3_flutter_libs. The app
  /// passes a file-backed executor; tests pass `NativeDatabase.memory()`.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 11;

  /// The ids of [type] rows that still have a job in the outbox.
  ///
  /// Until that job clears, the phone's copy of the row is newer than the
  /// server's, so a pull must leave it alone. A job leaves the outbox only
  /// once the server confirms it, so a push in flight still counts.
  Future<Set<String>> queuedLocalIds(SyncEntityType type) async {
    final jobs = await (select(outboxEntries)
          ..where((t) => t.entityType.equalsValue(type)))
        .get();
    return jobs.map((job) => job.localId).toSet();
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(customers, customers.isDeleted);
          await m.addColumn(customers, customers.syncStatus);
          await m.addColumn(categories, categories.isDeleted);
          await m.addColumn(categories, categories.syncStatus);
          await m.addColumn(shopItems, shopItems.isDeleted);
          await m.addColumn(shopItems, shopItems.syncStatus);
          await m.addColumn(loaners, loaners.isDeleted);
          await m.addColumn(loaners, loaners.syncStatus);
        }

        if (from < 3) {
          await m.addColumn(loaners, loaners.customer);
        }

        if (from < 4) {
          await m.createTable(bankNotifications);
        }

        if (from < 5) {
          await m.addColumn(bankNotifications, bankNotifications.syncStatus);
        }

        if (from < 6) {
          await m.createTable(outboxEntries);
          await m.createIndex(outboxDrainIdx);
        }

        // Two outbox columns were renamed before anything ever wrote to
        // the table: `fingerprint` -> `idempotencyKey` and
        // `entityLocalId` -> `localId`. Recreating is correct precisely
        // because the queue is guaranteed empty -- schema 6 shipped on no
        // device, and no code enqueued a job until phase 3.
        if (from < 7) {
          await m.deleteTable(outboxEntries.actualTableName);
          await m.createTable(outboxEntries);
          await m.createIndex(outboxDrainIdx);
        }

        if (from < 8) {
          await m.createTable(syncCursors);
        }

        if (from < 9) {
          for (final table in _redesignTableList) {
            await m.createTable(table);
          }
        }

        // From below 9 the tables above were just created with these
        // columns already, so only a schema-9 file adds them.
        if (from == 9) {
          await m.addColumn(itemTable, itemTable.nicknames);
          await m.addColumn(itemPriceTable, itemPriceTable.barcode);
        }

        if (from < 10) {
          await m.createTable(recentItemTable);
        }

        if (from < 11) {
          await m.createTable(shopSyncCursors);
        }
      },
    );
  }

  List<TableInfo<Table, Object?>> get _redesignTableList => [
        shopSettingsTable,
        memberTable,
        categoryTable,
        categoryUnitTable,
        itemTable,
        itemPriceTable,
        customerTable,
        creditTable,
        creditItemTable,
      ];

  /// Forgets everything held for [shopId]: its rows, recents, queued jobs
  /// and cursor. For a removed Member (decision 11); other Shops stay.
  Future<void> wipeShop(String shopId) => transaction(() async {
    Future<Set<String>> ids(
      TableInfo<Table, Object?> table,
      GeneratedColumn<String> shop,
      GeneratedColumn<String> id,
    ) async {
      final query = selectOnly(table)
        ..addColumns([id])
        ..where(shop.equals(shopId));
      return {for (final row in await query.get()) row.read(id)!};
    }

    final itemIds = await ids(itemTable, itemTable.shopId, itemTable.id);
    final categoryIds = await ids(
      categoryTable,
      categoryTable.shopId,
      categoryTable.id,
    );
    final creditIds = await ids(creditTable, creditTable.shopId, creditTable.id);
    final customerIds = await ids(
      customerTable,
      customerTable.shopId,
      customerTable.id,
    );
    await (delete(itemPriceTable)..where((t) => t.itemId.isIn(itemIds))).go();
    await (delete(
      categoryUnitTable,
    )..where((t) => t.categoryId.isIn(categoryIds))).go();
    await (delete(
      creditItemTable,
    )..where((t) => t.creditId.isIn(creditIds))).go();
    for (final table in <TableInfo<Table, Object?>>[
      itemTable,
      categoryTable,
      customerTable,
      creditTable,
      memberTable,
      shopSettingsTable,
    ]) {
      await customStatement(
        'DELETE FROM ${table.actualTableName} WHERE shop_id = ?',
        [shopId],
      );
    }
    await (delete(recentItemTable)..where((t) => t.shopId.equals(shopId))).go();
    await (delete(shopSyncCursors)..where((t) => t.shopId.equals(shopId))).go();
    await (delete(outboxEntries)..where(
      (t) =>
          t.entityType.equalsValue(SyncEntityType.shopSettings) &
              t.localId.equals(shopId) |
          t.entityType.equalsValue(SyncEntityType.item) &
              t.localId.isIn(itemIds) |
          t.entityType.equalsValue(SyncEntityType.itemCategory) &
              t.localId.isIn(categoryIds) |
          t.entityType.equalsValue(SyncEntityType.credit) &
              t.localId.isIn(creditIds) |
          t.entityType.equalsValue(SyncEntityType.creditCustomer) &
              t.localId.isIn(customerIds),
    )).go();
  });

  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(bankNotifications).go();
      await delete(shopItems).go();
      await delete(loaners).go();
      await delete(categories).go();
      await delete(customers).go();
      for (final table in _redesignTableList) {
        await delete(table).go();
      }
      await delete(recentItemTable).go();
      // Or the next account to sign in would skip its first pull.
      await delete(syncCursors).go();
      await delete(shopSyncCursors).go();
    });
  }
}
