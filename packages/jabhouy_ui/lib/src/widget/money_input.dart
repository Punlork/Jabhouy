import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// A money field with a `៛ | $` switch and a muted converted hint below.
/// Reports null while empty or unreadable, so a missing price is never 0.
///
/// shortcut: [value] is read once; give the widget a new key to reset it
/// from outside.
class MoneyInput extends StatefulWidget {
  const MoneyInput({
    required this.currency,
    required this.khrPerUsd,
    this.onChanged,
    this.onText,
    this.errorText,
    this.hasError = false,
    this.hintText,
    this.value,
    super.key,
  });

  final Money? value;

  /// Starting currency when [value] is null, usually the shop default.
  final Currency currency;

  /// Rate for the hint and the toggle: the shop's, or a credit's snapshot.
  final int khrPerUsd;
  final ValueChanged<Money?>? onChanged;

  /// The text as typed and the chosen currency, so a form can name a typo
  /// that [onChanged] reports as null.
  final void Function(String text, Currency currency)? onText;
  final String? errorText;

  /// A red border with no text, for a form that shows the message itself.
  final bool hasError;
  final String? hintText;

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late Currency _currency = widget.value?.currency ?? widget.currency;
  late final _controller = TextEditingController(
    text: widget.value?.formatNumber() ?? '',
  );
  Money? _money;

  @override
  void initState() {
    super.initState();
    _money = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onText(String text) {
    setState(() => _money = Money.tryParse(text, _currency));
    widget.onChanged?.call(_money);
    widget.onText?.call(text, _currency);
  }

  void _switchTo(Currency to) {
    if (to == _currency) return;
    final converted = _money?.convertTo(to, khrPerUsd: widget.khrPerUsd);
    setState(() {
      _currency = to;
      _money = converted;
      _controller.text = converted?.formatNumber() ?? '';
    });
    widget.onChanged?.call(converted);
    widget.onText?.call(_controller.text, to);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final other = _currency == Currency.khr ? Currency.usd : Currency.khr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onText,
          keyboardType: moneyKeyboard(_currency),
          inputFormatters: moneyFormatters(_currency),
          style: AppTextTheme.body.copyWith(color: t.textPrimary),
          decoration: InputDecoration(
            errorText: widget.errorText,
            error: widget.errorText == null && widget.hasError
                ? const SizedBox()
                : null,
            hintText: widget.hintText,
            suffixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: _CurrencySegments(
                selected: _currency,
                onSelect: _switchTo,
              ),
            ),
          ),
        ),
        if (_money != null) ...[
          const SizedBox(height: AppSizes.fieldGap),
          Text(
            _money!
                .convertTo(other, khrPerUsd: widget.khrPerUsd)
                .formatApprox(),
            textAlign: TextAlign.end,
            style: AppTextTheme.hint.copyWith(color: t.textMuted),
          ),
        ],
      ],
    );
  }
}

/// `៛ $` side by side; the chosen one is a dark square.
class _CurrencySegments extends StatelessWidget {
  const _CurrencySegments({required this.selected, required this.onSelect});

  final Currency selected;
  final ValueChanged<Currency> onSelect;

  @override
  Widget build(BuildContext context) {
    final symbol = selected == Currency.khr ? '៛' : r'$';
    final other = selected == Currency.khr ? Currency.usd : Currency.khr;
    // One node for screen readers: inner per-symbol nodes got clipped into
    // invisible ones while the row scrolled. Sighted taps still hit each
    // symbol; a screen reader's tap flips the currency.
    return Semantics(
      button: true,
      label: '${context.l10n.currencySwitch} $symbol',
      onTap: () => onSelect(other),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (currency, symbol) in [
            (Currency.khr, '៛'),
            (Currency.usd, r'$'),
          ])
            _Segment(
              symbol: symbol,
              selected: currency == selected,
              onTap: () => onSelect(currency),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // A 36 px square to see, a 44 px square to tap.
      child: SizedBox.square(
        dimension: AppSizes.minTapTarget,
        child: Center(
          child: Container(
            width: 36,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? t.textPrimary : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              symbol,
              // Kantumruy draws ៛ small; it needs a larger size to read.
              style: TextStyle(
                fontSize: symbol == '៛' ? 22 : 17,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: selected ? t.onPrimary : t.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The keyboard for typing an amount in [currency].
TextInputType moneyKeyboard(Currency currency) =>
    TextInputType.numberWithOptions(decimal: currency == Currency.usd);

/// What a money field accepts: riel digits grouped by thousands, or
/// dollars with up to two decimals. Shared by every amount field.
List<TextInputFormatter> moneyFormatters(Currency currency) => [
  if (currency == Currency.khr)
    _GroupedDigitsFormatter()
  else
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
];

/// Keeps only digits and groups them by thousands while typing. A dot is
/// left as typed, so `3,000.5` reads as a mistake rather than 30,005.
class _GroupedDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.contains('.')) {
      final kept = newValue.text.replaceAll(RegExp(r'[^\d,.]'), '');
      return TextEditingValue(
        text: kept,
        selection: TextSelection.collapsed(offset: kept.length),
      );
    }
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    final text = Money(int.parse(digits), Currency.khr).formatNumber();
    // shortcut: cursor jumps to the end; fine for typing amounts left to right.
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
