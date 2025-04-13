import 'package:flutter/material.dart';

class AnimatedWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double verticalOffset;
  final bool animate;
  final int? index;

  const AnimatedWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutQuad,
    this.delay = Duration.zero,
    this.verticalOffset = 20.0,
    this.animate = true,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return child;
    }

    final effectiveDuration =
        index != null ? duration + (delay * index!) : duration;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: effectiveDuration,
      curve: curve,
      builder: (context, value, buildChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, verticalOffset * (1 - value)),
            child: buildChild,
          ),
        );
      },
      child: child,
    );
  }

  /// Creates a delayed animation wrapper
  factory AnimatedWrapper.delayed({
    Key? key,
    required Widget child,
    required Duration delay,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutQuad,
    double verticalOffset = 20.0,
    bool animate = true,
  }) {
    return AnimatedWrapper(
      key: key,
      duration: duration,
      curve: curve,
      delay: delay,
      verticalOffset: verticalOffset,
      animate: animate,
      child: child,
    );
  }

  /// Creates a staggered animation wrapper for list items
  factory AnimatedWrapper.staggered({
    Key? key,
    required Widget child,
    required int index,
    Duration duration = const Duration(milliseconds: 300),
    Duration staggerDelay = const Duration(milliseconds: 50),
    Curve curve = Curves.easeOutQuad,
    double verticalOffset = 20.0,
    bool animate = true,
  }) {
    return AnimatedWrapper(
      key: key,
      duration: duration,
      curve: curve,
      delay: staggerDelay,
      verticalOffset: verticalOffset,
      animate: animate,
      index: index,
      child: child,
    );
  }
}
