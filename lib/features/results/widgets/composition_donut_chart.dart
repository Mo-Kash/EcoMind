import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/taxonomy.dart';
import '../../../data/models/detected_item.dart';

class CompositionDonutChart extends StatelessWidget {
  final List<DetectedItem> items;

  const CompositionDonutChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Aggregate counts by class
    final Map<String, int> counts = {};
    for (final item in items) {
      counts[item.effectiveClass] = (counts[item.effectiveClass] ?? 0) + 1;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scene Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'} found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Custom Donut Ring
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: _DonutChartPainter(counts: counts, total: items.length),
                    child: Center(
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: counts.entries.map((entry) {
                      final color = Taxonomy.getColor(entry.key);
                      final name = Taxonomy.getDisplayName(entry.key);
                      final pct = (entry.value / items.length * 100).toStringAsFixed(0);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$name ($pct%)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, int> counts;
  final int total;

  _DonutChartPainter({required this.counts, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    double startAngle = -pi / 2;

    for (final entry in counts.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi;
      final paint = Paint()
        ..color = Taxonomy.getColor(entry.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

