import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/income/income.dart';
import 'package:my_app/l10n/l10n.dart';

class IncomePieChart extends StatelessWidget {
  const IncomePieChart({
    required this.summary,
    super.key,
  });

  final IncomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final segments = summary.incomeByBank.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => _ChartSegment(
            label: entry.key.label,
            branding: resolveBankBranding(entry.key, colorScheme),
            value: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

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
          Text(
            context.l10n.incomeByBank,
            style: AppTextTheme.title.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _IncomePieChartPainter(
                      segments: segments,
                      emptyColor: colorScheme.secondaryContainer,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.totalIncome,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            BankNotificationModel(
                              fingerprint: 'chart',
                              packageName: '',
                              bankApp: BankApp.unknown,
                              message: '',
                              amount: summary.totalIncome,
                              isIncome: true,
                              receivedAt: DateTime.now(),
                            ).amountLabel,
                            style: AppTextTheme.title.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: segments.isEmpty
                      ? Text(
                          context.l10n.noIncomeChartData,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: segments
                              .map(
                                (segment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      BankLogoBadge(
                                        branding: segment.branding,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          segment.label,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        segment.value.toStringAsFixed(0),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ],
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
    final strokeWidth = size.width * 0.05;
    final rect = Offset.zero & size;
    final total = segments.fold<double>(0, (sum, segment) => sum + segment.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      paint.color = emptyColor;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
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
        rect.deflate(strokeWidth / 2),
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
