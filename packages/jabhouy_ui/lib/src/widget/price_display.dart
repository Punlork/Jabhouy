import 'package:flutter/material.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// A price in the currency it was entered in, with an optional muted
/// converted line. A missing price reads `មិនទាន់មានតម្លៃ`, never `0 ៛`.
class PriceDisplay extends StatelessWidget {
  const PriceDisplay({
    required this.price,
    required this.khrPerUsd,
    required this.showConverted,
    this.style,
    super.key,
  });

  final Money? price;
  final int khrPerUsd;
  final bool showConverted;

  /// Defaults to the list price style (17 / 700).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final price = this.price;
    if (price == null) {
      return Text(
        context.l10n.priceMissing,
        style: AppTextTheme.label.copyWith(color: t.warningText),
      );
    }
    final other = price.currency == Currency.khr ? Currency.usd : Currency.khr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price.format(),
          style: (style ?? AppTextTheme.price).copyWith(color: t.textPrimary),
        ),
        if (showConverted)
          Text(
            price.convertTo(other, khrPerUsd: khrPerUsd).formatApprox(),
            style: AppTextTheme.hint.copyWith(color: t.textMuted),
          ),
      ],
    );
  }
}
