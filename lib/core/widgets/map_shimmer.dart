import 'package:child_track/core/widgets/shimmer_widget.dart';
import 'package:flutter/material.dart';

/// Shimmer skeleton for the MapViewWidget loading state.
/// Shows a map-like placeholder with shimmer road lines and a location pin.
class MapShimmer extends StatelessWidget {
  final double width;
  final double height;

  const MapShimmer({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0)),
        child: Stack(
          children: [
            // Horizontal "road" shimmer lines
            Positioned(
              top: height * 0.3,
              left: 0,
              right: 0,
              child: const ShimmerBox(
                width: double.infinity,
                height: 10,
                borderRadius: 4,
              ),
            ),
            Positioned(
              top: height * 0.55,
              left: 0,
              right: 0,
              child: const ShimmerBox(
                width: double.infinity,
                height: 8,
                borderRadius: 4,
              ),
            ),
            Positioned(
              top: height * 0.75,
              left: 0,
              right: 0,
              child: const ShimmerBox(
                width: double.infinity,
                height: 6,
                borderRadius: 4,
              ),
            ),

            // Vertical "road" shimmer lines
            Positioned(
              top: 0,
              bottom: 0,
              left: width * 0.3,
              child: ShimmerBox(width: 8, height: height, borderRadius: 4),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: width * 0.65,
              child: ShimmerBox(width: 6, height: height, borderRadius: 4),
            ),

            // Centre location pin placeholder
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ShimmerCircle(size: 40),
                  Container(
                    width: 2,
                    height: 16,
                    color: const Color(0xFFBDBDBD),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
