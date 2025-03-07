import 'package:flutter/material.dart';

class CustomLoading extends StatefulWidget {
  const CustomLoading({
    super.key,
    this.itemCount = 4,
    this.duration = const Duration(milliseconds: 600),
    this.delayStep = const Duration(milliseconds: 150),
    this.dotSize = 8.0,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  /// Number of dots/items in the loading indicator
  final int itemCount;

  /// Duration of each animation cycle
  final Duration duration;

  /// Delay step between each dot's animation start
  final Duration delayStep;

  /// Base size of the dots (height)
  final double dotSize;

  /// Color of the dots (defaults to Theme.primaryColor with alpha adjustment)
  final Color? color;

  /// Padding around the loader
  final EdgeInsets padding;

  @override
  State<CustomLoading> createState() => _GridBottomLoaderState();
}

class _GridBottomLoaderState extends State<CustomLoading> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and animations
    _controllers = List.generate(
      widget.itemCount,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
      ),
    );

    _animations = List.generate(
      widget.itemCount,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Start animations with staggered delays
    for (var i = 0; i < widget.itemCount; i++) {
      Future.delayed(widget.delayStep * i, () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.itemCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final effectiveColor = widget.color ?? Theme.of(context).primaryColor;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: widget.dotSize,
                width: widget.dotSize / 2 + (widget.dotSize / 2 * _animations[index].value),
                decoration: BoxDecoration(
                  color: effectiveColor.withAlpha(
                    (255 * (0.6 + (0.4 * _animations[index].value))).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(widget.dotSize / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
