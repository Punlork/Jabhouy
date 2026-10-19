import 'package:bloc/bloc.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_shop/src/data/item_repository.dart';
import 'package:jabhouy_shop/src/models/item.dart';

/// The Prices & currency screen: the Shop's [PriceSettings], which only
/// the owner may change. Each change saves at once.
class PriceSettingsCubit extends Cubit<PriceSettings?> {
  PriceSettingsCubit(this._repository, ShopScope scope)
    : canEdit = scope.role == MemberRole.owner,
      super(null);

  final ItemRepository _repository;

  /// Owner only; everyone else sees the settings read-only.
  final bool canEdit;

  Future<void> load() async => emit(await _repository.priceSettings());

  Future<void> save(PriceSettings next) async {
    if (!canEdit) return;
    if (await _repository.savePriceSettings(next) case Ok(:final value)) {
      emit(value);
    }
  }
}
