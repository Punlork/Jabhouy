import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final themes = {
    'light': (AppTheme.lightTheme, AppTokens.light),
    'dark': (AppTheme.darkTheme, AppTokens.dark),
  };

  for (final MapEntry(key: name, value: (theme, tokens)) in themes.entries) {
    group(name, () {
      test('registers its tokens and maps them onto the color scheme', () {
        expect(theme.extension<AppTokens>(), same(tokens));
        expect(theme.colorScheme.primary, tokens.textPrimary);
        expect(theme.colorScheme.onPrimary, tokens.onPrimary);
        expect(theme.scaffoldBackgroundColor, tokens.bg);
      });

      // WCAG AA for normal text.
      final pairs = {
        'textPrimary on bg': (tokens.textPrimary, tokens.bg),
        'textPrimary on surface': (tokens.textPrimary, tokens.surface),
        'textSecondary on surface': (tokens.textSecondary, tokens.surface),
        'textMuted on surface': (tokens.textMuted, tokens.surface),
        'textMuted on bg': (tokens.textMuted, tokens.bg),
        'placeholder on surfaceMuted': (
          tokens.placeholder,
          tokens.surfaceMuted,
        ),
        'warningText on warningBg': (tokens.warningText, tokens.warningBg),
        'successText on successBg': (tokens.successText, tokens.successBg),
        'dangerText on surface': (tokens.dangerText, tokens.surface),
        'onPrimary on textPrimary': (tokens.onPrimary, tokens.textPrimary),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test('$label meets 4.5:1', () {
          expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }
}
