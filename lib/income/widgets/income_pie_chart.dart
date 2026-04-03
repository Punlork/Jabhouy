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

  static const _segmentColors = <BankApp, Color>{
    BankApp.aba: Color(0xFF0F9D58),
    BankApp.chipMong: Color(0xFFFF7043),
    BankApp.acleda: Color(0xFF1976D2),
    BankApp.unknown: Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    final segments = summary.incomeByBank.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => _ChartSegment(
            label: entry.key.label,
            color: _segmentColors[entry.key] ?? _segmentColors[BankApp.unknown]!,
            value: entry.value,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _IncomePieChartPainter(
                      segments: segments,
                      emptyColor: colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.totalIncome,
                            style: Theme.of(context).textTheme.bodySmall,
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: segments
                              .map(
                                (segment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: segment.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          segment.label,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        segment.value.toStringAsFixed(0),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
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
      paint.color = segment.color;
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
