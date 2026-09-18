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

@DriftDatabase(
  tables: [
    Customers,
    Categories,
    ShopItems,
    Loaners,
    BankNotifications,
    OutboxEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Takes its executor rather than opening one, so this package stays
  /// free of `dart:io`, path_provider and sqlite3_flutter_libs. The app
  /// passes a file-backed executor; tests pass `NativeDatabase.memory()`.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 6;

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
      },
    );
  }

  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(bankNotifications).go();
      await delete(shopItems).go();
      await delete(loaners).go();
      await delete(categories).go();
      await delete(customers).go();
    });
  }
}
