import 'package:drift/drift.dart';
import 'package:flutter_runtime_debugger/flutter_runtime_debugger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exposes the Drift database to the debug overlay's Storage tab.
///
/// The overlay discovers tables itself through `sqlite_master`, so this only
/// needs to forward raw SQL.
class DriftStorageReader implements SqlStorageReader {
  const DriftStorageReader(this._db);

  final DatabaseConnectionUser _db;

  @override
  String get name => 'Drift';

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    final rows = await _db
        .customSelect(
          sql,
          variables: args.map((a) => Variable<Object>(a)).toList(),
        )
        .get();
    return rows.map((row) => row.data).toList();
  }
}

/// Exposes SharedPreferences (session cache, cookies, app settings) to the
/// debug overlay's Storage tab.
class SharedPreferencesStorageReader implements KeyValueStorageReader {
  const SharedPreferencesStorageReader();

  @override
  String get name => 'SharedPreferences';

  @override
  Future<Map<String, dynamic>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {for (final key in prefs.getKeys()) key: prefs.get(key)};
  }
}
