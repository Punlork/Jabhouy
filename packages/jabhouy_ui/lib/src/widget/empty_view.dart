import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.msg,
  });

  final String? msg;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: muted),
          const SizedBox(height: 16),
          Text(
            msg ?? context.l10n.noItemFound,
            style: TextStyle(
              fontSize: 18,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
