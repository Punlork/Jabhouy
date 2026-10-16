import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    super.key,
    this.maxHeightFactor = 0.9,
    this.scrollable = true,
  });

  final Widget child;
  final double maxHeightFactor;

  /// False when [child] scrolls part of itself, e.g. to keep a footer fixed.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * maxHeightFactor,
          ),
          child: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    );
  }
}
