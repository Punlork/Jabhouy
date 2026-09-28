import 'package:jabhouy/income/models/bank_notification_model.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_net/jabhouy_net.dart';

/// Every HTTP call the income feature makes, and nothing else.
///
/// Income has two transports: this one pulls the server's list, and
/// Firebase pushes new notifications up. Only the pull is HTTP.
class IncomeApi extends BaseService {
  IncomeApi(super.apiService);

  @override
  String get basePath => '/notifications';

  Future<Result<List<BankNotificationModel>>> fetchNotifications() async {
    final response = await get<List<BankNotificationModel>>(
      '',
      showSnackBar: false,
      parser: parseNotifications,
    );
    return response.toResult();
  }

  /// The server has shipped four shapes for this list over time, so the
  /// parser accepts all of them rather than guessing one.
  static List<BankNotificationModel> parseNotifications(dynamic payload) {
    dynamic data = payload;

    if (data is Map<String, dynamic>) {
      data = data['data'] ??
          data['notifications'] ??
          data['items'] ??
          data['results'];
    }

    if (data is! List) return const [];

    return data
        .map((entry) {
          final map = switch (entry) {
            final Map<String, dynamic> m => m,
            final Map<Object?, Object?> m =>
              Map<String, dynamic>.from(m),
            _ => null,
          };
          if (map == null) return null;
          return BankNotificationModel.fromNativeMap(
            BankNotificationModel.fromJSON(map),
          );
        })
        .whereType<BankNotificationModel>()
        .toList(growable: false);
  }
}
