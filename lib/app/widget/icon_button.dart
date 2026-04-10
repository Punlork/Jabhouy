import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconButtonWidget extends StatelessWidget {
  const IconButtonWidget({
    required this.onPressed,
    required this.colorScheme,
    super.key,
    this.icon,
    this.svgAsset,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderColor,
  }) : assert(
          icon != null || svgAsset != null,
          'Either icon or svgAsset must be provided.',
        );
  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 42,
      width: 42,
      child: Tooltip(
        message: tooltip ?? '',
        child: IconButton(
          onPressed: onPressed,
          icon: _buildIcon(),
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            backgroundColor:
                backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
            side: borderColor == null
                ? BorderSide.none
                : BorderSide(color: borderColor!),
            elevation: 0,
            minimumSize: const Size(42, 42),
            maximumSize: const Size(42, 42),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final foreground = color ?? colorScheme.onSurfaceVariant;

    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset!,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
      );
    }

    return Icon(icon, color: foreground, size: 20);
  }
}
