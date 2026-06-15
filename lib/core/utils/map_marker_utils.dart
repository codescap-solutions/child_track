import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:child_track/core/constants/app_colors.dart';

class MapMarkerUtils {
  static Future<BitmapDescriptor> createCustomMarkerBitmap(
    String label, {
    required IconData icon,
    required Color backgroundColor,
    Color? circleColor,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Config
    const double size = 150.0; // Increased base size for better resolution
    const double iconSize = 40.0;
    const double fontSize = 20.0;
    const double padding = 10.0; // Increased padding

    // Paint Setup
    final Paint pillPaint = Paint()..color = backgroundColor;
    final Paint circlePaint = Paint()
      ..color =
          circleColor ??
          backgroundColor; // Use circleColor if provided, else match pill

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Draw Pill/Label Background
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
    textPainter.layout();

    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;
    final double pillWidth = textWidth + (padding * 3);
    final double pillHeight = textHeight + (padding * 1.5);

    // Draw Pill Rect (centered horizontally)
    final double pillTop = 0;
    final double pillLeft = (size - pillWidth) / 2;

    final RRect pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight),
      const Radius.circular(8.0),
    );

    // Draw Shadow
    canvas.drawRRect(
      pillRRect.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw Pill
    canvas.drawRRect(pillRRect, pillPaint);

    // Draw Text
    textPainter.paint(
      canvas,
      Offset(
        pillLeft + (pillWidth - textWidth) / 2,
        pillTop + (pillHeight - textHeight) / 2,
      ),
    );

    // 2. Draw Icon Circle below
    const double circleRadius = 30.0;
    final double circleCenterX = size / 2;
    final double circleCenterY = pillHeight + 20 + circleRadius;

    // Pin Shadow
    canvas.drawCircle(
      Offset(circleCenterX, circleCenterY + 2),
      circleRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Pin Body
    canvas.drawCircle(
      Offset(circleCenterX, circleCenterY),
      circleRadius,
      circlePaint,
    );

    // Draw Icon
    final TextPainter iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        circleCenterX - (iconPainter.width / 2),
        circleCenterY - (iconPainter.height / 2),
      ),
    );

    // Convert to Image
    final int imgWidth = size.toInt();
    // Ensure height captures everything
    final int imgHeight = (circleCenterY + circleRadius + 5).toInt();

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      imgWidth < pillWidth.toInt()
          ? pillWidth.toInt()
          : imgWidth, // Ensure width covers pill
      imgHeight,
    );

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> getStartMarker() async {
    return createCustomMarkerBitmap(
      'START',
      icon: Icons.home,
      backgroundColor: AppColors.success, // Green Pill
      circleColor: AppColors.textSecondary, // Standard Icon Background
    );
  }

  static Future<BitmapDescriptor> getEndMarker() async {
    return createCustomMarkerBitmap(
      'END',
      icon: Icons.share_location_sharp,
      backgroundColor: AppColors.error, // Red Pill
      circleColor: AppColors.textSecondary, // Standard Icon Background
    );
  }
}
