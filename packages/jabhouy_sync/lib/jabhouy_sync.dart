/// The outbox-driven sync engine.
///
/// Pure Dart on purpose: the whole package must build and test without
/// Flutter, which `dart test` enforces because the plain VM has no dart:ui.
library jabhouy_sync;

export 'src/backoff.dart';
export 'src/sync_engine.dart';
export 'src/transport.dart';
