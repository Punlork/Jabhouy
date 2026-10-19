import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// A money field with a `៛` / `$` toggle button and a muted converted
/// hint below.
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
          keyboardType: TextInputType.numberWithOptions(
            decimal: _currency == Currency.usd,
          ),
          inputFormatters: [
            if (_currency == Currency.khr)
              _GroupedDigitsFormatter()
            else
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: AppTextTheme.body.copyWith(color: t.textPrimary),
          decoration: InputDecoration(
            errorText: widget.errorText,
            // One compact toggle leaves the narrow price column room to
            // type; two buttons took most of it.
            suffixIcon: _CurrencyToggle(
              label: _currency == Currency.khr ? '៛' : r'$',
              onTap: () => _switchTo(other),
            ),
          ),
        ),
        if (_money != null) ...[
          const SizedBox(height: AppSizes.fieldGap),
          Text(
            _money!
                .convertTo(other, khrPerUsd: widget.khrPerUsd)
                .formatApprox(),
            style: AppTextTheme.hint.copyWith(color: t.textMuted),
          ),
        ],
      ],
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: context.l10n.currencySwitch,
      // 44 × 44 tap target around a 36 px bordered button (canvas ៤ខ).
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.minTapTarget / 2,
        child: SizedBox.square(
          dimension: AppSizes.minTapTarget,
          child: Center(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 36),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: t.bg,
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                label,
                style: AppTextTheme.label.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
