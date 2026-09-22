import 'package:flutter/foundation.dart';
import 'package:jabhouy/l10n/arb/app_localizations.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Satisfies `jabhouy_ui`'s [UiStrings] port from the app's ARB files.
///
/// The package declares the four labels its widgets show; translating them
/// stays here, where the generated `AppLocalizations` lives.
@immutable
class AppUiStrings implements UiStrings {
  const AppUiStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get loading => _l10n.loading;

  @override
  String get noItemFound => _l10n.noItemFound;

  @override
  String get cancel => _l10n.cancel;

  @override
  String get imgFound => _l10n.imgFound;

  @override
  String get selectImageSource => _l10n.selectImageSource;

  @override
  String get takePhoto => _l10n.takePhoto;

  @override
  String get chooseFromGallery => _l10n.chooseFromGallery;

  @override
  bool operator ==(Object other) =>
      other is AppUiStrings && other._l10n == _l10n;

  @override
  int get hashCode => _l10n.hashCode;
}
