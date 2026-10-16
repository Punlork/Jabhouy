import 'package:flutter/material.dart';

/// The redesign's color tokens (plan §1). Screens read colors from here,
/// through [AppTokensContext.tokens], never from hex literals.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSubtle,
    required this.border,
    required this.divider,
    required this.dividerStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.placeholder,
    required this.scrim,
    required this.warningBg,
    required this.warningText,
    required this.successBg,
    required this.successText,
    required this.dangerText,
    required this.dangerBorder,
    required this.onPrimary,
  });

  static const light = AppTokens(
    bg: Color(0xFFF4F4F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE8E8E5),
    surfaceSubtle: Color(0xFFEDEDEA),
    border: Color(0xFFD6D6D3),
    divider: Color(0xFFEEEEEB),
    dividerStrong: Color(0xFFE2E2DF),
    textPrimary: Color(0xFF1F1F1F),
    textSecondary: Color(0xFF3A3A3A),
    textMuted: Color(0xFF5C5C5C),
    placeholder: Color(0xFF686866),
    scrim: Color(0x73000000),
    warningBg: Color(0xFFFCEFD8),
    warningText: Color(0xFF6B4200),
    successBg: Color(0xFFE2F0E4),
    successText: Color(0xFF1E5B2A),
    dangerText: Color(0xFFA12626),
    dangerBorder: Color(0xFFE4B4B4),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const dark = AppTokens(
    bg: Color(0xFF121212),
    surface: Color(0xFF1C1C1C),
    surfaceMuted: Color(0xFF2A2A2A),
    surfaceSubtle: Color(0xFF242424),
    border: Color(0xFF3A3A3A),
    divider: Color(0xFF262626),
    dividerStrong: Color(0xFF303030),
    textPrimary: Color(0xFFEDEDEA),
    textSecondary: Color(0xFFD0D0CC),
    textMuted: Color(0xFFA3A3A0),
    placeholder: Color(0xFF959592),
    scrim: Color(0x99000000),
    warningBg: Color(0xFF3D2E10),
    warningText: Color(0xFFF5C977),
    successBg: Color(0xFF1A3320),
    successText: Color(0xFF9AD3A5),
    dangerText: Color(0xFFF09090),
    dangerBorder: Color(0xFF6B2C2C),
    onPrimary: Color(0xFF1F1F1F),
  );

  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceSubtle;
  final Color border;
  final Color divider;
  final Color dividerStrong;

  /// Also the fill of primary buttons and active chips.
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color placeholder;
  final Color scrim;
  final Color warningBg;
  final Color warningText;
  final Color successBg;
  final Color successText;
  final Color dangerText;
  final Color dangerBorder;
  final Color onPrimary;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceSubtle: l(surfaceSubtle, other.surfaceSubtle),
      border: l(border, other.border),
      divider: l(divider, other.divider),
      dividerStrong: l(dividerStrong, other.dividerStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      placeholder: l(placeholder, other.placeholder),
      scrim: l(scrim, other.scrim),
      warningBg: l(warningBg, other.warningBg),
      warningText: l(warningText, other.warningText),
      successBg: l(successBg, other.successBg),
      successText: l(successText, other.successText),
      dangerText: l(dangerText, other.dangerText),
      dangerBorder: l(dangerBorder, other.dangerBorder),
      onPrimary: l(onPrimary, other.onPrimary),
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

/// Shape and spacing from plan §1.
abstract final class AppSizes {
  static const radiusInput = 12.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 24.0;
  static const radiusChip = 20.0;

  static const inputHeight = 50.0;
  static const buttonHeight = 54.0;
  static const chipHeight = 40.0;
  static const minTapTarget = 44.0;

  static const screenPadding = 16.0;
  static const sectionGap = 24.0;
  static const fieldGap = 6.0;
}
