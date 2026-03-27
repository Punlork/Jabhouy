import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';

void showErrorSnackBar(BuildContext? context, String message) {
  final colorScheme =
      Theme.of(context ?? GlobalContext.currentContext).colorScheme;
  _showSnackBar(
    context: context,
    message: message,
    backgroundColor: colorScheme.error,
    foregroundColor: colorScheme.onError,
    icon: Icons.error_outline,
  );
}

void showSuccessSnackBar(BuildContext? context, String message) {
  final colorScheme =
      Theme.of(context ?? GlobalContext.currentContext).colorScheme;
  _showSnackBar(
    context: context,
    message: message,
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    icon: Icons.check_circle_outline,
  );
}

void _showSnackBar({
  required BuildContext? context,
  required String message,
  required Color backgroundColor,
  required Color foregroundColor,
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
              color: foregroundColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: foregroundColor),
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
