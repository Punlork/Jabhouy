/// Jabhouy's translations, and the `context.l10n` shorthand.
///
/// The ARB files lived under `lib/l10n/` in the app package, which meant
/// no package could put a translated word on screen. That is what a
/// feature package has to do on almost every line, so the catalog moves
/// out ahead of the features that need it.
library jabhouy_l10n;

export 'src/arb/app_localizations.dart';
export 'src/context_extension.dart';
