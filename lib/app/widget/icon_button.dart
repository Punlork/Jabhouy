import 'package:flutter/material.dart';

class IconButtonWidget extends StatelessWidget {
  const IconButtonWidget({
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
    super.key,
    this.tooltip,
    this.color,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color ?? Colors.black),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
