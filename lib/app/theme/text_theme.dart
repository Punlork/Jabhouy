import 'package:flutter/material.dart';

class AppTextTheme {
  static const TextStyle headline = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'NotoSansKhmer',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static TextTheme get textTheme => const TextTheme(
        displayLarge: headline,
        headlineMedium: title,
        bodyLarge: body,
        bodySmall: caption,
      );
}
