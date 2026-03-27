import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

class Customers extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer()
      .withDefault(const Constant(0))(); // 0: synced, 1: pending, 2: error

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

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
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

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
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Customers, Categories, ShopItems, Loaners])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Add columns to Customers
          await m.addColumn(customers, customers.isDeleted);
          await m.addColumn(customers, customers.syncStatus);

          // Add columns to Categories
          await m.addColumn(categories, categories.isDeleted);
          await m.addColumn(categories, categories.syncStatus);

          // Add columns to ShopItems
          await m.addColumn(shopItems, shopItems.isDeleted);
          await m.addColumn(shopItems, shopItems.syncStatus);

          // Add columns to Loaners
          await m.addColumn(loaners, loaners.isDeleted);
          await m.addColumn(loaners, loaners.syncStatus);
        }

        if (from < 3) {
          await m.addColumn(loaners, loaners.customer);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    // if (Platform.isAndroid) {
    //   await applyWorkaroundToOpenSqlite3OnOldAndroidDevices();
    // }

    final cacheDatabase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cacheDatabase.path;

    return NativeDatabase.createInBackground(file);
  });
}
