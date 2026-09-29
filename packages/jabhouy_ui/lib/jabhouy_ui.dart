/// Shared presentation for Jabhouy: theme, assets, widgets and mixins.
///
/// This package must not import the app package or any feature. What it
/// needs from them arrives as a port — see `ImageUploader`. That rule is what
/// lets a feature become a package: the app's barrel exports the router,
/// the router imports every feature, so any widget reached through the
/// app barrel drags the whole feature graph behind it.
library jabhouy_ui;

export 'src/constant/app_assets.dart';
export 'src/context/global_context.dart';
export 'src/mixin/infinite_scroll_mixin.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/color_theme.dart';
export 'src/theme/text_theme.dart';
export 'src/upload/image_uploader.dart';
export 'src/upload/upload_bloc.dart';
export 'src/utils/overlay_loading.dart';
export 'src/utils/snack_bar.dart';
export 'src/widget/app_bottom_sheet.dart';
export 'src/widget/app_logo.dart';
export 'src/widget/custom_loading.dart';
export 'src/widget/custom_outline_border.dart';
export 'src/widget/custom_text_form_field.dart';
export 'src/widget/empty_view.dart';
export 'src/widget/icon_button.dart';
export 'src/widget/infinite_end_widget.dart';
export 'src/widget/sync_state_icon.dart';
export 'src/widget/tab_scroll_manager.dart';
