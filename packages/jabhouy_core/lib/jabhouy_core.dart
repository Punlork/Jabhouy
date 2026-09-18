/// Shared primitives and the Drift schema for Jabhouy.
///
/// This package has no Flutter dependency: it must keep building under
/// `dart test`. Opening a real database file is the app's job: the
/// AppDatabase constructor takes an executor rather than creating one.
library jabhouy_core;

export 'package:drift/drift.dart' show Value;

export 'src/database/app_database.dart';
