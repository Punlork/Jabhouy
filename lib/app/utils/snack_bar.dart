import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';

void showErrorSnackBar(BuildContext? context, String message) {
  _showSnackBar(
    context: context,
    message: message,
    backgroundColor: Colors.red,
    icon: Icons.error_outline,
  );
}

void showSuccessSnackBar(BuildContext? context, String message) {
  _showSnackBar(
    context: context,
    message: message,
    backgroundColor: Colors.green,
    icon: Icons.check_circle_outline,
  );
}

void _showSnackBar({
  required BuildContext? context,
  required String message,
  required Color backgroundColor,
  required IconData icon,
}) {
  final tempContext = context ?? GlobalContext.currentContext;
  if (tempContext.mounted) {
    ScaffoldMessenger.of(tempContext).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
