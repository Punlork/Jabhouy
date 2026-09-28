/// The shop feature, as a package.
///
/// One feature was promoted deliberately, to find out what a package
/// boundary costs and what it buys. What it cost is recorded in
/// docs/ARCHITECTURE_RESTRUCTURE.md; what it buys is that nothing here
/// can reach the app, and the analyzer says so rather than a reviewer.
library jabhouy_shop;

export 'src/data/api/category_api.dart';
export 'src/data/api/shop_api.dart';
export 'src/data/category_repository.dart';
export 'src/data/category_repository_impl.dart';
export 'src/data/category_sync_adapter.dart';
export 'src/data/db/category_dao.dart';
export 'src/data/db/shop_dao.dart';
export 'src/data/shop_repository.dart';
export 'src/data/shop_repository_impl.dart';
export 'src/data/shop_sync_adapter.dart';
export 'src/models/category_model.dart';
export 'src/models/shop_item_model.dart';
export 'src/ui/bloc/category/category_bloc.dart';
export 'src/ui/bloc/shop_bloc.dart';
export 'src/ui/views/category_page.dart';
export 'src/ui/views/shop_item_form_controller.dart';
export 'src/ui/views/shop_item_form_page.dart';
export 'src/ui/widgets/category_chip.dart';
export 'src/ui/widgets/category_selection_dropdown.dart';
export 'src/ui/widgets/filter_card_sheet.dart';
export 'src/ui/widgets/shop_grid_builder.dart';
export 'src/ui/widgets/shop_header.dart';
export 'src/ui/widgets/shop_item_card.dart';
export 'src/ui/widgets/shop_item_detail_sheet.dart';
export 'src/ui/widgets/shop_item_grid_card.dart';
export 'src/ui/widgets/shop_item_image_section.dart';
export 'src/ui/widgets/shop_item_variant_builder.dart';
export 'src/ui/widgets/shop_tab.dart';
