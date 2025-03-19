import 'package:flutter/material.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:shimmer/shimmer.dart';

class LoanerItem extends StatelessWidget {
  const LoanerItem({
    required this.loaner,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final LoanerModel loaner;
  final void Function(LoanerModel) onEdit;
  final void Function(LoanerModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16).copyWith(right: 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                spacing: 12, // Assuming Column has a spacing property; if not, use SizedBox
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loaner.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${loaner.amount} រៀល',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  Text(
                    'Note: ${(loaner.note?.isEmpty ?? true) ? 'No note' : loaner.note}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: (loaner.note?.isEmpty ?? true) ? FontStyle.italic : FontStyle.normal,
                        ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 30,
                  ),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => onEdit(loaner),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 30,
                  ),
                  color: Colors.red,
                  onPressed: () => onDelete(loaner),
                ),
              ],
            ),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 20,
                      color: Colors.white, // Name placeholder
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 100,
                      height: 16,
                      color: Colors.white, // Amount placeholder
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 200,
                      height: 16,
                      color: Colors.white, // Note placeholder
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    color: Colors.white, // Edit button placeholder
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 30,
                    height: 30,
                    color: Colors.white, // Delete button placeholder
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
