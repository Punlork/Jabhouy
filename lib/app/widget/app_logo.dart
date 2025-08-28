import 'package:flutter/material.dart';
import 'package:my_app/app/app.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80.0, // Default size of 80
    this.shape = BoxShape.circle, // Default shape as circle
    this.useBg = true, // Default to using background
  });

  final double size; // Size parameter for the logo
  final BoxShape shape; // Shape parameter (circle or rectangle)
  final bool useBg; // Toggle for background container

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Widget content without background
    final Widget logoContent = ClipOval(
      child: Image.asset(
        AppAssets.logo,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.lock_outline_rounded,
          size: size,
          color: colorScheme.onPrimary,
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    // Return with background if useBg is true
    if (useBg) {
      return Container(
        padding: EdgeInsets.all(size / 5), // Dynamic padding based on size
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(.2),
          shape: shape,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(.1),
              blurRadius: size / 6.67, // Adjusted blur based on size
              offset: Offset(0, size / 20), // Adjusted offset based on size
            ),
          ],
        ),
        child: logoContent,
      );
    }

    // Return just the logo content if useBg is false
    return logoContent;
  }
}
