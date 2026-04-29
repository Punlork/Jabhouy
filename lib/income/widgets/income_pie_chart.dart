import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/l10n.dart';

class IncomePieChart extends StatefulWidget {
  const IncomePieChart({
    required this.summary,
    super.key,
  });

  final IncomeSummary summary;

  @override
  State<IncomePieChart> createState() => _IncomePieChartState();
}

class _IncomePieChartState extends State<IncomePieChart> {
  String? _selectedCurrency;

  @override
  void didUpdateWidget(covariant IncomePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currencies = _availableCurrencies;
    if (currencies.isEmpty) {
      _selectedCurrency = null;
      return;
    }

    if (_selectedCurrency == null || !currencies.contains(_selectedCurrency)) {
      _selectedCurrency = currencies.first;
    }
  }

  List<String> get _availableCurrencies {
    final currencies = widget.summary.incomeByBankByCurrency.keys.toList()..sort(_compareCurrencies);
    return currencies;
  }

  _CurrencyChartSection? get _selectedSection {
    final currencies = _availableCurrencies;
    if (currencies.isEmpty) {
      return null;
    }

    final currency =
        _selectedCurrency != null && currencies.contains(_selectedCurrency) ? _selectedCurrency! : currencies.first;
    _selectedCurrency = currency;

    final summary = widget.summary;
    final colorScheme = Theme.of(context).colorScheme;
    final bankTotals = summary.incomeByBankByCurrency[currency] ?? const {};

    return _CurrencyChartSection(
      currency: currency,
      total: summary.totalIncomeByCurrency[currency] ?? 0,
      segments: bankTotals.entries
          .where((bankEntry) => bankEntry.value > 0)
          .map(
            (bankEntry) => _ChartSegment(
              label: bankEntry.key.label,
              branding: resolveBankBranding(bankEntry.key, colorScheme),
              value: bankEntry.value,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencySection = _selectedSection;
    final currencies = _availableCurrencies;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.incomeByBank,
                style: AppTextTheme.title.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (currencies.length > 1) ...[
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currencies
                      .map(
                        (currency) => ChoiceChip(
                          label: Text(currency),
                          selected: currency == _selectedCurrency,
                          onSelected: (_) {
                            setState(() {
                              _selectedCurrency = currency;
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (currencySection == null)
            Text(
              context.l10n.noIncomeChartData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else
            _CurrencyPieChartSection(
              section: currencySection,
            ),
        ],
      ),
    );
  }

  int _compareCurrencies(String left, String right) {
    const preferredOrder = ['USD', 'KHR'];
    final leftIndex = preferredOrder.indexOf(left);
    final rightIndex = preferredOrder.indexOf(right);

    if (leftIndex == -1 && rightIndex == -1) {
      return left.compareTo(right);
    }
    if (leftIndex == -1) {
      return 1;
    }
    if (rightIndex == -1) {
      return -1;
    }
    return leftIndex.compareTo(rightIndex);
  }
}

class _CurrencyChartSection {
  const _CurrencyChartSection({
    required this.currency,
    required this.total,
    required this.segments,
  });

  final String currency;
  final double total;
  final List<_ChartSegment> segments;
}

class _CurrencyPieChartSection extends StatelessWidget {
  const _CurrencyPieChartSection({
    required this.section,
  });

  final _CurrencyChartSection section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: _IncomePieChartPainter(
                  segments: section.segments,
                  emptyColor: colorScheme.secondaryContainer,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${context.l10n.totalIncome} • ${section.currency}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 110,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            BankNotificationModel.formatAmount(
                              amount: section.total,
                              currency: section.currency,
                            ),
                            maxLines: 1,
                            style: AppTextTheme.title.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: section.segments.isEmpty
                ? Text(
                    context.l10n.noIncomeChartData,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(section.segments.length, (index) {
                      final segment = section.segments[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == section.segments.length - 1 ? 0 : 10),
                        child: Row(
                          children: [
                            BankLogoBadge(
                              branding: segment.branding,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                segment.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 84, maxWidth: 120),
                              child: Text(
                                BankNotificationModel.formatAmount(
                                  amount: segment.value,
                                  currency: section.currency,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartSegment {
  const _ChartSegment({
    required this.label,
    required this.branding,
    required this.value,
  });

  final String label;
  final BankBranding branding;
  final double value;
}

class _IncomePieChartPainter extends CustomPainter {
  const _IncomePieChartPainter({
    required this.segments,
    required this.emptyColor,
  });

  final List<_ChartSegment> segments;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final strokeWidth = (shortestSide * 0.10).clamp(8.0, 16.0);
    final center = Offset(size.width / 2, size.height / 2);
    final squareRect = Rect.fromCenter(
      center: center,
      width: shortestSide,
      height: shortestSide,
    );
    final arcRect = squareRect.deflate(strokeWidth / 2);
    final total = segments.fold<double>(0, (sum, segment) => sum + segment.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (total <= 0) {
      paint.color = emptyColor;
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        math.pi * 2,
        false,
        paint,
      );
      return;
    }

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * math.pi * 2;
      paint.color = segment.branding.primary;
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_IncomePieChartPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.emptyColor != emptyColor;
  }
}
