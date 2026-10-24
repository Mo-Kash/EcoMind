import 'package:flutter/material.dart';
import '../../../core/constants/taxonomy.dart';
import '../../../data/models/detected_item.dart';

class MaskOverlayPainter extends CustomPainter {
  final List<DetectedItem> items;
  final String? selectedItemId;

  MaskOverlayPainter({
    required this.items,
    this.selectedItemId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final isSelected = selectedItemId == null || item.id == selectedItemId;
      final opacity = isSelected ? 0.45 : 0.15;
      final color = Taxonomy.getColor(item.effectiveClass);

      final boxRect = Rect.fromLTRB(
        item.boundingBox.left * size.width,
        item.boundingBox.top * size.height,
        item.boundingBox.right * size.width,
        item.boundingBox.bottom * size.height,
      );

      // 1. Draw bounding box / mask fill
      final fillPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = color.withOpacity(isSelected ? 0.9 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.5;

      canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(8)), fillPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(8)), strokePaint);

      // 2. Draw label pill
      final label = "${Taxonomy.getDisplayName(item.effectiveClass)} ${(item.confidence * 100).toStringAsFixed(0)}%";
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelBackgroundRect = Rect.fromLTWH(
        boxRect.left,
        (boxRect.top - textPainter.height - 4).clamp(0, size.height),
        textPainter.width + 10,
        textPainter.height + 4,
      );

      final bgPaint = Paint()..color = color.withOpacity(0.9);
      canvas.drawRRect(RRect.fromRectAndRadius(labelBackgroundRect, const Radius.circular(4)), bgPaint);

      textPainter.paint(
        canvas,
        Offset(labelBackgroundRect.left + 5, labelBackgroundRect.top + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MaskOverlayPainter oldDelegate) {
    return oldDelegate.selectedItemId != selectedItemId || oldDelegate.items != items;
  }
}

