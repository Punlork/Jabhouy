import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

void main() {
  const named = {
    'headline': AppTextTheme.headline,
    'title': AppTextTheme.title,
    'body': AppTextTheme.body,
    'caption': AppTextTheme.caption,
    'pageTitle': AppTextTheme.pageTitle,
    'sectionTitle': AppTextTheme.sectionTitle,
    'label': AppTextTheme.label,
    'hint': AppTextTheme.hint,
    'price': AppTextTheme.price,
    'amount': AppTextTheme.amount,
  };

  for (final MapEntry(key: name, value: style) in named.entries) {
    test('$name uses Kantumruy Pro at line height 1.5', () {
      expect(style.fontFamily, 'KantumruyPro');
      expect(style.height, 1.5);
    });
  }

  test('body and input text is at least 16', () {
    expect(AppTextTheme.body.fontSize, greaterThanOrEqualTo(16));
    final theme = AppTheme.lightTheme;
    expect(theme.textTheme.bodyLarge!.fontSize, greaterThanOrEqualTo(16));
    expect(theme.textTheme.titleMedium!.fontSize, greaterThanOrEqualTo(16));
  });

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    test('${theme.brightness.name} theme sets the font on every text slot', () {
      final t = theme.textTheme;
      for (final style in [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall,
      ]) {
        expect(style!.fontFamily, 'KantumruyPro');
        expect(style.height, 1.5);
      }
    });
  }
}
