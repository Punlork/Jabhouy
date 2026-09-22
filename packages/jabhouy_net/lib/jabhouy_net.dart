/// Everything Jabhouy uses to reach a server.
///
/// It depends on `jabhouy_ui` and not the other way round: `ApiService`
/// shows a snack bar and a loading overlay on failure. That is transport
/// choosing words, which the layering rules say belongs above it — a
/// compromise recorded rather than fixed, because the alternative is a
/// second port for one call site. No cycle either way: `jabhouy_ui`
/// imports nothing from here.
library jabhouy_net;

export 'src/api_result.dart';
export 'src/api_service.dart';
export 'src/base_service.dart';
export 'src/connectivity_service.dart';
export 'src/network_inspector_service.dart';
export 'src/upload_service.dart';
