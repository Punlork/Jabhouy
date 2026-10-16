import 'package:flutter/material.dart';

/// Text styles from plan §1. Kantumruy Pro with Noto Sans Khmer as fallback;
/// line height 1.5 everywhere so stacked Khmer vowels and subscripts fit.
class AppTextTheme {
  static const _family = 'KantumruyPro';
  static const _fallback = ['NotoSansKhmer'];

  // Older names, still used across the current screens.
  static const TextStyle headline = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Redesign styles.
  static const TextStyle pageTitle = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle hint = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle price = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );
  static const TextStyle amount = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  static TextTheme get textTheme => TextTheme(
        displayLarge: amount,
        displayMedium: amount.copyWith(fontSize: 26),
        displaySmall: headline,
        headlineLarge: headline,
        headlineMedium: title,
        headlineSmall: pageTitle,
        titleLarge: pageTitle,
        titleMedium: sectionTitle.copyWith(fontWeight: FontWeight.w600),
        titleSmall: label,
        bodyLarge: body,
        bodyMedium: body.copyWith(fontSize: 15),
        bodySmall: caption,
        labelLarge: label,
        labelMedium: hint,
        labelSmall: hint.copyWith(fontSize: 13),
      );
}
