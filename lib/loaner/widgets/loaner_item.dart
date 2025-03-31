import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:shimmer/shimmer.dart';

class LoanerItem extends StatelessWidget {
  const LoanerItem({
    required this.loaner,
    super.key,
  });
  final LoanerModel loaner;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Container(
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
                    Text(
                      loaner.customer?.name ?? 'Unknown',
                      style: AppTextTheme.title,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${loaner.amount} រៀល',
                      style: AppTextTheme.body,
                    ),
                  ],
                ),
                ...[
                  const SizedBox(height: 8),
                  Text(
                    loaner.displayDate,
                    style: AppTextTheme.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
            if (loaner.note != null) ...[
              const SizedBox(height: 8),
              Text(
                '${context.l10n.note}: ${loaner.note}',
                style: AppTextTheme.caption,
              ),
            ],
          ],
        ),
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
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 20,
                  color: Colors.white, // Name placeholder
                ),
                Container(
                  width: 100,
                  height: 16,
                  color: Colors.white, // Amount placeholder
                ),
                Container(
                  width: 200,
                  height: 16,
                  color: Colors.white, // Note placeholder
                ),
                Container(
                  width: 200,
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
