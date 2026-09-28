import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens the on-device database file.
///
/// This is the half of the database that needs Flutter, so it stays in the
/// app while the schema lives in `jabhouy_core`. Pass the result to
/// `AppDatabase`.
LazyDatabase openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    final cacheDatabase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cacheDatabase.path;

    return NativeDatabase.createInBackground(file);
  });
}
