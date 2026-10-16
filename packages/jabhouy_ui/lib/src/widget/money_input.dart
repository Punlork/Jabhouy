import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';

/// A money field with a `៛ | $` toggle and a muted converted hint below.
/// Reports null while empty or unreadable, so a missing price is never 0.
///
/// shortcut: [value] is read once; give the widget a new key to reset it
/// from outside.
class MoneyInput extends StatefulWidget {
  const MoneyInput({
    required this.currency,
    required this.khrPerUsd,
    required this.onChanged,
    this.value,
    super.key,
  });

  final Money? value;

  /// Starting currency when [value] is null, usually the shop default.
  final Currency currency;

  /// Rate for the hint and the toggle: the shop's, or a credit's snapshot.
  final int khrPerUsd;
  final ValueChanged<Money?> onChanged;

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
    widget.onChanged(_money);
  }

  void _switchTo(Currency to) {
    if (to == _currency) return;
    final converted = _money?.convertTo(to, khrPerUsd: widget.khrPerUsd);
    setState(() {
      _currency = to;
      _money = converted;
      _controller.text = converted?.formatNumber() ?? '';
    });
    widget.onChanged(converted);
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
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CurrencyButton(
                  label: '៛',
                  selected: _currency == Currency.khr,
                  onTap: () => _switchTo(Currency.khr),
                ),
                _CurrencyButton(
                  label: r'$',
                  selected: _currency == Currency.usd,
                  onTap: () => _switchTo(Currency.usd),
                ),
              ],
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

class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.minTapTarget / 2,
        child: SizedBox.square(
          dimension: AppSizes.minTapTarget,
          child: Center(
            child: Text(
              label,
              style: AppTextTheme.label.copyWith(
                color: selected ? t.textPrimary : t.textMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps only digits and groups them by thousands while typing.
class _GroupedDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
