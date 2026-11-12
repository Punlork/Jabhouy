import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/bloc/price_settings/price_settings_cubit.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Prices & currency (canvas ១២ក): which prices the Shop uses, the default
/// currency, the exchange rate and the converted line. Expects a
/// [PriceSettingsCubit] above it.
class PriceSettingsPage extends StatefulWidget {
  const PriceSettingsPage({super.key});

  static const rateKey = Key('price-settings-rate');

  @override
  State<PriceSettingsPage> createState() => _PriceSettingsPageState();
}

class _PriceSettingsPageState extends State<PriceSettingsPage> {
  final _rate = TextEditingController();
  String? _rateError;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  /// A new rate changes every converted price, so it asks first.
  Future<void> _submitRate(PriceSettings settings) async {
    final l10n = context.l10n;
    final rate = Money.tryParse(_rate.text, Currency.khr)?.amount ?? 0;
    if (rate <= 0) {
      setState(() => _rateError = l10n.settingsRateInvalid);
      return;
    }
    setState(() => _rateError = null);
    if (rate == settings.khrPerUsd) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.settingsRateFormat(Money(rate, Currency.khr).formatNumber()),
        ),
        content: Text(l10n.settingsRateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed ?? false) {
      await context.read<PriceSettingsCubit>().save(
        settings.copyWith(khrPerUsd: rate),
      );
    } else {
      _rate.text = Money(settings.khrPerUsd, Currency.khr).formatNumber();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final cubit = context.read<PriceSettingsCubit>();
    final canEdit = cubit.canEdit;

    return BlocConsumer<PriceSettingsCubit, PriceSettings?>(
      listenWhen: (a, b) => a?.khrPerUsd != b?.khrPerUsd,
      listener: (context, s) {
        if (s != null) {
          _rate.text = Money(s.khrPerUsd, Currency.khr).formatNumber();
        }
      },
      builder: (context, settings) {
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            centerTitle: false,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(l10n.settingsPricesCurrency),
          ),
          body: settings == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (!canEdit) ...[
                      Text(
                        l10n.settingsOwnerOnly,
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _Heading(l10n.settingsPricesUsed),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        l10n.settingsPricesUsedHint,
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                    ),
                    _Card(
                      children: [
                        _CheckRow(
                          title: l10n.priceSelling,
                          subtitle: l10n.settingsAlwaysOn,
                          value: true,
                        ),
                        _CheckRow(
                          title: l10n.priceWholesale,
                          subtitle: l10n.settingsWholesaleHint,
                          value: settings.useWholesale,
                          onChanged: canEdit
                              ? (v) => cubit.save(
                                  settings.copyWith(useWholesale: v),
                                )
                              : null,
                        ),
                        _CheckRow(
                          title: l10n.priceCost,
                          value: settings.useCost,
                          onChanged: canEdit
                              ? (v) => cubit.save(settings.copyWith(useCost: v))
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sectionGap),
                    _Heading(l10n.settingsCurrency),
                    _Card(
                      padding: const EdgeInsets.all(16),
                      children: [
                        LabeledField(
                          label: l10n.settingsDefaultCurrency,
                          child: IgnorePointer(
                            ignoring: !canEdit,
                            child: SegmentedControl<Currency>(
                              options: [
                                (Currency.khr, '៛ ${l10n.currencyKhr}'),
                                (Currency.usd, '\$ ${l10n.currencyUsd}'),
                              ],
                              selected: settings.currency,
                              onChanged: (c) =>
                                  cubit.save(settings.copyWith(currency: c)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: l10n.settingsRate,
                          hint: [
                            if (settings.rateUpdatedAt case final at?)
                              l10n.lastEditedOn(
                                l10n.formatDate(at.toPhnomPenh()),
                              ),
                            l10n.settingsRateKeepsOld,
                          ].join(' · '),
                          child: TextField(
                            key: PriceSettingsPage.rateKey,
                            controller: _rate,
                            enabled: canEdit,
                            keyboardType: moneyKeyboard(Currency.khr),
                            inputFormatters: moneyFormatters(Currency.khr),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitRate(settings),
                            style: AppTextTheme.body.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              prefixText: r'$1 = ',
                              suffixText: '៛',
                              errorText: _rateError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      children: [
                        _CheckRow(
                          title: l10n.settingsShowConverted,
                          subtitle: _example(settings),
                          value: settings.showConverted,
                          onChanged: canEdit
                              ? (v) => cubit.save(
                                  settings.copyWith(showConverted: v),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// `ឧ. 3,000 ៛ · ≈ $0.75` at the current rate.
  String _example(PriceSettings s) {
    const price = Money(3000, Currency.khr);
    final usd = price.convertTo(Currency.usd, khrPerUsd: s.khrPerUsd);
    return 'ឧ. ${price.format()} · ${usd.formatApprox()}';
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: AppTextTheme.sectionTitle.copyWith(
        color: context.tokens.textPrimary,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.tokens.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// A tick-box row; null [onChanged] shows it fixed (selling, or read-only).
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? (enabled ? t.textPrimary : t.textMuted) : null,
                  border: value ? null : Border.all(color: t.border, width: 2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: value
                    ? Icon(Icons.check_rounded, size: 18, color: t.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextTheme.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
