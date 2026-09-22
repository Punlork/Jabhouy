import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/strings/ui_strings.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.msg,
  });

  final String? msg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            msg ?? UiStringsScope.of(context).noItemFound,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
