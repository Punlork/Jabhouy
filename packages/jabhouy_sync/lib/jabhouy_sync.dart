/// The outbox-driven sync engine.
///
/// Pure Dart on purpose: the whole package must build and test without
/// Flutter, which `dart test` enforces because the plain VM has no dart:ui.
library jabhouy_sync;

export 'src/adapter_sync_transport.dart';
export 'src/backoff.dart';
export 'src/feature_pull_adapter.dart';
export 'src/feature_sync_adapter.dart';
export 'src/fetch_every_page.dart';
export 'src/sync_engine.dart';
export 'src/transport.dart';
