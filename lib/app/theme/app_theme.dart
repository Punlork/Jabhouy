import 'package:flutter/material.dart';
import 'package:my_app/app/theme/color_theme.dart';
import 'package:my_app/app/theme/text_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark
          ? AppColorTheme.brandDark
          : AppColorTheme.brand,
      brightness: brightness,
    );
    final colorScheme = _buildColorScheme(baseScheme, brightness);
    final textTheme = AppTextTheme.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
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
        color: brightness == Brightness.dark
            ? colorScheme.surfaceContainerLow
            : Colors.white,
        elevation: brightness == Brightness.dark ? 0 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
    ColorScheme baseScheme,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return baseScheme.copyWith(
      primary: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF2F2F2F),
      onPrimary: isDark ? const Color(0xFF171717) : Colors.white,
      primaryContainer:
          isDark ? const Color(0xFF2A2A2A) : const Color(0xFF4C4C4C),
      onPrimaryContainer: Colors.white,
      secondary: isDark ? const Color(0xFFCACACA) : const Color(0xFF5F5F5F),
      onSecondary: isDark ? const Color(0xFF171717) : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF242424) : const Color(0xFFEAEAEA),
      onSecondaryContainer:
          isDark ? const Color(0xFFF3F3F3) : const Color(0xFF1A1A1A),
      tertiary: isDark ? const Color(0xFFBEBEBE) : const Color(0xFF757575),
      onTertiary: isDark ? const Color(0xFF171717) : Colors.white,
      tertiaryContainer:
          isDark ? const Color(0xFF2B2B2B) : const Color(0xFFF0F0F0),
      onTertiaryContainer:
          isDark ? const Color(0xFFF3F3F3) : const Color(0xFF1A1A1A),
      error: AppColorTheme.error,
      onError: Colors.white,
      surface: isDark ? const Color(0xFF181818) : const Color(0xFFF4F4F4),
      onSurface: isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1D1D1D),
      onSurfaceVariant:
          isDark ? const Color(0xFFB8B8B8) : const Color(0xFF6B6B6B),
      outline: isDark ? const Color(0xFF464646) : const Color(0xFFD0D0D0),
      outlineVariant:
          isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE7E7E7),
      inverseSurface:
          isDark ? const Color(0xFFF2F2F2) : const Color(0xFF242424),
      onInverseSurface:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9),
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }
}
