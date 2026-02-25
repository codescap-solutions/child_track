import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer colors used across the app skeleton loaders.
const Color _shimmerBase = Color(0xFFE0E0E0); // light grey
const Color _shimmerHighlight = Color(0xFFF5F5F5); // near-white

/// Wraps any child widget in a shimmer animation.
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: child,
    );
  }
}

/// A simple grey rounded box used as a placeholder in shimmer skeletons.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular shimmer placeholder (avatar / icon).
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _shimmerBase,
        shape: BoxShape.circle,
      ),
    );
  }
}
