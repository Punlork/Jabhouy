import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:shimmer/shimmer.dart';

class LoanerItem extends StatelessWidget {
  const LoanerItem({
    required this.loaner,
    this.onMarkAsPaid,
    super.key,
  });

  final LoanerModel loaner;
  final void Function({bool isPaid})? onMarkAsPaid;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      color: loaner.isPaid ? Colors.green[50] : null,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            Text(
                              loaner.customer?.name ?? 'Unknown',
                              style: AppTextTheme.title,
                            ),
                            if (loaner.isPaid) ...[
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        if (loaner.amount != 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${loaner.amount} រៀល',
                            style: AppTextTheme.body,
                          ),
                        ]
                      ],
                    ),
                    Text(
                      loaner.displayDate,
                      style: AppTextTheme.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                if (loaner.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${context.l10n.note}: ${loaner.note}',
                    style: AppTextTheme.caption,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => onMarkAsPaid?.call(
                isPaid: !loaner.isPaid,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loaner.isPaid ? context.l10n.unpaid : context.l10n.paid,
                  style: AppTextTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoanerItemShimmer extends StatelessWidget {
  const LoanerItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 100,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        height: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 100,
                  height: 16,
                  color: Colors.white, // Created date placeholder
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
