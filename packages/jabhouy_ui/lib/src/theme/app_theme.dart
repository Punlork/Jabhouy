import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final tokens =
        brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;
    final colorScheme = _buildColorScheme(tokens, brightness);
    final textTheme = AppTextTheme.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [tokens],
      scaffoldBackgroundColor: tokens.bg,
      fontFamily: 'NotoSansKhmer',
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        // Cards and card-like containers (settings groups, income cards)
        // both use surfaceContainerLow, so every raised surface matches.
        color: colorScheme.surfaceContainerLow,
        elevation: brightness == Brightness.dark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: TextStyle(color: tokens.placeholder),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusInput),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusInput),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusInput),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
        ),
      ),
    );
  }

  static ColorScheme _buildColorScheme(
    AppTokens tokens,
    Brightness brightness,
  ) {
    return ColorScheme(
      brightness: brightness,
      primary: tokens.textPrimary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.surfaceSubtle,
      onPrimaryContainer: tokens.textPrimary,
      secondary: tokens.textSecondary,
      onSecondary: tokens.onPrimary,
      secondaryContainer: tokens.surfaceMuted,
      onSecondaryContainer: tokens.textPrimary,
      tertiary: tokens.textMuted,
      onTertiary: tokens.onPrimary,
      error: tokens.dangerText,
      onError: tokens.onPrimary,
      surface: tokens.bg,
      onSurface: tokens.textPrimary,
      surfaceContainerLowest: tokens.surface,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surfaceSubtle,
      surfaceContainerHigh: tokens.surfaceMuted,
      surfaceContainerHighest: tokens.surfaceMuted,
      onSurfaceVariant: tokens.textMuted,
      outline: tokens.border,
      outlineVariant: tokens.divider,
      inverseSurface: tokens.textPrimary,
      onInverseSurface: tokens.onPrimary,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: tokens.scrim,
    );
  }
}
